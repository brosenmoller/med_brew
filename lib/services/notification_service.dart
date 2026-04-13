import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _supported = false;

  bool get isSupported => _supported;

  static const _reminderId = 0;
  static const _channelId = 'streak_reminder';
  static const _channelName = 'Daily Reminder';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      tz_data.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const linux = LinuxInitializationSettings(defaultActionName: 'Open');
      const settings = InitializationSettings(android: android, linux: linux);
      await _plugin.initialize(settings);
      _supported = Platform.isAndroid || Platform.isLinux;
    } catch (_) {
      _supported = false;
    }
  }

  /// Requests POST_NOTIFICATIONS permission on Android 13+.
  /// Returns true if permission is granted (or not needed on the current platform).
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      if (Platform.isAndroid) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await impl?.requestNotificationsPermission() ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancels any existing reminder and schedules a new daily one at [hour]:[minute]
  /// (local time). Repeats every 24 h at the same UTC-converted time.
  Future<void> rescheduleReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    try {
      await _plugin.cancelAll();

      // Convert desired local time to UTC for scheduling.
      final now = DateTime.now();
      var nextLocal = DateTime(now.year, now.month, now.day, hour, minute);
      if (!nextLocal.isAfter(now)) {
        nextLocal = nextLocal.add(const Duration(days: 1));
      }
      final nextUtc = nextLocal.toUtc();
      final tzDate = tz.TZDateTime(
        tz.UTC,
        nextUtc.year,
        nextUtc.month,
        nextUtc.day,
        nextUtc.hour,
        nextUtc.minute,
      );

      await _plugin.zonedSchedule(
        _reminderId,
        title,
        body,
        tzDate,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Daily reminder to keep your study streak',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> cancelReminder() async {
    if (!_supported) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
