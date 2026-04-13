import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/l10n/app_localizations.dart';
import 'package:med_brew/screens/sync_screen.dart';
import 'package:med_brew/services/favorites_service.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/settings_service.dart';
import 'package:med_brew/services/srs_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppDatabase db;

  const SettingsScreen({super.key, required this.db});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SrsService _srsService = SrsService();
  final SettingsService _settings = SettingsService();

  Future<void> _confirmWipe(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe all content?'),
        content: const Text(
            'This deletes every folder, quiz, question, SRS record, and '
            'favorite. Content cannot be recovered — re-import packs from '
            'the Content Packs screen afterwards.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Wipe'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await widget.db.wipeAllContent();
    await SrsService().resetAll();
    await FavoritesService().clearAll();
    await QuestionService().refresh();

    messenger.showSnackBar(
      const SnackBar(content: Text('All content wiped.')),
    );
  }

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

            // ── Sync ─────────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sync_rounded),
              title: Text(l10n.navSync),
              subtitle: Text(l10n.navSyncSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SyncScreen(db: widget.db)),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // ── Dev: wipe all content ────────────────────────────
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Wipe all content (dev)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () => _confirmWipe(context),
              ),
              const Divider(),
            ],

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
