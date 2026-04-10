import 'package:flutter/material.dart';
import 'package:med_brew/l10n/app_localizations.dart';
import 'package:med_brew/models/quiz_data.dart';
import 'package:med_brew/services/favorites_service.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/screens/quiz_session_screen.dart';
import 'package:med_brew/widgets/quiz_tile.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService favoritesService = FavoritesService();
  final QuestionService questionService = QuestionService();
  bool _initialized = false;

  List<QuizData> _favoriteQuizzes = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      await favoritesService.init();

      final favoriteIds = favoritesService.allFavorites;

      _favoriteQuizzes = favoriteIds
          .map((id) => questionService.getQuiz(id))
          .whereType<QuizData>()
          .toList();
    } catch (_) {
      _favoriteQuizzes = [];
    }

    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_favoriteQuizzes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.favoritesTitle)),
        body: Center(child: Text(l10n.favoritesEmpty)),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 6;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteQuizzes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final quiz = _favoriteQuizzes[index];
          return QuizTile(
            quiz: quiz,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizSessionScreen(quizData: quiz),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
