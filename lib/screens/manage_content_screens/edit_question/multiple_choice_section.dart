import 'package:flutter/material.dart';
import 'package:med_brew/l10n/app_localizations.dart';

class MultipleChoiceSection extends StatelessWidget {
  final List<TextEditingController> optionControllers;
  final int correctIndex;
  final ValueChanged<int> onCorrectIndexChanged;

  const MultipleChoiceSection({
    super.key,
    required this.optionControllers,
    required this.correctIndex,
    required this.onCorrectIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.optionsLabel,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(4, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Radio<int>(
                value: i,
                groupValue: correctIndex,
                onChanged: (v) => onCorrectIndexChanged(v!),
              ),
              Expanded(
                child: TextFormField(
                  controller: optionControllers[i],
                  decoration: InputDecoration(
                    labelText: l10n.optionN(i + 1),
                    border: const OutlineInputBorder(),
                    fillColor: correctIndex == i
                        ? Colors.green.withOpacity(0.1)
                        : null,
                    filled: correctIndex == i,
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? l10n.required : null,
                ),
              ),
            ],
          ),
        )),
        Text(l10n.radioCorrectHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.green)),
      ],
    );
  }
}
