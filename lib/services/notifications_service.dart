// lib/services/notifications_service.dart
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// NotificationsService using flutter_local_notifications + timezone (Asia/Kolkata)
class NotificationsService {
  NotificationsService._();
  static final NotificationsService _instance = NotificationsService._();
  static NotificationsService get instance => _instance;

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // initialize timezone DB and set local zone to Asia/Kolkata
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings();

    await _fln.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // handle notification tap: payload may be "task:123", "bill:45", "emi:7"
        // You can route using navigatorKey from main.dart if you want deep links
      },
    );

    // create android notification channel
    const channel = AndroidNotificationChannel(
      'reminders_channel',
      'Reminders',
      description: 'Reminders for tasks, bills and EMIs',
      importance: Importance.high,
    );

    await _fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final ios = _fln.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final mac = _fln.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    var ok = true;
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      ok = ok && (granted ?? false);
    }
    if (mac != null) {
      final granted = await mac.requestPermissions(alert: true, badge: true, sound: true);
      ok = ok && (granted ?? false);
    }
    return ok;
  }

  int generateId() => Random().nextInt(1 << 31);

  /// Schedule a one-time notification (TZ-aware). Use deterministic id so it can be cancelled/updated later.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate, // local DateTime (interpreted as Asia/Kolkata)
    String? payload,
  }) async {
    await init();

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders_channel',
        'Reminders',
        channelDescription: 'Reminders for tasks, bills and EMIs',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // Use zonedSchedule for one-shot with required androidScheduleMode param
    await _fln.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule daily at given hour/minute (repeats daily)
  Future<void> scheduleDailyAtTime({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    final details = NotificationDetails(
      android: AndroidNotificationDetails('reminders_channel', 'Reminders'),
      iOS: const DarwinNotificationDetails(),
    );

    await _fln.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // daily
    );
  }

  /// Schedule monthly on a day-of-month + time (repeats monthly)
  Future<void> scheduleMonthly({
    required int id,
    required String title,
    required String body,
    required int day,
    required int hour,
    required int minute,
    required int startYear,
    required int startMonth,
    String? payload,
  }) async {
    await init();

    int y = startYear;
    int m = startMonth;

    tz.TZDateTime candidate() {
      final lastDay = tz.TZDateTime(tz.local, y, m + 1, 0).day;
      final d = day > lastDay ? lastDay : day;
      return tz.TZDateTime(tz.local, y, m, d, hour, minute);
    }

    var schedule = candidate();
    final now = tz.TZDateTime.now(tz.local);
    while (schedule.isBefore(now)) {
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
      schedule = candidate();
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails('reminders_channel', 'Reminders'),
      iOS: const DarwinNotificationDetails(),
    );

    await _fln.zonedSchedule(
      id,
      title,
      body,
      schedule,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> cancel(int id) async {
    await _fln.cancel(id);
  }

  Future<void> cancelAll() async {
    await _fln.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    return _fln.pendingNotificationRequests();
  }
}
