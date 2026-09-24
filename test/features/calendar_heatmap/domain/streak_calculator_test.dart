import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/models/calendar_day_model.dart';
import 'package:consistency_tracker/features/calendar_heatmap/domain/streak_calculator.dart';

CalendarDayModel _day(DateTime d, {bool done = true, int minutes = 30}) =>
    CalendarDayModel(
      date: DateTime(d.year, d.month, d.day),
      totalMinutesFocused: minutes,
      targetMinutes: 30,
      isCompleted: done,
    );

void main() {
  final now = DateTime(2026, 9, 24, 15);
  DateTime ago(int days) => DateTime(now.year, now.month, now.day - days);

  group('calculateCurrentStreak', () {
    test('counts consecutive completed days ending today', () {
      final entries = [_day(ago(0)), _day(ago(1)), _day(ago(2))];
      expect(calculateCurrentStreak(entries, now: now), 3);
    });

    test('today still in progress does not break the streak', () {
      final entries = [
        _day(ago(0), done: false, minutes: 5),
        _day(ago(1)),
        _day(ago(2)),
      ];
      expect(calculateCurrentStreak(entries, now: now), 2);
    });

    test('a day with no entry breaks the streak (gap)', () {
      final entries = [_day(ago(0)), _day(ago(1)), _day(ago(3)), _day(ago(4))];
      expect(calculateCurrentStreak(entries, now: now), 2);
    });

    test('streak is 0 when yesterday and today were both missed', () {
      final entries = [_day(ago(2)), _day(ago(3))];
      expect(calculateCurrentStreak(entries, now: now), 0);
    });

    test('empty history returns 0', () {
      expect(calculateCurrentStreak(const [], now: now), 0);
    });
  });

  group('calculateLongestStreak', () {
    test('finds the longest run across gaps', () {
      final entries = [
        _day(ago(0)),
        _day(ago(5)),
        _day(ago(6)),
        _day(ago(7)),
        _day(ago(9)),
      ];
      expect(calculateLongestStreak(entries), 3);
    });

    test('ignores incomplete days', () {
      final entries = [_day(ago(1), done: false), _day(ago(2))];
      expect(calculateLongestStreak(entries), 1);
    });
  });

  group('calculateConsistency', () {
    test('counts missing days since start as missed, excludes open today', () {
      final entries = [_day(ago(1)), _day(ago(3))];
      final result = calculateConsistency(entries, startDate: ago(4), now: now);
      // Eligible: days 1..4 ago (today excluded because not completed).
      expect(result.eligible, 4);
      expect(result.met, 2);
    });

    test('includes today once completed', () {
      final result = calculateConsistency(
        [_day(ago(0))],
        startDate: ago(0),
        now: now,
      );
      expect(result.eligible, 1);
      expect(result.met, 1);
    });
  });
}
