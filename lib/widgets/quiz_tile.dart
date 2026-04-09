import 'package:flutter/material.dart';
import 'package:med_brew/models/quiz_data.dart';
import 'package:med_brew/services/favorites_service.dart';
import 'package:med_brew/services/srs_service.dart';
import 'package:med_brew/widgets/app_image.dart';

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
    try {
      await _favoritesService.init();
      await _srsService.init();

      _isFavorite = _favoritesService.isFavorite(widget.quiz.id);

      final questions = _srsService.getQuestionsForQuiz(quiz: widget.quiz);
      _isSrsEnabled = questions.isNotEmpty
          ? _srsService.getUserData(questions.first).spacedRepetitionEnabled
          : false;
    } catch (_) {
      // Leave defaults (false) on failure
    }

    if (mounted) setState(() => _initialized = true);
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
    final questions = _srsService.getQuestionsForQuiz(quiz: widget.quiz);
    for (final question in questions) {
      final userData = _srsService.getUserData(question);
      userData.spacedRepetitionEnabled = _isSrsEnabled;
      await _srsService.updateUserData(userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.quiz.imagePath != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: _hovering ? 0.25 : 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base colour (shows only when there is no image)
                  const ColoredBox(color: Colors.green),

                  // Image layer — always painted, no flash
                  if (hasImage)
                    AppImage(
                      path: widget.quiz.imagePath,
                      fit: BoxFit.cover,
                    ),

                  // Darkening overlay, animated so it never causes a flash
                  AnimatedOpacity(
                    opacity: _hovering ? 0.25 : 0.4,
                    duration: const Duration(milliseconds: 150),
                    child: const ColoredBox(color: Colors.black),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        // Top-right toggles
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _IconToggle(
                              icon: Icons.repeat,
                              active: _isSrsEnabled,
                              activeColor: Colors.blue,
                              onPressed: _toggleSrs,
                            ),
                            _IconToggle(
                              icon: _isFavorite
                                  ? Icons.star
                                  : Icons.star_border,
                              active: _isFavorite,
                              activeColor: Colors.yellowAccent,
                              onPressed: _toggleFavorite,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
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
                        const Spacer(),
                        // Type badge
                        _TypeBadge(
                          icon: Icons.quiz_outlined,
                          label: 'Quiz',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onPressed;

  const _IconToggle({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: active ? activeColor : Colors.white, size: 20),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TypeBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
