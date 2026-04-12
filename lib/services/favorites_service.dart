import 'package:hive/hive.dart';
import 'package:med_brew/data/database/app_database.dart';

class FavoritesService {
  static const String _boxName = 'favoritesBox';

  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  late Box<String> _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<String>(_boxName);
    _initialized = true;
  }

  List<String> get allFavorites => _box.values.toList();
  bool isFavorite(String quizId) => _box.containsKey(quizId);
  Future<void> addFavorite(String quizId) async => _box.put(quizId, quizId);
  Future<void> removeFavorite(String quizId) async => _box.delete(quizId);

  /// Returns syncIds of all favorited custom quizzes (permanent quizzes have no syncId).
  Future<List<String>> getAllFavoriteSyncIds(AppDatabase db) async {
    final result = <String>[];
    for (final key in _box.keys.cast<String>()) {
      final intId = int.tryParse(key);
      if (intId == null) continue;
      final syncId = await db.getQuizSyncIdById(intId);
      if (syncId != null) result.add(syncId);
    }
    return result;
  }

  Future<void> clearAll() => _box.clear();

  /// Add a favorite by its syncId, resolving to the local int-string key.
  Future<void> addFavoriteBySyncId(String quizSyncId, AppDatabase db) async {
    final quiz = await db.getQuizBySyncId(quizSyncId);
    if (quiz == null) return;
    await addFavorite(quiz.id.toString());
  }
}