import 'package:flutter/material.dart';
import 'package:med_brew/models/answer_state.dart';
import 'package:med_brew/models/question_data.dart';

class ImageClickWidget extends StatefulWidget {
  final QuestionData question;
  final Function(bool isCorrect) onAnswered;
  final bool locked;
  final AnswerState answerState;

  const ImageClickWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    required this.locked,
    required this.answerState,
  });

  @override
  State<ImageClickWidget> createState() => _ImageClickWidgetState();
}

class _ImageClickWidgetState extends State<ImageClickWidget> {
  bool _answered = false;
  Offset? _tapPosition;

  void _handleTap(TapUpDetails details, BuildContext context) {
    if (widget.locked || _answered) return;

    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final isCorrect = widget.question.imageClickConfig!.isCorrect(localPosition);

    setState(() {
      _answered = true;
      _tapPosition = localPosition;
    });

    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.question.imageClickConfig!;
    final answered = widget.answerState != AnswerState.unanswered;
    final isCorrect = widget.answerState == AnswerState.correct;

    return GestureDetector(
      onTapUp: (details) => _handleTap(details, context),
      child: Stack(
        children: [
          Image.asset(
            widget.question.imagePath!,
            fit: BoxFit.contain,
          ),

          // Overlay: drawn once the user has tapped.
          if (answered)
            Positioned.fill(
              child: CustomPaint(
                painter: _ClickOverlayPainter(
                  correctArea: config.correctArea,
                  tapPosition: _tapPosition,
                  wasCorrect: isCorrect,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClickOverlayPainter extends CustomPainter {
  final Rect correctArea;
  final Offset? tapPosition;
  final bool wasCorrect;

  _ClickOverlayPainter({
    required this.correctArea,
    required this.tapPosition,
    required this.wasCorrect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Green highlight showing the correct area.
    final correctFill = Paint()
      ..color = Colors.green.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final correctBorder = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(correctArea, correctFill);
    canvas.drawRect(correctArea, correctBorder);

    // If the user missed, draw a red cross where they tapped.
    if (!wasCorrect && tapPosition != null) {
      final crossPaint = Paint()
        ..color = Colors.red.shade600
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      const r = 10.0;
      final c = tapPosition!;
      canvas.drawLine(c.translate(-r, -r), c.translate(r, r), crossPaint);
      canvas.drawLine(c.translate(r, -r), c.translate(-r, r), crossPaint);
    }
  }

  @override
  bool shouldRepaint(_ClickOverlayPainter old) =>
      old.wasCorrect != wasCorrect ||
          old.tapPosition != tapPosition ||
          old.correctArea != correctArea;
}