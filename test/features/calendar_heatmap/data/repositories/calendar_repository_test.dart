import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:consistency_tracker/core/errors/failures.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/datasources/calendar_local_datasource.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/models/calendar_day_model.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/repositories/calendar_repository.dart';

class MockCalendarLocalDataSource extends Mock
    implements CalendarLocalDataSource {}

void main() {
  late CalendarRepository repository;
  late MockCalendarLocalDataSource mockLocalDataSource;

  final today = DateTime.now();

  setUp(() {
    mockLocalDataSource = MockCalendarLocalDataSource();
    repository = CalendarRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('CalendarRepository - addFocusMinutesToToday QA Skill Tests', () {
    test(
      'TC-P0-01 (Defect Fix): Goal with 1 min progress + 2 min focus session stop equals 3 mins (isCompleted == false)',
      () async {
        final expectedDay = CalendarDayModel(
          date: DateTime(today.year, today.month, today.day),
          totalMinutesFocused: 3,
          targetMinutes: 25,
          isCompleted: false,
        );

        when(
          () => mockLocalDataSource.addFocusMinutesToToday(
            goalId: 'goal_1',
            targetMinutes: 25,
            minutesToAdd: 2,
          ),
        ).thenAnswer((_) async => expectedDay);

        final result = await repository.addFocusMinutesToToday(
          goalId: 'goal_1',
          targetMinutes: 25,
          minutesToAdd: 2,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.totalMinutesFocused, equals(3));
        expect(result.data!.isCompleted, isFalse);
      },
    );

    test(
      'TC-P0-02 (Target Completed): 20 mins progress + 5 mins focus session equals 25 mins (isCompleted == true)',
      () async {
        final expectedDay = CalendarDayModel(
          date: DateTime(today.year, today.month, today.day),
          totalMinutesFocused: 25,
          targetMinutes: 25,
          isCompleted: true,
        );

        when(
          () => mockLocalDataSource.addFocusMinutesToToday(
            goalId: 'goal_1',
            targetMinutes: 25,
            minutesToAdd: 5,
          ),
        ).thenAnswer((_) async => expectedDay);

        final result = await repository.addFocusMinutesToToday(
          goalId: 'goal_1',
          targetMinutes: 25,
          minutesToAdd: 5,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.totalMinutesFocused, equals(25));
        expect(result.data!.isCompleted, isTrue);
      },
    );

    test(
      'TC-P1-01 (Boundary 0s): 1 min progress + 0 min focus session equals 1 min (isCompleted == false)',
      () async {
        final expectedDay = CalendarDayModel(
          date: DateTime(today.year, today.month, today.day),
          totalMinutesFocused: 1,
          targetMinutes: 25,
          isCompleted: false,
        );

        when(
          () => mockLocalDataSource.addFocusMinutesToToday(
            goalId: 'goal_1',
            targetMinutes: 25,
            minutesToAdd: 0,
          ),
        ).thenAnswer((_) async => expectedDay);

        final result = await repository.addFocusMinutesToToday(
          goalId: 'goal_1',
          targetMinutes: 25,
          minutesToAdd: 0,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.totalMinutesFocused, equals(1));
      },
    );

    test(
      'TC-P2-01 (Negative Failure): Storage error maps to CacheFailure cleanly',
      () async {
        when(
          () => mockLocalDataSource.addFocusMinutesToToday(
            goalId: 'goal_1',
            targetMinutes: 25,
            minutesToAdd: 2,
          ),
        ).thenThrow(Exception('Hive I/O Error'));

        final result = await repository.addFocusMinutesToToday(
          goalId: 'goal_1',
          targetMinutes: 25,
          minutesToAdd: 2,
        );

        expect(result.isFailure, isTrue);
        expect(result.failure, isA<CacheFailure>());
        expect(result.failure!.message, contains('Hive I/O Error'));
      },
    );
  });
}
