import 'package:flutter/material.dart';
import 'package:med_brew/services/srs_service.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final SrsService srsService = SrsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text("Reset all SRS data"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () async {
                // Confirm before resetting
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Reset SRS Data"),
                    content: const Text(
                        "Are you sure you want to reset all SRS data? This cannot be undone."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await srsService.resetAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All SRS data reset")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
