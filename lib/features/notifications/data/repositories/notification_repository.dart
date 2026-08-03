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
      return Result.failure(NotificationFailure('Notification init failed: $e'));
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
      return Result.failure(NotificationFailure('Immediate notification failed: $e'));
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
      return Result.failure(NotificationFailure('Failed to schedule reminder: $e'));
    }
  }

  @override
  Future<Result<void>> scheduleGoalReminders(GoalModel goal) async {
    try {
      final baseId = goal.id.hashCode.abs() % 100000;
      final reminders = goal.activeReminderTimes;

      for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i];
        await localDataSource.scheduleGoalNotification(
          id: baseId + i,
          title: 'Target Reminder: ${goal.title}',
          body: goal.motivationalQuote.isNotEmpty
              ? goal.motivationalQuote
              : 'Keep your consistency streak alive! Focus ${goal.targetMinutes} mins today.',
          hour: reminder.hour,
          minute: reminder.minute,
        );
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(NotificationFailure('Failed to schedule goal reminders: $e'));
    }
  }

  @override
  Future<Result<void>> cancelReminder(int id) async {
    try {
      await localDataSource.cancelNotification(id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(NotificationFailure('Failed to cancel reminder: $e'));
    }
  }

  @override
  Future<Result<void>> cancelGoalReminders(String goalId) async {
    try {
      await localDataSource.cancelGoalReminders(goalId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(NotificationFailure('Failed to cancel goal reminders: $e'));
    }
  }
}
