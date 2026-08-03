import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/models/reminder_time_model.dart';
import 'package:consistency_tracker/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:consistency_tracker/features/notifications/data/repositories/notification_repository.dart';

class MockNotificationLocalDataSource extends Mock
    implements NotificationLocalDataSource {}

void main() {
  late NotificationRepositoryImpl repository;
  late MockNotificationLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockNotificationLocalDataSource();
    repository = NotificationRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('NotificationRepository QA Skill Unit Tests', () {
    test('TC-P0-01 (Positive): initNotifications initializes local data source', () async {
      when(() => mockLocalDataSource.initialize()).thenAnswer((_) async {});

      final result = await repository.initNotifications();

      expect(result.isSuccess, isTrue);
      verify(() => mockLocalDataSource.initialize()).called(1);
    });

    test('TC-P0-02 (Positive): scheduleGoalReminders schedules all active reminder times', () async {
      when(() => mockLocalDataSource.scheduleGoalNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          )).thenAnswer((_) async {});

      final goal = GoalModel(
        id: 'g1',
        title: 'Deep Focus',
        description: 'Read research paper',
        targetMinutes: 30,
        reminderTimeHour: 9,
        reminderTimeMinute: 0,
        reminderTimes: const [
          ReminderTimeModel(hour: 9, minute: 0),
          ReminderTimeModel(hour: 18, minute: 30),
        ],
        motivationalQuote: 'Consistency is key',
        colorHex: '#6366F1',
        createdAt: DateTime.now(),
      );

      final result = await repository.scheduleGoalReminders(goal);

      expect(result.isSuccess, isTrue);
      verify(() => mockLocalDataSource.scheduleGoalNotification(
            id: any(named: 'id'),
            title: 'Target Reminder: Deep Focus',
            body: 'Consistency is key',
            hour: 9,
            minute: 0,
          )).called(1);
      verify(() => mockLocalDataSource.scheduleGoalNotification(
            id: any(named: 'id'),
            title: 'Target Reminder: Deep Focus',
            body: 'Consistency is key',
            hour: 18,
            minute: 30,
          )).called(1);
    });

    test('TC-N1-01 (Negative): Exception during scheduleGoalReminders maps cleanly to NotificationFailure', () async {
      when(() => mockLocalDataSource.scheduleGoalNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          )).thenThrow(Exception('OS notification channel error'));

      final goal = GoalModel(
        id: 'g2',
        title: 'Workout',
        description: 'Gym',
        targetMinutes: 45,
        reminderTimeHour: 7,
        reminderTimeMinute: 0,
        motivationalQuote: '',
        colorHex: '#38BDF8',
        createdAt: DateTime.now(),
      );

      final result = await repository.scheduleGoalReminders(goal);

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('Should not succeed'),
        onFailure: (failure) {
          expect(failure.message, contains('Failed to schedule goal reminders'));
        },
      );
    });

    test('TC-C0-01 (Monkey/Chaos): Goal deletion triggers cancelGoalReminders', () async {
      when(() => mockLocalDataSource.cancelGoalReminders('g1')).thenAnswer((_) async {});

      final result = await repository.cancelGoalReminders('g1');

      expect(result.isSuccess, isTrue);
      verify(() => mockLocalDataSource.cancelGoalReminders('g1')).called(1);
    });
  });
}
