import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/errors/failures.dart';
import 'package:consistency_tracker/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:consistency_tracker/features/notifications/data/repositories/notification_repository.dart';

class MockNotificationLocalDataSource extends Mock
    implements NotificationLocalDataSource {}

void main() {
  late NotificationRepository repository;
  late MockNotificationLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockNotificationLocalDataSource();
    repository = NotificationRepositoryImpl(localDataSource: mockDataSource);
  });

  group('initNotifications', () {
    test('Positive: should initialize local notification service successfully', () async {
      when(() => mockDataSource.initialize()).thenAnswer((_) async => {});

      final result = await repository.initNotifications();

      expect(result.isSuccess, isTrue);
      verify(() => mockDataSource.initialize()).called(1);
    });

    test('Negative: should return NotificationFailure when initialization throws error', () async {
      when(() => mockDataSource.initialize())
          .thenThrow(Exception('Permission denied'));

      final result = await repository.initNotifications();

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<NotificationFailure>());
      expect(result.failure!.message, contains('Permission denied'));
    });
  });

  group('scheduleReminder', () {
    test('Positive: should schedule goal notification with custom quote', () async {
      when(() => mockDataSource.scheduleGoalNotification(
            id: 101,
            title: 'Daily Code',
            body: 'Keep building!',
            hour: 9,
            minute: 0,
          )).thenAnswer((_) async => {});

      final result = await repository.scheduleReminder(
        id: 101,
        title: 'Daily Code',
        quote: 'Keep building!',
        hour: 9,
        minute: 0,
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockDataSource.scheduleGoalNotification(
            id: 101,
            title: 'Daily Code',
            body: 'Keep building!',
            hour: 9,
            minute: 0,
          )).called(1);
    });

    test('Edge Case: empty quote should fallback to default motivational text', () async {
      when(() => mockDataSource.scheduleGoalNotification(
            id: 102,
            title: 'Exercise',
            body: 'You won\'t regret taking 20 minutes for your future self today.',
            hour: 8,
            minute: 30,
          )).thenAnswer((_) async => {});

      final result = await repository.scheduleReminder(
        id: 102,
        title: 'Exercise',
        quote: '',
        hour: 8,
        minute: 30,
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockDataSource.scheduleGoalNotification(
            id: 102,
            title: 'Exercise',
            body: 'You won\'t regret taking 20 minutes for your future self today.',
            hour: 8,
            minute: 30,
          )).called(1);
    });
  });
}
