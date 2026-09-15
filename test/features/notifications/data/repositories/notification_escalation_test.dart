import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/models/reminder_time_model.dart';
import 'package:consistency_tracker/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:consistency_tracker/features/notifications/data/repositories/notification_repository.dart';

class MockNotificationLocalDataSource extends Mock
    implements NotificationLocalDataSource {}

void main() {
  late MockNotificationLocalDataSource mockLocalDataSource;
  late NotificationRepositoryImpl repository;

  setUp(() {
    mockLocalDataSource = MockNotificationLocalDataSource();
    repository = NotificationRepositoryImpl(
      localDataSource: mockLocalDataSource,
    );
  });

  group('Notification Escalation & Closed-App Tests', () {
    final testGoal = GoalModel(
      id: 'escalation-goal-1',
      title: 'Deep Coding',
      description: 'Focus on Flutter architecture',
      targetMinutes: 30,
      reminderTimeHour: 18,
      reminderTimeMinute: 0,
      motivationalQuote: 'Keep building consistency!',
      colorHex: '#53B5EA',
      reminderTimes: const [ReminderTimeModel(hour: 18, minute: 0)],
      createdAt: DateTime(2026, 1, 1),
    );

    test(
      'scheduleGoalReminders schedules all 6 escalation slots for each reminder',
      () async {
        when(
          () => mockLocalDataSource.scheduleGoalNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.scheduleGoalReminders(testGoal);

        expect(result.isSuccess, isTrue);

        // 1 reminder * 6 escalation offsets = 6 scheduled notifications
        verify(
          () => mockLocalDataSource.scheduleGoalNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          ),
        ).called(6);
      },
    );

    test(
      'cancelGoalReminders invokes local datasource cancelGoalReminders',
      () async {
        when(
          () => mockLocalDataSource.cancelGoalReminders('escalation-goal-1'),
        ).thenAnswer((_) async {});

        final result = await repository.cancelGoalReminders(
          'escalation-goal-1',
        );

        expect(result.isSuccess, isTrue);
        verify(
          () => mockLocalDataSource.cancelGoalReminders('escalation-goal-1'),
        ).called(1);
      },
    );
  });
}
