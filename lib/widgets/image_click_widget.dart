import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';

class ImageClickWidget extends StatefulWidget {
  final QuestionData question;
  final Function(bool isCorrect) onAnswered;
  final bool locked;

  const ImageClickWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    required this.locked,
  });

  @override
  State<ImageClickWidget> createState() =>
      _ImageClickWidgetState();
}

class _ImageClickWidgetState extends State<ImageClickWidget> {
  bool answered = false;

  void _handleTap(TapUpDetails details, BuildContext context) {
    if (widget.locked || answered) return;

    final box = context.findRenderObject() as RenderBox;
    final localPosition =
    box.globalToLocal(details.globalPosition);

    final config = widget.question.imageClickConfig!;
    final isCorrect = config.isCorrect(localPosition);

    setState(() {
      answered = true;
    });

    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) =>
          _handleTap(details, context),
      child: Image.asset(
        widget.question.imagePath!,
        fit: BoxFit.contain,
      ),
    );
  }
}