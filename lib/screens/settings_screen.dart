import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/l10n/app_localizations.dart';
import 'package:med_brew/models/srs_settings.dart';
import 'package:med_brew/screens/sync_screen.dart';
import 'package:med_brew/services/favorites_service.dart';
import 'package:med_brew/services/notification_service.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/settings_service.dart';
import 'package:med_brew/services/srs_service.dart';
import 'package:med_brew/services/streak_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppDatabase db;

  const SettingsScreen({super.key, required this.db});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SrsService _srsService = SrsService();
  final SettingsService _settings = SettingsService();
  final StreakService _streak = StreakService();
  final NotificationService _notifs = NotificationService();

  late SrsSettings _srs;
  late bool _streakEnabled;
  late bool _notifsEnabled;
  late TimeOfDay _notifTime;

  @override
  void initState() {
    super.initState();
    _srs = _settings.srsSettings;
    _streakEnabled = _streak.streakEnabled;
    _notifsEnabled = _streak.notifsEnabled;
    _notifTime = TimeOfDay(hour: _streak.notifsHour, minute: _streak.notifsMinute);
  }

  Future<void> _saveSrs(SrsSettings updated) async {
    setState(() => _srs = updated);
    await _settings.setSrsSettings(updated);
  }

  Future<void> _resetSrs() async {
    await _settings.resetSrsSettings();
    setState(() => _srs = const SrsSettings());
  }


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
      body: ListView(
        padding: const EdgeInsets.all(16),
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

            // ── Streak ───────────────────────────────────────────
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.hardEdge,
              child: ExpansionTile(
                leading: const Icon(Icons.local_fire_department),
                title: Text(l10n.streakSectionTitle),
                subtitle: ValueListenableBuilder<StreakState>(
                  valueListenable: _streak.streakNotifier,
                  builder: (context, state, _) => Text(
                    state.streakEnabled && state.streakCount > 0
                        ? l10n.streakCount(state.streakCount)
                        : l10n.streakEnabledSubtitle,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                children: [
                  SwitchListTile(
                    title: Text(l10n.streakEnabledToggle),
                    value: _streakEnabled,
                    onChanged: (v) async {
                      await _streak.setStreakEnabled(v);
                      setState(() => _streakEnabled = v);
                    },
                  ),
                  if (_streakEnabled) ...[
                    SwitchListTile(
                      title: Text(l10n.streakNotifsToggle),
                      subtitle: Text(l10n.streakNotifsSubtitle),
                      value: _notifsEnabled,
                      onChanged: (v) async {
                        if (v) {
                          final granted = await _notifs.requestPermission();
                          if (!granted) return;
                        }
                        await _streak.setNotifsEnabled(v);
                        if (mounted) setState(() => _notifsEnabled = v);
                      },
                    ),
                    if (_notifsEnabled)
                      ListTile(
                        title: Text(l10n.streakNotifsTime),
                        trailing: Text(
                          _notifTime.format(context),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _notifTime,
                          );
                          if (picked == null || !mounted) return;
                          await _streak.setNotifTime(picked.hour, picked.minute);
                          setState(() => _notifTime = picked);
                        },
                      ),
                    const Divider(indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        label: Text(l10n.streakResetButton),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.streakResetDialogTitle),
                              content: Text(l10n.streakResetDialogContent),
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
                          if (confirm == true) await _streak.resetStreak();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── SRS Algorithm ────────────────────────────────────
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.hardEdge,
              child: ExpansionTile(
                leading: const Icon(Icons.tune),
                title: const Text('SRS Algorithm'),
                subtitle: const Text('Adjust scheduling behaviour'),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                children: [
                  _SrsSliderRow(
                    key: ValueKey('lapse_${_srs.lapseMultiplier}'),
                    label: 'Lapse multiplier',
                    initialValue: _srs.lapseMultiplier,
                    min: 0.05,
                    max: 0.75,
                    divisions: 14,
                    formatValue: (v) => v.toStringAsFixed(2),
                    description:
                        'On "Again", keep this fraction of the card\'s current interval.',
                    onChangeEnd: (v) => _saveSrs(
                      _srs.copyWith(lapseMultiplier: double.parse(v.toStringAsFixed(2))),
                    ),
                  ),
                  _SrsSliderRow(
                    key: ValueKey('again_${_srs.easeAgain}'),
                    label: 'Again — ease penalty',
                    initialValue: _srs.easeAgain,
                    min: -0.50,
                    max: -0.05,
                    divisions: 9,
                    formatValue: (v) => v.toStringAsFixed(2),
                    description: 'How much the ease factor drops on each lapse.',
                    onChangeEnd: (v) => _saveSrs(
                      _srs.copyWith(easeAgain: double.parse(v.toStringAsFixed(2))),
                    ),
                  ),
                  _SrsSliderRow(
                    key: ValueKey('hard_${_srs.easeHard}'),
                    label: 'Hard — ease penalty',
                    initialValue: _srs.easeHard,
                    min: -0.50,
                    max: -0.05,
                    divisions: 9,
                    formatValue: (v) => v.toStringAsFixed(2),
                    description: 'How much the ease factor drops on "Hard".',
                    onChangeEnd: (v) => _saveSrs(
                      _srs.copyWith(easeHard: double.parse(v.toStringAsFixed(2))),
                    ),
                  ),
                  _SrsSliderRow(
                    key: ValueKey('good_${_srs.easeGood}'),
                    label: 'Good — ease adjustment',
                    initialValue: _srs.easeGood,
                    min: -0.05,
                    max: 0.10,
                    divisions: 15,
                    formatValue: (v) {
                      final s = v.toStringAsFixed(2);
                      return v > 0 ? '+$s' : s;
                    },
                    description: 'How much the ease factor shifts on "Good". Default 0 keeps it neutral.',
                    onChangeEnd: (v) => _saveSrs(
                      _srs.copyWith(easeGood: double.parse(v.toStringAsFixed(2))),
                    ),
                  ),
                  _SrsSliderRow(
                    key: ValueKey('easy_${_srs.easeEasy}'),
                    label: 'Easy — ease bonus',
                    initialValue: _srs.easeEasy,
                    min: 0.05,
                    max: 0.50,
                    divisions: 9,
                    formatValue: (v) => '+${v.toStringAsFixed(2)}',
                    description: 'How much the ease factor rises on "Easy".',
                    onChangeEnd: (v) => _saveSrs(
                      _srs.copyWith(easeEasy: double.parse(v.toStringAsFixed(2))),
                    ),
                  ),
                  _SrsSliderRow(
                    key: ValueKey('initial_${_srs.initialEase}'),
                    label: 'Initial ease factor',
                    initialValue: _srs.initialEase,
                    min: 1.3,
                    max: 3.0,
                    divisions: 17,
                    formatValue: (v) => v.toStringAsFixed(1),
                    description: 'Starting ease factor for newly enrolled cards.',
                    onChangeEnd: (v) => _saveSrs(
                      _srs.copyWith(initialEase: double.parse(v.toStringAsFixed(1))),
                    ),
                  ),
                  _SrsSliderRow(
                    key: ValueKey('maxInterval_${_srs.maxIntervalDays}'),
                    label: 'Max interval',
                    initialValue: _srs.maxIntervalDays.toDouble(),
                    min: 30,
                    max: 365,
                    divisions: 67,
                    formatValue: (v) => '${v.round()} days',
                    description: 'Longest interval a card can be scheduled.',
                    onChangeEnd: (v) =>
                        _saveSrs(_srs.copyWith(maxIntervalDays: v.round())),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to defaults'),
                      onPressed: _resetSrs,
                    ),
                  ),
                ],
              ),
            ),

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
    );
  }
}

class _SrsSliderRow extends StatefulWidget {
  final String label;
  final double initialValue;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) formatValue;
  final ValueChanged<double> onChangeEnd;
  final String? description;

  const _SrsSliderRow({
    super.key,
    required this.label,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.formatValue,
    required this.onChangeEnd,
    this.description,
  });

  @override
  State<_SrsSliderRow> createState() => _SrsSliderRowState();
}

class _SrsSliderRowState extends State<_SrsSliderRow> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                widget.formatValue(_value),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (widget.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                widget.description!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: widget.onChangeEnd,
          ),
        ],
      ),
    );
  }
}
