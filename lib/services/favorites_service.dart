import 'package:hive/hive.dart';

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
}