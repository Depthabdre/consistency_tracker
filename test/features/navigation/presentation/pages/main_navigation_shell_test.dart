import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/repositories/calendar_repository.dart';
import 'package:consistency_tracker/features/calendar_heatmap/presentation/bloc/calendar_bloc.dart';
import 'package:consistency_tracker/features/focus_timer/data/repositories/focus_session_repository.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_bloc.dart';
import 'package:consistency_tracker/features/goals/data/repositories/goal_repository.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:consistency_tracker/features/navigation/presentation/pages/main_navigation_shell.dart';
import 'package:consistency_tracker/features/settings/data/repositories/settings_repository.dart';
import 'package:consistency_tracker/features/settings/domain/entities/app_settings.dart';
import 'package:consistency_tracker/features/settings/presentation/bloc/settings_bloc.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockFocusSessionRepository extends Mock
    implements FocusSessionRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockGoalRepository mockGoalRepository;
  late MockCalendarRepository mockCalendarRepository;
  late MockFocusSessionRepository mockFocusSessionRepository;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockGoalRepository = MockGoalRepository();
    mockCalendarRepository = MockCalendarRepository();
    mockFocusSessionRepository = MockFocusSessionRepository();
    mockSettingsRepository = MockSettingsRepository();

    when(
      () => mockGoalRepository.getGoals(),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => mockSettingsRepository.getSettings(),
    ).thenAnswer((_) async => const Result.success(AppSettings.defaults));
  });

  testWidgets('MainNavigationShell renders 3 tabs and switches between them', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<GoalRepository>.value(value: mockGoalRepository),
          RepositoryProvider<CalendarRepository>.value(
            value: mockCalendarRepository,
          ),
          RepositoryProvider<FocusSessionRepository>.value(
            value: mockFocusSessionRepository,
          ),
          RepositoryProvider<SettingsRepository>.value(
            value: mockSettingsRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GoalBloc>(
              create: (_) => GoalBloc(goalRepository: mockGoalRepository),
            ),
            BlocProvider<FocusTimerBloc>(
              create: (_) =>
                  FocusTimerBloc(sessionRepository: mockFocusSessionRepository),
            ),
            BlocProvider<CalendarBloc>(
              create: (_) =>
                  CalendarBloc(calendarRepository: mockCalendarRepository),
            ),
            BlocProvider<SettingsBloc>(
              create: (_) => SettingsBloc(repository: mockSettingsRepository),
            ),
          ],
          child: const MaterialApp(home: MainNavigationShell()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial tab is Today
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tap Insights
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Your consistency across all goals'), findsOneWidget);

    // Tap Settings
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Session setup'), findsOneWidget);
  });
}
