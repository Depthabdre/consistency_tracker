import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/models/calendar_day_model.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/repositories/calendar_repository.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/repositories/goal_repository.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_event.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_state.dart';
import 'package:consistency_tracker/features/notifications/data/repositories/notification_repository.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockGoalRepository mockGoalRepository;
  late MockCalendarRepository mockCalendarRepository;
  late MockNotificationRepository mockNotificationRepository;

  final now = DateTime.now();
  final testGoal = GoalModel(
    id: 'sync-goal-1',
    title: 'Code Architecture',
    description: 'Clean design',
    targetMinutes: 40,
    reminderTimeHour: 10,
    reminderTimeMinute: 0,
    motivationalQuote: 'Architecture matters',
    colorHex: '#53B5EA',
    createdAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(testGoal);
  });

  setUp(() {
    mockGoalRepository = MockGoalRepository();
    mockCalendarRepository = MockCalendarRepository();
    mockNotificationRepository = MockNotificationRepository();
  });

  group('GoalBloc Startup Sync & Update Tests', () {
    test(
      'LoadGoalsEvent restores todayMinutes from CalendarRepository',
      () async {
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Result.success([testGoal]));

        final todayEntry = CalendarDayModel(
          date: DateTime(now.year, now.month, now.day),
          totalMinutesFocused: 25,
          targetMinutes: 40,
          isCompleted: false,
        );

        when(
          () => mockCalendarRepository.getCalendarEntries('sync-goal-1'),
        ).thenAnswer((_) async => Result.success([todayEntry]));

        final bloc = GoalBloc(
          goalRepository: mockGoalRepository,
          calendarRepository: mockCalendarRepository,
          notificationRepository: mockNotificationRepository,
        );

        bloc.add(const LoadGoalsEvent());

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<GoalLoadingState>(),
            predicate<GoalLoadedState>((state) {
              return state.goals.length == 1 &&
                  state.todayMinutesByGoalId['sync-goal-1'] == 25;
            }),
          ]),
        );

        verify(
          () => mockCalendarRepository.getCalendarEntries('sync-goal-1'),
        ).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'UpdateGoalEvent saves modified goal and reschedules reminders',
      setUp: () {
        when(
          () => mockGoalRepository.saveGoal(any()),
        ).thenAnswer((_) async => const Result.success(true));
        when(
          () => mockGoalRepository.getGoals(),
        ).thenAnswer((_) async => Result.success([testGoal]));
        when(
          () => mockNotificationRepository.cancelGoalReminders(any()),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockNotificationRepository.scheduleGoalReminders(any()),
        ).thenAnswer((_) async => const Result.success(null));
      },
      build: () => GoalBloc(
        goalRepository: mockGoalRepository,
        notificationRepository: mockNotificationRepository,
      ),
      act: (bloc) => bloc.add(UpdateGoalEvent(testGoal)),
      expect: () => [isA<GoalLoadingState>(), isA<GoalLoadedState>()],
      verify: (_) {
        verify(() => mockGoalRepository.saveGoal(testGoal)).called(1);
        verify(
          () => mockNotificationRepository.cancelGoalReminders(testGoal.id),
        ).called(1);
        verify(
          () => mockNotificationRepository.scheduleGoalReminders(testGoal),
        ).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'UpdateGoalEvent preserves loaded progress map without flickering GoalLoadingState when already loaded',
      setUp: () {
        when(
          () => mockGoalRepository.saveGoal(any()),
        ).thenAnswer((_) async => const Result.success(true));
        when(
          () => mockNotificationRepository.cancelGoalReminders(any()),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockNotificationRepository.scheduleGoalReminders(any()),
        ).thenAnswer((_) async => const Result.success(null));
      },
      build: () => GoalBloc(
        goalRepository: mockGoalRepository,
        notificationRepository: mockNotificationRepository,
      ),
      seed: () => GoalLoadedState(
        [testGoal],
        todayMinutesByGoalId: {'sync-goal-1': 25},
      ),
      act: (bloc) =>
          bloc.add(UpdateGoalEvent(testGoal.copyWith(title: 'Updated Title'))),
      expect: () => [
        predicate<GoalLoadedState>((state) {
          return state.goals.first.title == 'Updated Title' &&
              state.todayMinutesByGoalId['sync-goal-1'] == 25;
        }),
      ],
      verify: (_) {
        verify(() => mockGoalRepository.saveGoal(any())).called(1);
        verify(
          () => mockNotificationRepository.cancelGoalReminders(testGoal.id),
        ).called(1);
        verify(
          () => mockNotificationRepository.scheduleGoalReminders(any()),
        ).called(1);
      },
    );
  });
}
