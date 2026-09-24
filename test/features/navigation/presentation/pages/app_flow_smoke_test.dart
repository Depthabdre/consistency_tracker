import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/theme/app_theme.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/models/calendar_day_model.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/repositories/calendar_repository.dart';
import 'package:consistency_tracker/features/calendar_heatmap/presentation/bloc/calendar_bloc.dart';
import 'package:consistency_tracker/features/calendar_heatmap/presentation/reusable_widgets/calendar_grid_widget.dart';
import 'package:consistency_tracker/features/focus_timer/data/models/focus_session_model.dart';
import 'package:consistency_tracker/features/focus_timer/data/repositories/focus_session_repository.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_bloc.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_event.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/repositories/goal_repository.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_event.dart';
import 'package:consistency_tracker/features/navigation/presentation/pages/main_navigation_shell.dart';
import 'package:consistency_tracker/features/settings/data/repositories/settings_repository.dart';
import 'package:consistency_tracker/features/settings/domain/entities/app_settings.dart';
import 'package:consistency_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:consistency_tracker/features/settings/presentation/bloc/settings_event.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockFocusSessionRepository extends Mock
    implements FocusSessionRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final goal = GoalModel(
    id: 'g1',
    title: 'Deep Work',
    description: 'Ship the side project',
    targetMinutes: 30,
    reminderTimeHour: 9,
    reminderTimeMinute: 0,
    motivationalQuote: 'Show up.',
    colorHex: '#8B7CFF',
    createdAt: today.subtract(const Duration(days: 20)),
  );

  late MockGoalRepository goalRepo;
  late MockCalendarRepository calendarRepo;
  late MockFocusSessionRepository sessionRepo;
  late MockSettingsRepository settingsRepo;

  setUpAll(() {
    registerFallbackValue(goal);
    registerFallbackValue(
      FocusSessionModel(
        id: 'x',
        goalId: 'g1',
        durationMinutes: 0,
        timestamp: DateTime(2026),
        completedTargetMet: false,
      ),
    );
  });

  setUp(() {
    goalRepo = MockGoalRepository();
    calendarRepo = MockCalendarRepository();
    sessionRepo = MockFocusSessionRepository();
    settingsRepo = MockSettingsRepository();

    when(
      () => goalRepo.getGoals(),
    ).thenAnswer((_) async => Result.success([goal]));
    when(() => calendarRepo.getCalendarEntries('g1')).thenAnswer(
      (_) async => Result.success([
        CalendarDayModel(
          date: today.subtract(const Duration(days: 1)),
          totalMinutesFocused: 30,
          targetMinutes: 30,
          isCompleted: true,
        ),
        CalendarDayModel(
          date: today,
          totalMinutesFocused: 12,
          targetMinutes: 30,
          isCompleted: false,
        ),
      ]),
    );
    when(
      () => settingsRepo.getSettings(),
    ).thenAnswer((_) async => const Result.success(AppSettings.defaults));
    when(
      () => sessionRepo.saveSession(any()),
    ).thenAnswer((_) async => const Result.success(true));
  });

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<GoalRepository>.value(value: goalRepo),
          RepositoryProvider<CalendarRepository>.value(value: calendarRepo),
          RepositoryProvider<FocusSessionRepository>.value(value: sessionRepo),
          RepositoryProvider<SettingsRepository>.value(value: settingsRepo),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => GoalBloc(
                goalRepository: goalRepo,
                calendarRepository: calendarRepo,
              )..add(const LoadGoalsEvent()),
            ),
            BlocProvider(
              create: (_) => FocusTimerBloc(sessionRepository: sessionRepo),
            ),
            BlocProvider(
              create: (_) => CalendarBloc(calendarRepository: calendarRepo),
            ),
            BlocProvider(
              create: (_) =>
                  SettingsBloc(repository: settingsRepo)
                    ..add(const LoadSettingsEvent()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const MainNavigationShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(390, 844), Size(1280, 800)]) {
    testWidgets('core flows render without layout errors at $size', (
      tester,
    ) async {
      await pumpApp(tester, size);

      // Today
      expect(find.text('Deep Work'), findsWidgets);
      expect(find.text('0 of 1 done'), findsOneWidget);

      // Goal detail
      await tester.tap(find.text('Deep Work').first);
      await tester.pumpAndSettle();
      expect(find.text('Ship the side project'), findsOneWidget);
      expect(find.text('Target met'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Focus setup defaults to what's left for today (30 - 12 = 18)
      await tester.tap(find.byTooltip('Start focus').first);
      await tester.pumpAndSettle();
      expect(find.text('Start focusing'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);

      // Start → active session UI
      await tester.tap(find.text('Start focusing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('In session'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      // Minimize → live session bar shows on the shell
      await tester.tap(find.text('Minimize'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('left'), findsWidgets);

      // Insights & Settings tabs
      await tester.tap(find.text('Insights'));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Weekly Focus Distribution'), findsOneWidget);
      await tester.tap(find.text('Settings').last);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Session setup'), findsOneWidget);

      // Stop the running ticker so the test ends cleanly.
      tester
          .element(find.byType(MainNavigationShell))
          .read<FocusTimerBloc>()
          .add(const PauseFocusTimerEvent());
      await tester.pump(const Duration(milliseconds: 700));
    });
  }

  testWidgets(
    'completed session is logged and celebrated even after minimizing',
    (tester) async {
      when(
        () => calendarRepo.addFocusMinutesToToday(
          goalId: 'g1',
          targetMinutes: 30,
          minutesToAdd: 10,
        ),
      ).thenAnswer(
        (_) async => Result.success(
          CalendarDayModel(
            date: today,
            totalMinutesFocused: 22,
            targetMinutes: 30,
            isCompleted: false,
          ),
        ),
      );

      await pumpApp(tester, const Size(390, 844));
      final timerBloc = tester
          .element(find.byType(MainNavigationShell))
          .read<FocusTimerBloc>();

      timerBloc.add(
        const StartFocusTimerEvent(goalId: 'g1', targetMinutes: 18),
      );
      await tester.pump();
      timerBloc.add(const PauseFocusTimerEvent());
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('Paused ·'), findsOneWidget);

      timerBloc.add(const CompleteFocusTimerEvent(elapsedSeconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Session logged'), findsOneWidget);
      expect(find.text('22/30 min'), findsOneWidget);
      verify(
        () => calendarRepo.addFocusMinutesToToday(
          goalId: 'g1',
          targetMinutes: 30,
          minutesToAdd: 10,
        ),
      ).called(1);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Session logged'), findsNothing);
      expect(find.text('22 / 30 min'), findsOneWidget);
    },
  );

  testWidgets(
    'goal detail fits a default 800×600 Mac window without scrolling',
    (tester) async {
      await pumpApp(tester, const Size(800, 600));
      await tester.tap(find.text('Deep Work').first);
      await tester.pumpAndSettle();

      final lastDay = DateTime(today.year, today.month + 1, 0).day;
      final lastCell = find.descendant(
        of: find.byType(CalendarGridWidget),
        matching: find.text('$lastDay'),
      );
      expect(lastCell, findsOneWidget);
      expect(tester.getRect(lastCell).bottom, lessThanOrEqualTo(600));
      expect(
        tester.getRect(find.text('Start focus')).bottom,
        lessThanOrEqualTo(600),
      );
      expect(find.byType(ListView), findsNothing);
    },
  );

  testWidgets(
    'editor suggests titles, tailored descriptions and accepts hours',
    (tester) async {
      when(
        () => goalRepo.saveGoal(any()),
      ).thenAnswer((_) async => const Result.success(true));
      await pumpApp(tester, const Size(1280, 800));

      await tester.tap(find.text('New goal'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Rea',
      );
      await tester.pump();
      await tester.tap(find.text('Reading'));
      await tester.pumpAndSettle();
      expect(find.text('20m every day'), findsOneWidget);

      await tester.tap(find.text('Read at least 10 pages'));
      await tester.pumpAndSettle();
      expect(find.text('Read at least 10 pages'), findsOneWidget);

      await tester.tap(find.text('Hours'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount'),
        '1.5',
      );
      await tester.pump();
      expect(find.text('1h 30m every day'), findsOneWidget);

      await tester.tap(find.text('Create goal'));
      await tester.pumpAndSettle();
      final saved =
          verify(() => goalRepo.saveGoal(captureAny())).captured.single
              as GoalModel;
      expect(saved.title, 'Reading');
      expect(saved.description, 'Read at least 10 pages');
      expect(saved.targetMinutes, 90);
    },
  );
}
