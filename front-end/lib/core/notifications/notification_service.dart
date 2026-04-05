import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../storage/storage_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    await init();

    var granted = true;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? granted;
    }

    if (iosPlugin != null) {
      granted =
          (await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          granted;
    }

    if (macPlugin != null) {
      granted =
          (await macPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          granted;
    }

    return granted;
  }

  Future<void> syncReminderPreference() async {
    await init();
    final storage = StorageService();
    final notificationsEnabled = storage.getNotificationsEnabled();
    final remindersEnabled = storage.getDailyReminderEnabled();

    if (!notificationsEnabled || !remindersEnabled) {
      await cancelDailyReminder();
      return;
    }

    final granted = await requestPermissions();
    if (!granted) {
      debugPrint('Notifications permission not granted.');
      return;
    }

    await scheduleDailyReminder(hour: storage.getDailyReminderHour());
  }

  Future<void> scheduleDailyReminder({required int hour}) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledAt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour.clamp(0, 23),
    );
    if (scheduledAt.isBefore(now)) {
      scheduledAt = scheduledAt.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder_channel',
        'Rappels quotidiens',
        channelDescription: 'Rappels locaux pour contribuer sur MoroccoCheck',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        'MoroccoCheck',
        'Pensez a partager un check-in, un avis ou une mise a jour terrain aujourd hui.',
        scheduledAt,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (error) {
      if (error.code != 'exact_alarms_not_permitted') {
        rethrow;
      }

      debugPrint(
        'Exact alarms are not permitted on this device. Falling back to inexact scheduling.',
      );
      await _plugin.zonedSchedule(
        _dailyReminderId,
        'MoroccoCheck',
        'Pensez a partager un check-in, un avis ou une mise a jour terrain aujourd hui.',
        scheduledAt,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(_dailyReminderId);
  }

  Future<void> showTestNotification() async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'general_channel',
        'General',
        channelDescription: 'Notifications locales generales',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      2001,
      'MoroccoCheck',
      'Les notifications locales sont actives sur cet appareil.',
      details,
    );
  }
}
