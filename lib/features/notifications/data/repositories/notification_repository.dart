import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../goals/data/models/goal_model.dart';
import '../datasources/notification_local_datasource.dart';

abstract class NotificationRepository {
  Future<Result<void>> initNotifications();
  Future<Result<void>> scheduleReminder({
    required int id,
    required String title,
    required String quote,
    required int hour,
    required int minute,
  });
  Future<Result<void>> scheduleGoalReminders(GoalModel goal);
  Future<Result<void>> showImmediateNotification({
    required String title,
    required String body,
  });
  Future<Result<void>> cancelReminder(int id);
  Future<Result<void>> cancelGoalReminders(String goalId);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<void>> initNotifications() async {
    try {
      await localDataSource.initialize();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Notification init failed: $e'),
      );
    }
  }

  @override
  Future<Result<void>> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    try {
      await localDataSource.showImmediateNotification(title: title, body: body);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Immediate notification failed: $e'),
      );
    }
  }

  @override
  Future<Result<void>> scheduleReminder({
    required int id,
    required String title,
    required String quote,
    required int hour,
    required int minute,
  }) async {
    try {
      await localDataSource.scheduleGoalNotification(
        id: id,
        title: title,
        body: quote.isNotEmpty
            ? quote
            : 'You won\'t regret taking $title minutes for your future self today.',
        hour: hour,
        minute: minute,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Failed to schedule reminder: $e'),
      );
    }
  }

  static const List<int> _escalationOffsets = [-30, -20, -10, -5, -1, 0];

  static (int, int) _calculateOffsetTime(
    int hour,
    int minute,
    int offsetMinutes,
  ) {
    int totalMinutes = (hour * 60 + minute + offsetMinutes) % (24 * 60);
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    return (totalMinutes ~/ 60, totalMinutes % 60);
  }

  @override
  Future<Result<void>> scheduleGoalReminders(GoalModel goal) async {
    try {
      final baseId = goal.id.hashCode.abs() % 100000;
      final reminders = goal.activeReminderTimes;

      for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i];
        for (int j = 0; j < _escalationOffsets.length; j++) {
          final offset = _escalationOffsets[j];
          final (hour, minute) = _calculateOffsetTime(
            reminder.hour,
            reminder.minute,
            offset,
          );
          final slotId = baseId + (i * 10) + j;

          final String title;
          final String body;

          if (offset == 0) {
            title = 'Target Reminder: ${goal.title}';
            body = goal.motivationalQuote.isNotEmpty
                ? goal.motivationalQuote
                : 'Keep your consistency streak alive! Focus ${goal.targetMinutes} mins today.';
          } else {
            final minsRemaining = -offset;
            title = 'Upcoming: ${goal.title} (${minsRemaining}m)';
            body = goal.motivationalQuote.isNotEmpty
                ? goal.motivationalQuote
                : 'Target session begins in $minsRemaining minutes!';
          }

          await localDataSource.scheduleGoalNotification(
            id: slotId,
            title: title,
            body: body,
            hour: hour,
            minute: minute,
          );
        }
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Failed to schedule goal reminders: $e'),
      );
    }
  }

  @override
  Future<Result<void>> cancelReminder(int id) async {
    try {
      await localDataSource.cancelNotification(id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Failed to cancel reminder: $e'),
      );
    }
  }

  @override
  Future<Result<void>> cancelGoalReminders(String goalId) async {
    try {
      await localDataSource.cancelGoalReminders(goalId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NotificationFailure('Failed to cancel goal reminders: $e'),
      );
    }
  }
}
