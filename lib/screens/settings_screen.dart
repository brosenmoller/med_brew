import 'package:flutter/material.dart';
import 'package:med_brew/l10n/app_localizations.dart';
import 'package:med_brew/services/settings_service.dart';
import 'package:med_brew/services/srs_service.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SrsService _srsService = SrsService();
  final SettingsService _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Language ──────────────────────────────────────────
            DropdownButtonFormField<String?>(
              value: _settings.languageCode,
              decoration: InputDecoration(
                labelText: l10n.settingsLanguage,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.settingsLanguageSystem),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.settingsLanguageEnglish),
                ),
                DropdownMenuItem(
                  value: 'nl',
                  child: Text(l10n.settingsLanguageDutch),
                ),
              ],
              onChanged: (code) async {
                await _settings.setLanguageCode(code);
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 20),

            // ── Reset SRS ────────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.settingsResetSrs),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.settingsResetSrsDialogTitle),
                    content: Text(l10n.settingsResetSrsDialogContent),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(l10n.reset),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _srsService.resetAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsResetSrsSuccess)),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
