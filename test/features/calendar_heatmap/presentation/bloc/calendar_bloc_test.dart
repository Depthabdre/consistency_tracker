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

  setUp(() {
    mockRepository = MockCalendarRepository();
    bloc = CalendarBloc(calendarRepository: mockRepository);
  });

  final testDay = CalendarDayModel(
    date: DateTime.now(),
    totalMinutesFocused: 30,
    targetMinutes: 30,
    isCompleted: true,
  );

  test('LoadCalendarEntriesEvent emits CalendarLoadedState with correct streak', () async {
    when(() => mockRepository.getCalendarEntries('g1'))
        .thenAnswer((_) async => Result.success([testDay]));

    bloc.add(const LoadCalendarEntriesEvent('g1'));

    expect(
      bloc.stream,
      emitsInOrder([
        const CalendarLoadingState(),
        CalendarLoadedState(entries: [testDay], currentStreak: 1),
      ]),
    );
  });
}
