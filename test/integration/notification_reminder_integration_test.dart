import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/models/reminder_time_model.dart';
import 'package:consistency_tracker/features/goals/data/repositories/goal_repository.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_event.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_state.dart';
import 'package:consistency_tracker/features/notifications/data/repositories/notification_repository.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late GoalBloc goalBloc;
  late MockGoalRepository mockGoalRepository;
  late MockNotificationRepository mockNotificationRepository;

  setUpAll(() {
    registerFallbackValue(
      GoalModel(
        id: 'g_fallback',
        title: 'Fallback',
        description: '',
        targetMinutes: 25,
        reminderTimeHour: 9,
        reminderTimeMinute: 0,
        motivationalQuote: '',
        colorHex: '#53B5EA',
        createdAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockGoalRepository = MockGoalRepository();
    mockNotificationRepository = MockNotificationRepository();

    when(
      () => mockGoalRepository.getGoals(),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => mockGoalRepository.saveGoal(any()),
    ).thenAnswer((_) async => const Result.success(true));
    when(
      () => mockGoalRepository.deleteGoal(any()),
    ).thenAnswer((_) async => const Result.success(true));

    when(
      () => mockNotificationRepository.scheduleGoalReminders(any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => mockNotificationRepository.cancelGoalReminders(any()),
    ).thenAnswer((_) async => const Result.success(null));

    goalBloc = GoalBloc(
      goalRepository: mockGoalRepository,
      notificationRepository: mockNotificationRepository,
    );
  });

  group('Notification Reminder Integration QA Skill Tests', () {
    test(
      'TC-P0-01 (Positive): AddGoalEvent saves goal and triggers scheduleGoalReminders',
      () async {
        final goal = GoalModel(
          id: 'g_integration_1',
          title: 'Daily Coding',
          description: 'Build Flutter app',
          targetMinutes: 45,
          reminderTimeHour: 9,
          reminderTimeMinute: 0,
          reminderTimes: const [
            ReminderTimeModel(hour: 9, minute: 0),
            ReminderTimeModel(hour: 17, minute: 30),
          ],
          motivationalQuote: 'Daily discipline',
          colorHex: '#53B5EA',
          createdAt: DateTime.now(),
        );

        goalBloc.add(AddGoalEvent(goal));

        await expectLater(
          goalBloc.stream,
          emitsThrough(isA<GoalLoadedState>()),
        );

        verify(() => mockGoalRepository.saveGoal(goal)).called(1);
        verify(
          () => mockNotificationRepository.scheduleGoalReminders(goal),
        ).called(1);
      },
    );

    test(
      'TC-C0-01 (Monkey/Chaos): DeleteGoalEvent deletes goal and triggers cancelGoalReminders',
      () async {
        goalBloc.add(const DeleteGoalEvent('g_integration_1'));

        await expectLater(
          goalBloc.stream,
          emitsThrough(isA<GoalLoadedState>()),
        );

        verify(
          () => mockGoalRepository.deleteGoal('g_integration_1'),
        ).called(1);
        verify(
          () =>
              mockNotificationRepository.cancelGoalReminders('g_integration_1'),
        ).called(1);
      },
    );
  });
}
