import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/services/srs_service.dart';

class SrsButtons extends StatefulWidget {
  final QuestionData question;
  final Function(SrsQuality quality)? onAnswered;

  const SrsButtons({
    super.key,
    required this.question,
    this.onAnswered,
  });

  @override
  State<SrsButtons> createState() => _SrsButtonsState();
}

class _SrsButtonsState extends State<SrsButtons> {
  final _focusNode = FocusNode();

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final qualities = SrsQuality.values; // [again, hard, good, easy]
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      widget.onAnswered?.call(qualities[0]);
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      widget.onAnswered?.call(qualities[1]);
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      widget.onAnswered?.call(qualities[2]);
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      widget.onAnswered?.call(qualities[3]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qualities = SrsQuality.values;
    final isDesktop = _isDesktop;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How well did you know this?',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(qualities.length, (i) {
            final quality = qualities[i];
            final nextDue = _computeNextReviewForQuality(quality);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _SrsChip(
                  quality: quality,
                  nextReview: _formatDuration(nextDue),
                  keyHint: isDesktop ? '${i + 1}' : null,
                  onTap: () => widget.onAnswered?.call(quality),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
      ],
    );

    if (isDesktop) {
      content = KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKey,
        child: content,
      );
    }

    return content;
  }

  DateTime _computeNextReviewForQuality(SrsQuality quality) {
    final userData = SrsService().getUserData(widget.question);
    final simulated = userData.copy();
    simulated.updateAfterAnswer(quality);
    return simulated.nextReview;
  }

  String _formatDuration(DateTime nextReview) {
    final diff = nextReview.difference(DateTime.now());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _SrsChip extends StatelessWidget {
  final SrsQuality quality;
  final String nextReview;
  final String? keyHint;
  final VoidCallback onTap;

  const _SrsChip({
    required this.quality,
    required this.nextReview,
    required this.onTap,
    this.keyHint,
  });

  Color _color() {
    switch (quality) {
      case SrsQuality.again:
        return Colors.red.shade400;
      case SrsQuality.hard:
        return Colors.orange.shade400;
      case SrsQuality.good:
        return Colors.blue.shade500;
      case SrsQuality.easy:
        return Colors.green.shade500;
    }
  }

  String _label() {
    switch (quality) {
      case SrsQuality.again:
        return 'Again';
      case SrsQuality.hard:
        return 'Hard';
      case SrsQuality.good:
        return 'Good';
      case SrsQuality.easy:
        return 'Easy';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _color(),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (keyHint != null)
            Text(
              keyHint!,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          Text(_label(), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(nextReview,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
