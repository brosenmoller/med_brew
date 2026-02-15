import 'package:flutter/material.dart';
import 'package:med_brew/models/quiz_data.dart';
import 'package:med_brew/services/favorites_service.dart';
import 'package:med_brew/services/srs_service.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

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

  bool _hovering = false;
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Transform(
        alignment: Alignment.center,
        transform: _hovering
            ? (Matrix4.identity()..scaleByVector3(Vector3.all(1.02)))
            : Matrix4.identity(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
              image: widget.quiz.imagePath != null
                  ? DecorationImage(
                image: AssetImage(widget.quiz.imagePath!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(_hovering ? 0.25 : 0.4),
                  BlendMode.darken,
                ),
              )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hovering ? 0.25 : 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(1, 1),
                        ),
                      ],
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
        ),
      ),
    );
  }
}