import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/utils/result.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/models/calendar_day_model.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/repositories/calendar_repository.dart';
import 'package:consistency_tracker/features/calendar_heatmap/presentation/bloc/calendar_bloc.dart';
import 'package:consistency_tracker/features/calendar_heatmap/presentation/bloc/calendar_event.dart';
import 'package:consistency_tracker/features/calendar_heatmap/presentation/bloc/calendar_state.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

void main() {
  late CalendarBloc bloc;
  late MockCalendarRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      CalendarDayModel(
        date: DateTime.now(),
        totalMinutesFocused: 30,
        targetMinutes: 30,
        isCompleted: true,
      ),
    );
  });

  setUp(() {
    mockRepository = MockCalendarRepository();
    bloc = CalendarBloc(calendarRepository: mockRepository);
  });

  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));

  final testDayCompleted = CalendarDayModel(
    date: today,
    totalMinutesFocused: 30,
    targetMinutes: 30,
    isCompleted: true,
  );

  final yesterdayCompleted = CalendarDayModel(
    date: yesterday,
    totalMinutesFocused: 30,
    targetMinutes: 30,
    isCompleted: true,
  );

  final yesterdayMissed = CalendarDayModel(
    date: yesterday,
    totalMinutesFocused: 15,
    targetMinutes: 30,
    isCompleted: false,
  );

  group('CalendarBloc - Goal Start Date Heatmap Rules', () {
    test(
      'Positive: LoadCalendarEntriesEvent calculates correct streak for consecutive target completed days',
      () async {
        when(() => mockRepository.getCalendarEntries('g1')).thenAnswer(
          (_) async => Result.success([testDayCompleted, yesterdayCompleted]),
        );

        bloc.add(const LoadCalendarEntriesEvent('g1'));

        expect(
          bloc.stream,
          emitsInOrder([
            const CalendarLoadingState(),
            CalendarLoadedState(
              entries: [testDayCompleted, yesterdayCompleted],
              currentStreak: 2,
            ),
          ]),
        );
      },
    );

    test(
      'Negative/Missed: streak breaks when a past day after goal start date is missed',
      () async {
        when(() => mockRepository.getCalendarEntries('g1')).thenAnswer(
          (_) async => Result.success([testDayCompleted, yesterdayMissed]),
        );

        bloc.add(const LoadCalendarEntriesEvent('g1'));

        expect(
          bloc.stream,
          emitsInOrder([
            const CalendarLoadingState(),
            CalendarLoadedState(
              entries: [testDayCompleted, yesterdayMissed],
              currentStreak: 1,
            ),
          ]),
        );
      },
    );

    test('Edge Case: empty entries list returns 0 streak', () async {
      when(
        () => mockRepository.getCalendarEntries('g1'),
      ).thenAnswer((_) async => const Result.success([]));

      bloc.add(const LoadCalendarEntriesEvent('g1'));

      expect(
        bloc.stream,
        emitsInOrder([
          const CalendarLoadingState(),
          const CalendarLoadedState(entries: [], currentStreak: 0),
        ]),
      );
    });
  });
}
