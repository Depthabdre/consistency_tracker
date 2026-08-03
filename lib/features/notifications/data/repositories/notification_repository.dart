import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
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
  Future<Result<void>> cancelReminder(int id);
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
            : 'You won\'t regret taking 20 minutes for your future self today.',
        hour: hour,
        minute: minute,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(NotificationFailure('Failed to schedule reminder: $e'));
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
}
