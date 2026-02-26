import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:flutter/foundation.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final QuestionData question;
  final Function(bool isCorrect) onAnswered;
  final bool locked;

  const MultipleChoiceWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    required this.locked,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  late List<String> options;
  int? selectedIndex;
  late FocusNode _focusNode;

  bool get isDesktop {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();

    final config = widget.question.multipleChoiceConfig!;
    options = List.from(config.options);

    if (config.scrambleOptions) {
      options.shuffle(Random());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (widget.locked || selectedIndex != null) return;

    setState(() {
      selectedIndex = index;
    });

    final correctAnswer =
    widget.question.multipleChoiceConfig!.options[
    widget.question.multipleChoiceConfig!.correctIndex];

    final isCorrect = options[index] == correctAnswer;

    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    Widget buttons = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(options.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: widget.locked
                  ? null
                  : () => _selectOption(index),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
              ),
              child: Row(
                children: [
                  if (isDesktop)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 28,
                        child: _ShortcutBadge(number: index + 1),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      options[index],
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(child: buttons),
    );

    if (!isDesktop) return content;

    final topRowKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];

    final numpadKeys = [
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && !widget.locked) {
          for (int i = 0; i < options.length && i < 9; i++) {
            if (event.logicalKey == topRowKeys[i] ||
                event.logicalKey == numpadKeys[i]) {
              _selectOption(i);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: content,
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  final int number;

  const _ShortcutBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Text(
        number.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}