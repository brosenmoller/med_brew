import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/models/sync_models.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/services/favorites_service.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/srs_service.dart';
import 'package:med_brew/services/sync_discovery_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  AppDatabase? _db;
  HttpServer? _server;
  int _httpPort = 0;
  bool _initialized = false;

  Completer<bool>? _pendingAccept;
  SyncResult? _acceptorResult; // set by _handlePush, consumed by _handleSyncDone

  final _incomingRequestController = StreamController<String>.broadcast();
  final _syncProgressController = StreamController<String>.broadcast();
  final _acceptorDoneController = StreamController<SyncResult>.broadcast();

  /// Emits the requesting device name when an incoming sync request arrives.
  Stream<String> get incomingRequests => _incomingRequestController.stream;

  /// Emits progress messages during an active sync (initiator side).
  Stream<String> get syncProgress => _syncProgressController.stream;

  /// Emits once when the initiator signals completion (acceptor side).
  Stream<SyncResult> get acceptorSyncComplete => _acceptorDoneController.stream;

  final SyncDiscoveryService discovery = SyncDiscoveryService();

  Future<void> init(AppDatabase db) async {
    if (_initialized) return;
    _db = db;
    await _startServer();
    _initialized = true;
  }

  /// Stop the HTTP server and reset so [init] can be called again next time
  /// the sync screen is opened.
  Future<void> shutdown() async {
    await discovery.stop();
    await _server?.close(force: true);
    _server = null;
    _httpPort = 0;
    _initialized = false;
    _pendingAccept?.complete(false);
    _pendingAccept = null;
    _acceptorResult = null;
  }

  Future<void> _startServer() async {
    final router = Router();
    router.get('/ping', _handlePing);
    router.post('/sync/request', _handleSyncRequest);
    router.get('/sync/manifest', _handleManifest);
    router.post('/sync/push', _handlePush);
    router.post('/sync/pull', _handlePull);
    router.get('/sync/image', _handleImage);
    router.post('/sync/done', _handleSyncDone);

    _server = await shelf_io.serve(router.call, InternetAddress.anyIPv4, 0);
    _httpPort = _server!.port;
  }

  int get httpPort => _httpPort;

  Future<void> startDiscovery(String deviceName) =>
      discovery.start(deviceName: deviceName, httpPort: _httpPort);

  Future<void> stopDiscovery() => discovery.stop();

  // ── Server handlers ──────────────────────────────────────────

  Response _handlePing(Request req) => Response.ok(
        jsonEncode({'deviceName': _deviceName, 'version': '1'}),
        headers: {'content-type': 'application/json'},
      );

  Future<Response> _handleSyncRequest(Request req) async {
    final body = Map<String, dynamic>.from(
        jsonDecode(await req.readAsString()) as Map);
    final requesterName = body['deviceName'] as String? ?? 'Unknown Device';

    if (_pendingAccept != null) {
      return Response(503,
          body: jsonEncode({'accepted': false, 'reason': 'busy'}),
          headers: {'content-type': 'application/json'});
    }

    _pendingAccept = Completer<bool>();
    _incomingRequestController.add(requesterName);

    final accepted = await _pendingAccept!.future
        .timeout(const Duration(seconds: 60), onTimeout: () => false);
    _pendingAccept = null;

    return Response.ok(
      jsonEncode({'accepted': accepted}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Called by the UI to accept or reject an incoming sync request.
  void respondToRequest(bool accepted) => _pendingAccept?.complete(accepted);

  Future<Response> _handleManifest(Request req) async {
    final manifest = await _buildManifest();
    return Response.ok(
      jsonEncode(manifest.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _handlePush(Request req) async {
    try {
      final data = Map<String, dynamic>.from(
          jsonDecode(await req.readAsString()) as Map);
      final senderPort = data['senderPort'] as int?;
      final connInfo =
          req.context['shelf.io.connection_info'] as HttpConnectionInfo?;
      final senderIp = connInfo?.remoteAddress.address;

      final payload = SyncPayload.fromJson(data);

      // Fetch images from sender before importing
      if (senderIp != null && senderPort != null) {
        final senderBase = 'http://$senderIp:$senderPort';
        for (final imgName in payload.imageFilenames) {
          await _fetchImage(senderBase, imgName);
        }
      }

      _acceptorResult = await _importPayload(payload);
      await QuestionService().refresh();
      return Response.ok(
        jsonEncode({'ok': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'ok': false, 'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _handlePull(Request req) async {
    try {
      final data = Map<String, dynamic>.from(
          jsonDecode(await req.readAsString()) as Map);
      final folderSyncIds =
          (data['folderSyncIds'] as List).map((e) => e as String).toList();
      final quizSyncIds =
          (data['quizSyncIds'] as List).map((e) => e as String).toList();
      final questionSyncIds =
          (data['questionSyncIds'] as List).map((e) => e as String).toList();

      final payload = await _buildPayload(
        folderSyncIds: folderSyncIds,
        quizSyncIds: quizSyncIds,
        questionSyncIds: questionSyncIds,
      );
      return Response.ok(
        jsonEncode(payload.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _handleImage(Request req) async {
    final name = req.url.queryParameters['name'];
    if (name == null || name.isEmpty) return Response.badRequest();
    // Sanitize: only allow basenames, no path traversal
    final safeName = p.basename(name);
    if (safeName.isEmpty || safeName.contains('..')) return Response.badRequest();

    final imgDir = await _getImagesDir();
    final file = File(p.join(imgDir, safeName));
    if (!await file.exists()) return Response.notFound('Image not found');

    final bytes = await file.readAsBytes();
    final ext = p.extension(safeName).toLowerCase();
    final contentType = switch (ext) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
    return Response.ok(bytes, headers: {'content-type': contentType});
  }

  Future<Response> _handleSyncDone(Request req) async {
    final result = _acceptorResult ?? const SyncResult();
    _acceptorResult = null;
    if (!_acceptorDoneController.isClosed) {
      _acceptorDoneController.add(result);
    }
    return Response.ok(
      jsonEncode({'ok': true}),
      headers: {'content-type': 'application/json'},
    );
  }

  // ── Initiator: full bidirectional sync ───────────────────────

  Future<SyncResult> syncWith(SyncPeer peer) async {
    final base = 'http://${peer.host}:${peer.port}';

    _progress('Connecting to ${peer.deviceName}…');
    final reqResp = await http
        .post(
          Uri.parse('$base/sync/request'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'deviceName': _deviceName}),
        )
        .timeout(const Duration(seconds: 65));

    final reqData =
        Map<String, dynamic>.from(jsonDecode(reqResp.body) as Map);
    if (reqData['accepted'] != true) {
      throw SyncException(reqData['reason'] as String? ?? 'Sync rejected');
    }

    _progress('Reading remote inventory…');
    final manifestResp =
        await http.get(Uri.parse('$base/sync/manifest'));
    final remoteManifest = SyncManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(manifestResp.body) as Map));

    final localManifest = await _buildManifest();

    // Delta for content
    final localFolderIds =
        localManifest.folders.map((e) => e.syncId).toSet();
    final localQuizIds =
        localManifest.quizzes.map((e) => e.syncId).toSet();
    final localQuestionIds =
        localManifest.questions.map((e) => e.syncId).toSet();
    final remoteFolderIds =
        remoteManifest.folders.map((e) => e.syncId).toSet();
    final remoteQuizIds =
        remoteManifest.quizzes.map((e) => e.syncId).toSet();
    final remoteQuestionIds =
        remoteManifest.questions.map((e) => e.syncId).toSet();

    final toSendFolderIds =
        localFolderIds.difference(remoteFolderIds).toList();
    final toSendQuizIds = localQuizIds.difference(remoteQuizIds).toList();
    final toSendQuestionIds =
        localQuestionIds.difference(remoteQuestionIds).toList();

    final toFetchFolderIds =
        remoteFolderIds.difference(localFolderIds).toList();
    final toFetchQuizIds = remoteQuizIds.difference(localQuizIds).toList();
    final toFetchQuestionIds =
        remoteQuestionIds.difference(localQuestionIds).toList();

    // Favorites delta (additive union)
    final remoteFavIds = remoteManifest.favoriteSyncIds.toSet();
    final localFavIds = localManifest.favoriteSyncIds.toSet();
    final toFetchFavIds =
        remoteFavIds.difference(localFavIds).toList();

    // Push local content to remote
    if (toSendFolderIds.isNotEmpty ||
        toSendQuizIds.isNotEmpty ||
        toSendQuestionIds.isNotEmpty) {
      _progress('Sending local content…');
      final pushPayload = await _buildPayload(
        folderSyncIds: toSendFolderIds,
        quizSyncIds: toSendQuizIds,
        questionSyncIds: toSendQuestionIds,
        includeSrs: true,
        includeFavorites: true,
      );
      final pushBody = pushPayload.toJson();
      pushBody['senderPort'] = _httpPort; // Tell remote where to fetch images
      await http.post(
        Uri.parse('$base/sync/push'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(pushBody),
      );
    } else {
      // Still push SRS + favorites even if no new content
      final srsAndFavPayload = await _buildPayload(
        folderSyncIds: [],
        quizSyncIds: [],
        questionSyncIds: [],
        includeSrs: true,
        includeFavorites: true,
      );
      if (srsAndFavPayload.srsData.isNotEmpty ||
          srsAndFavPayload.favoriteSyncIds.isNotEmpty) {
        final pushBody = srsAndFavPayload.toJson();
        pushBody['senderPort'] = _httpPort;
        await http.post(
          Uri.parse('$base/sync/push'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(pushBody),
        );
      }
    }

    // Pull remote content
    SyncResult result = const SyncResult();
    if (toFetchFolderIds.isNotEmpty ||
        toFetchQuizIds.isNotEmpty ||
        toFetchQuestionIds.isNotEmpty ||
        toFetchFavIds.isNotEmpty) {
      _progress('Fetching remote content…');
      final pullResp = await http.post(
        Uri.parse('$base/sync/pull'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'folderSyncIds': toFetchFolderIds,
          'quizSyncIds': toFetchQuizIds,
          'questionSyncIds': toFetchQuestionIds,
        }),
      );
      final fetchedPayload = SyncPayload.fromJson(
          Map<String, dynamic>.from(jsonDecode(pullResp.body) as Map));

      _progress('Downloading images…');
      for (final imgName in fetchedPayload.imageFilenames) {
        await _fetchImage(base, imgName);
      }

      _progress('Importing content…');
      result = await _importPayload(fetchedPayload);

      // Also apply remote favorites we don't have yet
      if (toFetchFavIds.isNotEmpty) {
        for (final favSyncId in toFetchFavIds) {
          await FavoritesService().addFavoriteBySyncId(favSyncId, _db!);
        }
      }
    }

    await QuestionService().refresh();
    _progress('Sync complete!');

    // Signal to the acceptor that the initiator is done so it can show its result.
    try {
      await http
          .post(Uri.parse('$base/sync/done'),
              headers: {'content-type': 'application/json'},
              body: jsonEncode({}))
          .timeout(const Duration(seconds: 5));
    } catch (_) {} // Non-fatal — acceptor will time out gracefully if this fails.

    return result;
  }

  // ── Manifest ─────────────────────────────────────────────────

  Future<SyncManifest> _buildManifest() async {
    final foldersRows = await _db!.getNonPermanentFolders();
    final quizzesRows = await _db!.getNonPermanentQuizzes();
    final questionsRows = await _db!.getNonPermanentQuestions();

    // Build SRS manifest keys: use syncId for custom questions, int-string for permanent
    final srsKeys = <String>[];
    for (final data in SrsService().getAllUserData()) {
      final key = data.questionId;
      final intId = int.tryParse(key);
      if (intId != null) {
        final syncId = await _db!.getQuestionSyncIdById(intId);
        srsKeys.add(syncId ?? key);
      } else {
        srsKeys.add(key);
      }
    }

    final favSyncIds =
        await FavoritesService().getAllFavoriteSyncIds(_db!);

    return SyncManifest(
      folders: foldersRows
          .where((f) => f.syncId != null)
          .map((f) => SyncEntry(syncId: f.syncId!, createdAt: f.createdAt))
          .toList(),
      quizzes: quizzesRows
          .where((q) => q.syncId != null)
          .map((q) => SyncEntry(syncId: q.syncId!, createdAt: q.createdAt))
          .toList(),
      questions: questionsRows
          .where((q) => q.syncId != null)
          .map((q) => SyncEntry(
              syncId: q.syncId!,
              createdAt: DateTime.fromMillisecondsSinceEpoch(0)))
          .toList(),
      srsKeys: srsKeys,
      favoriteSyncIds: favSyncIds,
    );
  }

  // ── Payload building ─────────────────────────────────────────

  Future<SyncPayload> _buildPayload({
    required List<String> folderSyncIds,
    required List<String> quizSyncIds,
    required List<String> questionSyncIds,
    bool includeSrs = false,
    bool includeFavorites = false,
  }) async {
    final foldersJson = <Map<String, dynamic>>[];
    for (final syncId in folderSyncIds) {
      final f = await _db!.getFolderBySyncId(syncId);
      if (f == null) continue;
      foldersJson.add({
        'syncId': f.syncId,
        'parentSyncId': f.parentFolderId != null
            ? await _db!.getFolderSyncIdById(f.parentFolderId!)
            : null,
        'title': f.title,
        'imageName':
            f.imagePath != null ? p.basename(f.imagePath!) : null,
      });
    }

    final quizzesJson = <Map<String, dynamic>>[];
    for (final syncId in quizSyncIds) {
      final quiz = await _db!.getQuizBySyncId(syncId);
      if (quiz == null) continue;
      final questionsInQuiz = await _db!.getQuestionsForQuiz(quiz.id);
      quizzesJson.add({
        'syncId': quiz.syncId,
        'folderSyncId': quiz.folderId != null
            ? await _db!.getFolderSyncIdById(quiz.folderId!)
            : null,
        'title': quiz.title,
        'imageName':
            quiz.imagePath != null ? p.basename(quiz.imagePath!) : null,
        'languageCode': quiz.languageCode,
        'questionSyncIds': questionsInQuiz
            .where((q) => q.syncId != null)
            .map((q) => q.syncId!)
            .toList(),
      });
    }

    final questionsJson = <Map<String, dynamic>>[];
    final imageFilenames = <String>{};

    for (final syncId in questionSyncIds) {
      final q = await _db!.getQuestionBySyncId(syncId);
      if (q == null) continue;
      final config =
          Map<String, dynamic>.from(jsonDecode(q.answerConfig) as Map);

      // Replace full paths with basenames in flashcard config
      final syncConfig = _normalizeConfigImagePaths(config, q.answerType, imageFilenames);

      if (q.imagePath != null) imageFilenames.add(p.basename(q.imagePath!));

      questionsJson.add({
        'syncId': q.syncId,
        'questionText': q.questionText,
        'questionVariants': q.questionVariants != null
            ? jsonDecode(q.questionVariants!)
            : null,
        'answerType': q.answerType,
        'answerConfig': syncConfig,
        'explanation': q.explanation,
        'imageName':
            q.imagePath != null ? p.basename(q.imagePath!) : null,
      });
    }

    // Collect folder + quiz image names
    for (final fj in foldersJson) {
      if (fj['imageName'] != null) imageFilenames.add(fj['imageName'] as String);
    }
    for (final qj in quizzesJson) {
      if (qj['imageName'] != null) imageFilenames.add(qj['imageName'] as String);
    }

    // SRS data (all custom + permanent questions)
    final srsDataJson = <Map<String, dynamic>>[];
    if (includeSrs) {
      for (final data in SrsService().getAllUserData()) {
        final key = data.questionId;
        final intId = int.tryParse(key);
        String syncKey;
        if (intId != null) {
          final syncId = await _db!.getQuestionSyncIdById(intId);
          syncKey = syncId ?? key; // syncId for custom, int-string for permanent
        } else {
          syncKey = key;
        }
        srsDataJson.add({
          'questionSyncId': syncKey,
          'streak': data.streak,
          'easeFactor': data.easeFactor,
          'intervalSeconds': data.intervalSeconds,
          'lastReviewed': data.lastReviewed.toIso8601String(),
          'nextReview': data.nextReview.toIso8601String(),
          'spacedRepetitionEnabled': data.spacedRepetitionEnabled,
        });
      }
    }

    // Favorites
    final favSyncIds = includeFavorites
        ? await FavoritesService().getAllFavoriteSyncIds(_db!)
        : <String>[];

    return SyncPayload(
      folders: foldersJson,
      quizzes: quizzesJson,
      questions: questionsJson,
      srsData: srsDataJson,
      favoriteSyncIds: favSyncIds,
      imageFilenames: imageFilenames.toList(),
    );
  }

  Map<String, dynamic> _normalizeConfigImagePaths(
    Map<String, dynamic> config,
    String answerType,
    Set<String> imageFilenames,
  ) {
    if (answerType != 'flashcard') return config;
    final result = Map<String, dynamic>.from(config);
    if (result['frontImagePath'] != null) {
      final name = p.basename(result['frontImagePath'] as String);
      imageFilenames.add(name);
      result['frontImagePath'] = name;
    }
    if (result['backImagePath'] != null) {
      final name = p.basename(result['backImagePath'] as String);
      imageFilenames.add(name);
      result['backImagePath'] = name;
    }
    return result;
  }

  // ── Import ───────────────────────────────────────────────────

  Future<SyncResult> _importPayload(SyncPayload payload) async {
    int foldersAdded = 0, quizzesAdded = 0, questionsAdded = 0;
    int srsUpdated = 0, favoritesAdded = 0;

    final imgDir = await _getImagesDir();
    final folderIdMap = <String, int>{};
    final questionIdMap = <String, int>{};

    await _db!.transaction(() async {
      // 1. Questions (no dependencies)
      for (final qJson in payload.questions) {
        final syncId = qJson['syncId'] as String;
        final existing = await _db!.getQuestionBySyncId(syncId);
        if (existing != null) {
          questionIdMap[syncId] = existing.id;
          continue;
        }

        final answerType = qJson['answerType'] as String;
        final configRaw =
            Map<String, dynamic>.from(qJson['answerConfig'] as Map);
        final localConfig =
            _localizeConfigImagePaths(configRaw, answerType, imgDir);

        final variants =
            (qJson['questionVariants'] as List?)?.map((e) => e as String).toList();
        final questionText = variants?.isNotEmpty == true
            ? variants!.first
            : qJson['questionText'] as String? ?? '';

        String? imagePath;
        final imgName = qJson['imageName'] as String?;
        if (imgName != null) imagePath = p.join(imgDir, imgName);

        final newId = await _db!.insertQuestionForSync(
          syncId: syncId,
          questionText: questionText,
          questionVariants: variants != null && variants.length > 1
              ? jsonEncode(variants)
              : null,
          answerType: answerType,
          answerConfig: jsonEncode(localConfig),
          explanation: qJson['explanation'] as String?,
          imagePath: imagePath,
        );
        questionIdMap[syncId] = newId;
        questionsAdded++;
      }

      // 2. Folders — first pass: insert without parent
      for (final fJson in payload.folders) {
        final syncId = fJson['syncId'] as String;
        final existing = await _db!.getFolderBySyncId(syncId);
        if (existing != null) {
          folderIdMap[syncId] = existing.id;
          continue;
        }

        String? imagePath;
        final imgName = fJson['imageName'] as String?;
        if (imgName != null) imagePath = p.join(imgDir, imgName);

        final newId = await _db!.insertFolderForSync(
          syncId: syncId,
          title: fJson['title'] as String,
          imagePath: imagePath,
        );
        folderIdMap[syncId] = newId;
        foldersAdded++;
      }
      // Second pass: wire up parent relationships
      for (final fJson in payload.folders) {
        final syncId = fJson['syncId'] as String;
        final parentSyncId = fJson['parentSyncId'] as String?;
        if (parentSyncId == null) continue;
        final localId = folderIdMap[syncId];
        final parentLocalId = folderIdMap[parentSyncId];
        if (localId != null && parentLocalId != null) {
          await _db!.updateFolderParentId(localId, parentLocalId);
        }
      }

      // 3. Quizzes + junction rows
      for (final qzJson in payload.quizzes) {
        final syncId = qzJson['syncId'] as String;
        int quizLocalId;

        final existing = await _db!.getQuizBySyncId(syncId);
        if (existing != null) {
          quizLocalId = existing.id;
        } else {
          final folderSyncId = qzJson['folderSyncId'] as String?;
          final folderId =
              folderSyncId != null ? folderIdMap[folderSyncId] : null;

          String? imagePath;
          final imgName = qzJson['imageName'] as String?;
          if (imgName != null) imagePath = p.join(imgDir, imgName);

          quizLocalId = await _db!.insertQuizForSync(
            syncId: syncId,
            title: qzJson['title'] as String,
            folderId: folderId,
            imagePath: imagePath,
            languageCode: qzJson['languageCode'] as String?,
          );
          quizzesAdded++;
        }

        int order = 0;
        for (final qSyncId
            in (qzJson['questionSyncIds'] as List).map((e) => e as String)) {
          final qLocalId = questionIdMap[qSyncId];
          if (qLocalId == null) continue;
          await _db!.insertJunctionRowSafe(quizLocalId, qLocalId, order++);
        }
      }
    });

    // SRS (outside transaction — Hive)
    for (final srsJson in payload.srsData) {
      final questionSyncId = srsJson['questionSyncId'] as String;
      String localKey;

      if (int.tryParse(questionSyncId) != null) {
        // Permanent question — int-string key is stable across devices
        localKey = questionSyncId;
      } else {
        // Custom question — resolve UUID → local int ID
        final question = await _db!.getQuestionBySyncId(questionSyncId);
        if (question == null) continue;
        localKey = question.id.toString();
      }

      final incoming = UserQuestionData(
        questionId: localKey,
        streak: (srsJson['streak'] as num).toInt(),
        easeFactor: (srsJson['easeFactor'] as num).toDouble(),
        intervalSeconds: (srsJson['intervalSeconds'] as num).toDouble(),
        spacedRepetitionEnabled: srsJson['spacedRepetitionEnabled'] as bool,
        lastReviewed:
            DateTime.parse(srsJson['lastReviewed'] as String),
        nextReview: DateTime.parse(srsJson['nextReview'] as String),
      );
      await SrsService().upsertUserData(incoming);
      srsUpdated++;
    }

    return SyncResult(
      foldersAdded: foldersAdded,
      quizzesAdded: quizzesAdded,
      questionsAdded: questionsAdded,
      srsUpdated: srsUpdated,
      favoritesAdded: favoritesAdded,
    );
  }

  Map<String, dynamic> _localizeConfigImagePaths(
    Map<String, dynamic> config,
    String answerType,
    String imgDir,
  ) {
    if (answerType != 'flashcard') return config;
    final result = Map<String, dynamic>.from(config);
    if (result['frontImagePath'] != null) {
      result['frontImagePath'] =
          p.join(imgDir, result['frontImagePath'] as String);
    }
    if (result['backImagePath'] != null) {
      result['backImagePath'] =
          p.join(imgDir, result['backImagePath'] as String);
    }
    return result;
  }

  // ── Image transfer ───────────────────────────────────────────

  Future<void> _fetchImage(String base, String imageName) async {
    final safeName = p.basename(imageName);
    if (safeName.isEmpty) return;
    final imgDir = await _getImagesDir();
    final localFile = File(p.join(imgDir, safeName));
    if (await localFile.exists()) return;
    try {
      final resp = await http
          .get(Uri.parse('$base/sync/image?name=${Uri.encodeComponent(safeName)}'))
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) await localFile.writeAsBytes(resp.bodyBytes);
    } catch (_) {}
  }

  // ── Utilities ────────────────────────────────────────────────

  Future<String> _getImagesDir() async {
    if (kDebugMode) {
      return '${Directory.current.path}/assets/images';
    }
    final docDir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${docDir.path}/images');
    if (!await imgDir.exists()) await imgDir.create(recursive: true);
    return imgDir.path;
  }

  String get _deviceName {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Med Brew Device';
    }
  }

  void _progress(String message) {
    if (!_syncProgressController.isClosed) _syncProgressController.add(message);
  }

  void dispose() {
    _server?.close();
    discovery.dispose();
    _syncProgressController.close();
    _incomingRequestController.close();
    _acceptorDoneController.close();
  }
}

class SyncException implements Exception {
  final String message;
  const SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}
