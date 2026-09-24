import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationLocalDataSource {
  Future<void> initialize();

  /// Shows the OS permission prompt (once); returns whether allowed.
  Future<bool> requestPermission();

  /// Whether notifications are currently allowed; null when unknown.
  Future<bool?> hasPermission();

  /// [weekday] (1 = Monday) repeats weekly instead of daily.
  Future<void> scheduleGoalNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool startTomorrow = false,
    int? weekday,
  });
  Future<void> scheduleZonedGoalNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool startTomorrow = false,
    int? weekday,
  });
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelGoalReminders(String goalId);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  /// Reminder IDs for a goal occupy `[baseId, baseId + idSpan)`.
  static const int idSpan = 320;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } else {
        final currentOffset = DateTime.now().timeZoneOffset;
        for (final location in tz.timeZoneDatabase.locations.values) {
          if (location.currentTimeZone.offset == currentOffset) {
            tz.setLocalLocation(location);
            break;
          }
        }
      }
    } catch (_) {
      // Gracefully maintain default if resolution is not supported
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    // Permission is requested in context (first goal / enabling reminders).
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      macOS: darwinSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
  }

  @override
  Future<bool> requestPermission() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final mac = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (mac != null) {
      return await mac.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    }
    final ios = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    }
    return true;
  }

  @override
  Future<bool?> hasPermission() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) return android.areNotificationsEnabled();
    final mac = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (mac != null) return (await mac.checkPermissions())?.isEnabled;
    final ios = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled;
    return null;
  }

  @override
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'phase_transitions',
      'Phase Transitions',
      channelDescription: 'Notifications on focus and break phase transitions',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      macOS: darwinDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  @override
  Future<void> scheduleZonedGoalNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool startTomorrow = false,
    int? weekday,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'consistency_reminders',
      'Goal Reminders',
      channelDescription:
          'Daily reminders to keep your focus consistency streak alive',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      macOS: darwinDetails,
      iOS: darwinDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime at(int dayOffset) => tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + dayOffset,
      hour,
      minute,
    );

    var offset = 0;
    if (weekday != null) {
      offset = (weekday - now.weekday) % 7;
      if ((offset == 0 && startTomorrow) || at(offset).isBefore(now)) {
        offset += 7;
      }
    } else if (startTomorrow || at(0).isBefore(now)) {
      offset = 1;
    }

    // Inexact scheduling needs no exact-alarm permission on Android 12+.
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: at(offset),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: weekday == null
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> scheduleGoalNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool startTomorrow = false,
    int? weekday,
  }) async {
    return scheduleZonedGoalNotification(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      startTomorrow: startTomorrow,
      weekday: weekday,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  @override
  Future<void> cancelGoalReminders(String goalId) async {
    final int baseId = goalId.hashCode.abs() % 100000;
    bool owned(int id) => id >= baseId && id < baseId + idSpan;
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      for (final p in pending.where((p) => owned(p.id))) {
        await _notificationsPlugin.cancel(id: p.id);
      }
    } catch (_) {
      for (var i = 0; i < idSpan; i++) {
        await _notificationsPlugin.cancel(id: baseId + i);
      }
    }
  }
}
