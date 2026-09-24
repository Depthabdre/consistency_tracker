import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/services/secret_store.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/models/calendar_day_model.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/repositories/calendar_repository.dart';
import 'package:consistency_tracker/features/calendar_heatmap/domain/streak_calculator.dart';
import 'package:consistency_tracker/features/focus_timer/data/datasources/active_session_store.dart';
import 'package:consistency_tracker/features/focus_timer/data/models/focus_session_model.dart';
import 'package:consistency_tracker/features/focus_timer/data/repositories/focus_session_repository.dart';
import 'package:consistency_tracker/features/focus_timer/domain/entities/session_phase.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_bloc.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_event.dart';
import 'package:consistency_tracker/features/focus_timer/presentation/bloc/focus_timer_state.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/repositories/goal_repository.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_event.dart';
import 'package:consistency_tracker/features/goals/presentation/bloc/goal_state.dart';
import 'package:consistency_tracker/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:consistency_tracker/features/notifications/data/repositories/notification_repository.dart';
import 'package:consistency_tracker/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:consistency_tracker/features/settings/data/services/backup_service.dart';
import 'package:consistency_tracker/features/settings/domain/entities/app_settings.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

class MockCalendarRepository extends Mock implements CalendarRepository {}

class MockSessionRepository extends Mock implements FocusSessionRepository {}

class MockNotificationDataSource extends Mock
    implements NotificationLocalDataSource {}

class MemoryActiveSessionStore implements ActiveSessionStore {
  ActiveSessionSnapshot? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<ActiveSessionSnapshot?> load() async => value;

  @override
  Future<void> save(ActiveSessionSnapshot snapshot) async => value = snapshot;
}

CalendarDayModel _day(DateTime d, {bool done = true}) => CalendarDayModel(
  date: DateTime(d.year, d.month, d.day),
  totalMinutesFocused: done ? 30 : 5,
  targetMinutes: 30,
  isCompleted: done,
);

