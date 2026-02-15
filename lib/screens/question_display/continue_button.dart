import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContinueButton extends StatelessWidget {
  final VoidCallback onContinue;

  const ContinueButton({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          onContinue();
        }
      },
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IconButton(
            iconSize: 36,
            icon: const Icon(Icons.arrow_forward),
            onPressed: onContinue,
          ),
        ),
      ),
    );
  }
}
