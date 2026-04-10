import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  late Box _box;

  /// Notifier for the currently active locale. null = follow system locale.
  final ValueNotifier<Locale?> localeNotifier = ValueNotifier(null);

  Future<void> init() async {
    _box = await Hive.openBox('settings');
    final code = _box.get('languageCode') as String?;
    if (code != null) {
      localeNotifier.value = Locale(code);
    }
  }

  /// The stored language code, or null for system default.
  String? get languageCode => _box.get('languageCode') as String?;

  Future<void> setLanguageCode(String? code) async {
    if (code == null) {
      await _box.delete('languageCode');
      localeNotifier.value = null;
    } else {
      await _box.put('languageCode', code);
      localeNotifier.value = Locale(code);
    }
  }
}
