import 'package:flutter/material.dart';
import 'package:med_brew/models/quiz_data.dart';
import 'package:med_brew/services/favorites_service.dart';
import 'package:med_brew/services/srs_service.dart';

class QuizTile extends StatefulWidget {
  final QuizData quiz;
  final VoidCallback onTap;

  const QuizTile({
    super.key,
    required this.quiz,
    required this.onTap,
  });

  @override
  State<QuizTile> createState() => _QuizTileState();
}

class _QuizTileState extends State<QuizTile> {
  final FavoritesService _favoritesService = FavoritesService();
  final SrsService _srsService = SrsService();

  bool _isFavorite = false;
  bool _isSrsEnabled = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    await _favoritesService.init();
    await _srsService.init();

    // Initialize favorite
    _isFavorite = _favoritesService.isFavorite(widget.quiz.id);

    // Initialize SRS based on first question
    final questions = _srsService.getQuestionsForQuiz(quiz: widget.quiz);
    _isSrsEnabled = questions.isNotEmpty
        ? _srsService.getUserData(questions.first).spacedRepetitionEnabled
        : false;

    setState(() {
      _initialized = true;
    });
  }

  void _toggleFavorite() async {
    if (!_initialized) return;

    setState(() => _isFavorite = !_isFavorite);

    if (_isFavorite) {
      await _favoritesService.addFavorite(widget.quiz.id);
    } else {
      await _favoritesService.removeFavorite(widget.quiz.id);
    }
  }

  void _toggleSrs() async {
    if (!_initialized) return;

    setState(() => _isSrsEnabled = !_isSrsEnabled);

    // Apply SRS to all questions in this quiz
    final questions = _srsService.getQuestionsForQuiz(quiz: widget.quiz);
    for (var question in questions) {
      final userData = _srsService.getUserData(question);
      userData.spacedRepetitionEnabled = _isSrsEnabled;
      await _srsService.updateUserData(userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Quiz title
            Center(
              child: Text(
                widget.quiz.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Top-right toggles
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SRS toggle
                  IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: _isSrsEnabled ? Colors.blue : Colors.white,
                      size: 20,
                    ),
                    onPressed: _toggleSrs,
                  ),

                  // Favorite toggle
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.star : Icons.star_border,
                      color: Colors.yellowAccent,
                      size: 20,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}