import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationLocalDataSource {
  Future<void> initialize();
  Future<void> scheduleGoalNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });
  Future<void> scheduleZonedGoalNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelGoalReminders(String goalId);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
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
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      macOS: darwinSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
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
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> scheduleGoalNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    return scheduleZonedGoalNotification(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  @override
  Future<void> cancelGoalReminders(String goalId) async {
    final int baseId = goalId.hashCode.abs() % 100000;
    // Cancel up to 100 potential reminder and escalation slots for this goal ID
    for (int i = 0; i < 100; i++) {
      await _notificationsPlugin.cancel(id: baseId + i);
    }
  }
}
