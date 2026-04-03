import 'package:flutter/material.dart';
import 'package:med_brew/models/answer_state.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/widgets/app_image.dart';

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
  Offset? _tapPosition;

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    if (widget.locked) return;

    final localPosition = details.localPosition;
    final size = Size(constraints.maxWidth, constraints.maxHeight);

    // Normalize the tap to 0.0–1.0 to match the stored correctArea
    final normalizedTap = Offset(
      localPosition.dx / size.width,
      localPosition.dy / size.height,
    );

    final isCorrect =
    widget.question.imageClickConfig!.isCorrect(normalizedTap);

    setState(() => _tapPosition = localPosition);
    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.question.imagePath;

    if (imagePath == null) {
      return const Center(
        child: Text(
          'No image set for this question.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    final config = widget.question.imageClickConfig!;
    final answered = widget.answerState != AnswerState.unanswered;
    final isCorrect = widget.answerState == AnswerState.correct;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: AspectRatio(
      aspectRatio: 16 / 9,
      child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapUp: (details) => _handleTap(details, constraints),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    path: imagePath,
                    fit: BoxFit.contain,
                  ),
                  if (answered)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ClickOverlayPainter(
                          // Pass normalized rect — painter will scale to canvas
                          correctArea: config.correctArea,
                          // Normalize tap position for the painter too
                          tapPosition: _tapPosition != null
                              ? Offset(
                            _tapPosition!.dx / constraints.maxWidth,
                            _tapPosition!.dy / constraints.maxHeight,
                          )
                              : null,
                          wasCorrect: isCorrect,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
      ),
    ),
    );
  }
}


class _ClickOverlayPainter extends CustomPainter {
  final Rect correctArea;     // normalized 0.0–1.0
  final Offset? tapPosition;  // normalized 0.0–1.0
  final bool wasCorrect;

  _ClickOverlayPainter({
    required this.correctArea,
    required this.tapPosition,
    required this.wasCorrect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale the normalized rect to canvas pixels
    final scaledRect = Rect.fromLTRB(
      correctArea.left * size.width,
      correctArea.top * size.height,
      correctArea.right * size.width,
      correctArea.bottom * size.height,
    );

    canvas.drawRect(
      scaledRect,
      Paint()
        ..color = Colors.green.withOpacity(0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      scaledRect,
      Paint()
        ..color = Colors.green.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Red cross at the tap position if wrong
    if (!wasCorrect && tapPosition != null) {
      final scaledTap = Offset(
        tapPosition!.dx * size.width,
        tapPosition!.dy * size.height,
      );
      const r = 10.0;
      final crossPaint = Paint()
        ..color = Colors.red.shade600
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          scaledTap.translate(-r, -r), scaledTap.translate(r, r), crossPaint);
      canvas.drawLine(
          scaledTap.translate(r, -r), scaledTap.translate(-r, r), crossPaint);
    }
  }

  @override
  bool shouldRepaint(_ClickOverlayPainter old) =>
      old.wasCorrect != wasCorrect ||
          old.tapPosition != tapPosition ||
          old.correctArea != correctArea;
}