GoalModel _goal({List<int> weekdays = GoalModel.everyDay}) => GoalModel(
  id: 'g1',
  title: 'Reading',
  description: 'Read 10 pages',
  targetMinutes: 30,
  reminderTimeHour: 9,
  reminderTimeMinute: 0,
  motivationalQuote: '',
  colorHex: '#5B8CFF',
  createdAt: DateTime(2026, 9, 1),
  activeWeekdays: weekdays,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_goal());
    registerFallbackValue(_day(DateTime(2026, 9, 1)));
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

  group('Rest days', () {
    // Thursday 24 Sep 2026; goal runs Mon–Fri.
    final now = DateTime(2026, 9, 24, 12);
    const weekdays = [1, 2, 3, 4, 5];

    test('weekend gap does not break the streak', () {
      final entries = [
        _day(DateTime(2026, 9, 24)), // Thu
        _day(DateTime(2026, 9, 23)), // Wed
        _day(DateTime(2026, 9, 22)), // Tue
        _day(DateTime(2026, 9, 21)), // Mon
        _day(DateTime(2026, 9, 18)), // Fri (Sat/Sun rest)
      ];
      expect(
        calculateCurrentStreak(entries, now: now, activeWeekdays: weekdays),
        5,
      );
      expect(calculateCurrentStreak(entries, now: now), 4);
      expect(calculateLongestStreak(entries, activeWeekdays: weekdays), 5);
    });

    test('missing a scheduled day still breaks the streak', () {
      final entries = [
        _day(DateTime(2026, 9, 24)),
        _day(DateTime(2026, 9, 22)), // Wed missed
      ];
      expect(
        calculateCurrentStreak(entries, now: now, activeWeekdays: weekdays),
        1,
      );
    });

    test('rest days are excluded from the completion rate', () {
      final result = calculateConsistency(
        [_day(DateTime(2026, 9, 21)), _day(DateTime(2026, 9, 22))],
        startDate: DateTime(2026, 9, 19), // Sat
        now: now,
        activeWeekdays: weekdays,
      );
      // Eligible: Mon, Tue, Wed (today Thu not yet done; Sat/Sun rest).
      expect(result.eligible, 3);
      expect(result.met, 2);
    });

    test('GoalModel stores and sanitises weekdays', () {
      final goal = _goal(weekdays: [1, 3, 5]);
      final restored = GoalModel.fromJson(goal.toJson());
      expect(restored.activeWeekdays, [1, 3, 5]);
      expect(restored.scheduleLabel, 'Mon, Wed, Fri');
      expect(
        GoalModel.fromJson({
          ...goal.toJson(),
          'activeWeekdays': [9, 0],
        }).activeWeekdays,
        GoalModel.everyDay,
      );
      expect(GoalModel.fromJson({'id': 'old'}).hasRestDays, isFalse);
    });

    test(
      'reminders for a Mon/Wed/Fri goal repeat weekly on those days',
      () async {
        final ds = MockNotificationDataSource();
        when(
          () => ds.scheduleGoalNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
            startTomorrow: any(named: 'startTomorrow'),
            weekday: any(named: 'weekday'),
          ),
        ).thenAnswer((_) async {});
        final repo = NotificationRepositoryImpl(localDataSource: ds);

        await repo.scheduleGoalReminders(
          _goal(weekdays: [1, 3, 5]),
          includeEscalation: false,
        );

        final weekdaysScheduled = verify(
          () => ds.scheduleGoalNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: 9,
            minute: 0,
            startTomorrow: false,
            weekday: captureAny(named: 'weekday'),
          ),
        ).captured;
        expect(weekdaysScheduled, [1, 3, 5]);
      },
    );
  });

  group('Session survives app restarts', () {
    const phases = [
      SessionPhase(
        type: SessionPhaseType.focus,
        durationSeconds: 600,
        labelMinutes: 10,
      ),
      SessionPhase(
        type: SessionPhaseType.breakTime,
        durationSeconds: 300,
        labelMinutes: 5,
      ),
      SessionPhase(
        type: SessionPhaseType.focus,
        durationSeconds: 600,
        labelMinutes: 10,
      ),
    ];
    final start = DateTime(2026, 9, 24, 10);

    late MockSessionRepository sessions;
    late MemoryActiveSessionStore store;

    setUp(() {
      sessions = MockSessionRepository();
      store = MemoryActiveSessionStore();
      when(
        () => sessions.saveSession(any()),
      ).thenAnswer((_) async => const Result.success(true));
    });

    ActiveSessionSnapshot running() => ActiveSessionSnapshot(
      goalId: 'g1',
      targetMinutes: 20,
      phases: phases,
      currentPhaseIndex: 0,
      remainingSecondsInPhase: 600,
      elapsedSeconds: 0,
      accumulatedFocusSeconds: 0,
      paused: false,
      targetEndTime: start.add(const Duration(seconds: 600)),
    );

    test('snapshot round-trips through JSON', () {
      final json = running().toJson();
      final parsed = ActiveSessionSnapshot.tryParse(json)!;
      expect(parsed.phases, phases);
      expect(parsed.targetEndTime, running().targetEndTime);
      expect(ActiveSessionSnapshot.tryParse({'goalId': 'x'}), isNull);
    });

    test('restores a paused session as paused', () async {
      store.value = ActiveSessionSnapshot(
        goalId: 'g1',
        targetMinutes: 20,
        phases: phases,
        currentPhaseIndex: 0,
        remainingSecondsInPhase: 420,
        elapsedSeconds: 180,
        accumulatedFocusSeconds: 180,
        paused: true,
      );
      final bloc = FocusTimerBloc(
        sessionRepository: sessions,
        activeSessionStore: store,
      );
      bloc.add(const RestoreFocusTimerEvent());
      await expectLater(
        bloc.stream,
        emits(
          isA<FocusTimerPausedState>().having(
            (s) => s.remainingSecondsInPhase,
            'remaining',
            420,
          ),
        ),
      );
      await bloc.close();
    });

    test('fast-forwards into the right phase after being closed', () async {
      store.value = running();
      final bloc = FocusTimerBloc(
        sessionRepository: sessions,
        activeSessionStore: store,
      );
      // 10 min focus + 5 min break done, 2 min into the second focus block.
      bloc.add(
        RestoreFocusTimerEvent(now: start.add(const Duration(minutes: 17))),
      );
      await expectLater(
        bloc.stream,
        emits(
          isA<FocusTimerRunningState>()
              .having((s) => s.currentPhaseIndex, 'phase', 2)
              .having((s) => s.remainingSecondsInPhase, 'remaining', 480),
        ),
      );
      await bloc.close();
    });

    test(
      'completes and logs focus time when the session ended while closed',
      () async {
        store.value = running();
        final bloc = FocusTimerBloc(
          sessionRepository: sessions,
          activeSessionStore: store,
        );
        bloc.add(
          RestoreFocusTimerEvent(now: start.add(const Duration(hours: 2))),
        );
        await expectLater(
          bloc.stream,
          emits(
            isA<FocusTimerCompletedState>().having(
              (s) => s.totalMinutesCompleted,
              'minutes',
              20,
            ),
          ),
        );
        expect(store.value, isNull);
        await bloc.close();
      },
    );

    test('nothing to restore leaves the timer idle', () async {
      final bloc = FocusTimerBloc(
        sessionRepository: sessions,
        activeSessionStore: store,
      );
      bloc.add(const RestoreFocusTimerEvent());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<FocusTimerInitialState>());
      await bloc.close();
    });
  });

  group('Password storage', () {
    late Directory dir;
    late Box box;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('settings_test');
      Hive.init(dir.path);
      box = await Hive.openBox('settings_test_box');
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await dir.delete(recursive: true);
    });

    test(
      'password goes to the secret store, never the settings file',
      () async {
        final secrets = InMemorySecretStore();
        final ds = SettingsLocalDataSourceImpl(
          settingsBox: box,
          secrets: secrets,
        );

        await ds.saveSettings(
          AppSettings.defaults.copyWith(smtpPassword: 'abcd efgh ijkl mnop'),
        );

        expect(
          box.get(SettingsLocalDataSourceImpl.key),
          isNot(contains('abcd')),
        );
        expect(await secrets.read('smtp_password'), 'abcd efgh ijkl mnop');
        expect((await ds.getSettings()).smtpPassword, 'abcd efgh ijkl mnop');
      },
    );

    test('migrates a plain-text password written by older builds', () async {
      await SettingsLocalDataSourceImpl(settingsBox: box).saveSettings(
        AppSettings.defaults.copyWith(smtpPassword: 'legacy-secret'),
      );
      final secrets = InMemorySecretStore();
      final ds = SettingsLocalDataSourceImpl(
        settingsBox: box,
        secrets: secrets,
      );

      expect((await ds.getSettings()).smtpPassword, 'legacy-secret');
      expect(
        box.get(SettingsLocalDataSourceImpl.key),
        isNot(contains('legacy')),
      );
      expect(await secrets.read('smtp_password'), 'legacy-secret');
    });
  });

  group('Backup', () {
    late MockGoalRepository goals;
    late MockCalendarRepository calendar;

    setUp(() {
      goals = MockGoalRepository();
      calendar = MockCalendarRepository();
    });

    test('export then parse round-trips goals and history', () async {
      final goal = _goal(weekdays: [1, 2, 3, 4, 5]);
      final history = [
        _day(DateTime(2026, 9, 21)),
        _day(DateTime(2026, 9, 22)),
      ];
      when(
        () => goals.getGoals(),
      ).thenAnswer((_) async => Result.success([goal]));
      when(
        () => calendar.getCalendarEntries('g1'),
      ).thenAnswer((_) async => Result.success(history));
      final service = BackupService(
        goalRepository: goals,
        calendarRepository: calendar,
      );

      final parsed = service.parse(await service.exportJson());

      expect(parsed.single.$1.toJson(), goal.toJson());
      expect(parsed.single.$2, history);
    });

    test('rejects files that are not backups', () {
      final service = BackupService(
        goalRepository: goals,
        calendarRepository: calendar,
      );
      expect(
        () => service.parse('not json'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => service.parse('{"goals": []}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('restore writes goals and every history day', () async {
      when(
        () => goals.saveGoal(any()),
      ).thenAnswer((_) async => const Result.success(true));
      when(
        () => calendar.saveCalendarDay(any(), any()),
      ).thenAnswer((_) async => const Result.success(true));
      final service = BackupService(
        goalRepository: goals,
        calendarRepository: calendar,
      );

      final count = await service.restore([
        (_goal(), [_day(DateTime(2026, 9, 21)), _day(DateTime(2026, 9, 22))]),
      ]);

      expect(count, 1);
      verify(() => goals.saveGoal(any())).called(1);
      verify(() => calendar.saveCalendarDay('g1', any())).called(2);
    });
  });

  test('undo restores a deleted goal with its history', () async {
    final goals = MockGoalRepository();
    final calendar = MockCalendarRepository();
    final goal = _goal();
    final history = [_day(DateTime(2026, 9, 22))];
    when(
      () => goals.saveGoal(any()),
    ).thenAnswer((_) async => const Result.success(true));
    when(
      () => goals.getGoals(),
    ).thenAnswer((_) async => Result.success([goal]));
    when(
      () => calendar.saveCalendarDay(any(), any()),
    ).thenAnswer((_) async => const Result.success(true));
    when(
      () => calendar.getCalendarEntries('g1'),
    ).thenAnswer((_) async => Result.success(history));

    final bloc = GoalBloc(goalRepository: goals, calendarRepository: calendar);
    bloc.add(RestoreGoalEvent(goal, history));

    await expectLater(
      bloc.stream,
      emitsThrough(
        isA<GoalLoadedState>().having(
          (s) => s.entriesFor('g1'),
          'history',
          history,
        ),
      ),
    );
    verify(() => calendar.saveCalendarDay('g1', history.single)).called(1);
    await bloc.close();
  });
}
