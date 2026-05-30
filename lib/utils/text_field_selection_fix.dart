import 'package:flutter/material.dart';

/// Restores normal single-tap caret placement on Android (Samsung devices in
/// particular), where the keyboard can trap a [TextField] in a "stuck"
/// selection state: each tap extends an anchored selection instead of moving
/// the cursor, and tapping never returns the field to normal typing
/// (flutter/flutter#184744, flutter/flutter#98720 — still open upstream).
///
/// Pass the result as the field's `onTap`. A single tap collapses any range
/// selection to a caret at the tapped (extent) position. Double-tap and
/// long-press selection are unaffected, since those gestures don't fire
/// `onTap`. On non-affected platforms the framework has already collapsed the
/// selection by the time `onTap` runs, so this is a no-op there.
VoidCallback collapseSelectionOnTap(TextEditingController controller) {
  return () {
    final selection = controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      controller.selection =
          TextSelection.collapsed(offset: selection.extentOffset);
    }
  };
}
