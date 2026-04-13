class SyncPeer {
  final String deviceName;
  final String host;
  final int port;

  const SyncPeer({
    required this.deviceName,
    required this.host,
    required this.port,
  });

  @override
  bool operator ==(Object other) =>
      other is SyncPeer && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => '$deviceName ($host:$port)';
}

class SyncEntry {
  final String id;
  final DateTime createdAt;

  const SyncEntry({required this.id, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncEntry.fromJson(Map<String, dynamic> json) => SyncEntry(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class SyncManifest {
  final List<SyncEntry> folders;
  final List<SyncEntry> quizzes;
  final List<SyncEntry> questions;
  final List<String> srsKeys;
  final List<String> favoriteSyncIds;

  const SyncManifest({
    required this.folders,
    required this.quizzes,
    required this.questions,
    required this.srsKeys,
    required this.favoriteSyncIds,
  });

  Map<String, dynamic> toJson() => {
        'folders': folders.map((e) => e.toJson()).toList(),
        'quizzes': quizzes.map((e) => e.toJson()).toList(),
        'questions': questions.map((e) => e.toJson()).toList(),
        'srsKeys': srsKeys,
        'favoriteSyncIds': favoriteSyncIds,
      };

  factory SyncManifest.fromJson(Map<String, dynamic> json) => SyncManifest(
        folders: (json['folders'] as List)
            .map((e) => SyncEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        quizzes: (json['quizzes'] as List)
            .map((e) => SyncEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        questions: (json['questions'] as List)
            .map((e) => SyncEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        srsKeys: (json['srsKeys'] as List).map((e) => e as String).toList(),
        favoriteSyncIds:
            (json['favoriteSyncIds'] as List).map((e) => e as String).toList(),
      );
}

class SyncPayload {
  final List<Map<String, dynamic>> folders;
  final List<Map<String, dynamic>> quizzes;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> srsData;
  final List<String> favoriteSyncIds;
  final List<String> imageFilenames;

  const SyncPayload({
    required this.folders,
    required this.quizzes,
    required this.questions,
    required this.srsData,
    required this.favoriteSyncIds,
    required this.imageFilenames,
  });

  Map<String, dynamic> toJson() => {
        'folders': folders,
        'quizzes': quizzes,
        'questions': questions,
        'srsData': srsData,
        'favoriteSyncIds': favoriteSyncIds,
        'imageFilenames': imageFilenames,
      };

  factory SyncPayload.fromJson(Map<String, dynamic> json) => SyncPayload(
        folders: (json['folders'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        quizzes: (json['quizzes'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        questions: (json['questions'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        srsData: (json['srsData'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        favoriteSyncIds:
            (json['favoriteSyncIds'] as List).map((e) => e as String).toList(),
        imageFilenames:
            (json['imageFilenames'] as List).map((e) => e as String).toList(),
      );
}

class SyncResult {
  final int foldersAdded;
  final int quizzesAdded;
  final int questionsAdded;
  final int srsUpdated;
  final int favoritesAdded;

  const SyncResult({
    this.foldersAdded = 0,
    this.quizzesAdded = 0,
    this.questionsAdded = 0,
    this.srsUpdated = 0,
    this.favoritesAdded = 0,
  });

  bool get isEmpty =>
      foldersAdded == 0 &&
      quizzesAdded == 0 &&
      questionsAdded == 0 &&
      srsUpdated == 0 &&
      favoritesAdded == 0;
}
