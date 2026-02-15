import 'package:flutter/material.dart';
import 'package:med_brew/models/category_data.dart';
import 'package:med_brew/screens/quiz_overview_screen.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class CategoryTile extends StatefulWidget {
  final CategoryData category;
  final VoidCallback onTap;

  const CategoryTile({super.key, required this.category, required this.onTap});

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Transform(
        alignment: Alignment.center, // scale from center
        transform: _hovering
            ? (Matrix4.identity()..scaleByVector3(Vector3.all(1.02)))
            : Matrix4.identity(),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizOverviewScreen(category: widget.category),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
              image: widget.category.imagePath != null
                  ? DecorationImage(
                image: AssetImage(widget.category.imagePath!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: _hovering ? 0.25 : 0.4),
                  BlendMode.darken,
                ),
              )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _hovering ? 0.25 : 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.category.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}