import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/analytics/domain/insights_calculator.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/models/calendar_day_model.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';

void main() {
  // Thursday
  final now = DateTime(2026, 9, 24, 12);
  DateTime ago(int days) => DateTime(now.year, now.month, now.day - days);

  GoalModel goal(String id, int target, {int createdDaysAgo = 10}) => GoalModel(
    id: id,
    title: id,
    description: '',
    targetMinutes: target,
    reminderTimeHour: 9,
    reminderTimeMinute: 0,
    motivationalQuote: '',
    colorHex: '#8B7CFF',
    createdAt: ago(createdDaysAgo),
  );

  CalendarDayModel entry(int daysAgo, int minutes, int target) =>
      CalendarDayModel(
        date: ago(daysAgo),
        totalMinutesFocused: minutes,
        targetMinutes: target,
        isCompleted: minutes >= target,
      );

  test('aggregates totals, streaks, weekly minutes and perfect days', () {
    final a = goal('a', 30);
    final b = goal('b', 20);
    final data = InsightsData.compute(
      goals: [a, b],
      entriesByGoalId: {
        'a': [entry(0, 30, 30), entry(1, 30, 30), entry(2, 10, 30)],
        'b': [entry(0, 20, 20), entry(1, 5, 20)],
      },
      now: now,
    );

    expect(data.totalMinutes, 95);
    expect(data.completedDays, 3);
    expect(data.activeStreak, 2);
    expect(data.longestStreak, 2);
    // Only today had both goals completed.
    expect(data.perfectDays, 1);
    // Tue (2 days ago) .. Thu (today)
    expect(data.weekdayMinutes[4], 50);
    expect(data.weekdayMinutes[3], 35);
    expect(data.weekdayMinutes[2], 10);
    expect(data.weekMinutes, 95);
    expect(data.goals.firstWhere((g) => g.goal.id == 'a').weekMinutes, 70);
  });

  test('empty history yields zeros without errors', () {
    final data = InsightsData.compute(
      goals: [goal('a', 30)],
      entriesByGoalId: const {},
      now: now,
    );
    expect(data.totalMinutes, 0);
    expect(data.consistency, 0);
    expect(data.activeStreak, 0);
  });

  test('days before a goal was created are not counted against it', () {
    final data = InsightsData.compute(
      goals: [goal('a', 30, createdDaysAgo: 1)],
      entriesByGoalId: {
        'a': [entry(1, 30, 30)],
      },
      now: now,
    );
    expect(data.consistency, 1.0);
  });
}
