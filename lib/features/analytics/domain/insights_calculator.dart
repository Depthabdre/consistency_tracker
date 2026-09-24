import '../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../calendar_heatmap/domain/streak_calculator.dart';
import '../../goals/data/models/goal_model.dart';

class GoalInsight {
  const GoalInsight({
    required this.goal,
    required this.currentStreak,
    required this.longestStreak,
    required this.weekMinutes,
    required this.totalMinutes,
    required this.completedDays,
  });

  final GoalModel goal;
  final int currentStreak;
  final int longestStreak;
  final int weekMinutes;
  final int totalMinutes;
  final int completedDays;

  int get weeklyTarget => goal.targetMinutes * goal.activeWeekdays.length;
}

/// Aggregated, UI-ready analytics derived purely from goal history.
class InsightsData {
  const InsightsData({
    required this.totalMinutes,
    required this.completedDays,
    required this.longestStreak,
    required this.activeStreak,
    required this.consistency,
    required this.perfectDays,
    required this.weekdayMinutes,
    required this.weekMinutes,
    required this.dailyAverage,
    required this.dailyRatio,
    required this.goals,
  });

  final int totalMinutes;
  final int completedDays;
  final int longestStreak;
  final int activeStreak;

  /// 0..1 over the last 30 days.
  final double consistency;

  /// Days in the last 30 where every active goal hit its target.
  final int perfectDays;

  /// 1 = Monday … 7 = Sunday, current week.
  final Map<int, int> weekdayMinutes;
  final int weekMinutes;

  /// Average focus minutes per day over the last 7 days.
  final int dailyAverage;

  /// Focused minutes ÷ combined target, per day (heatmap intensity).
  final Map<DateTime, double> dailyRatio;

  final List<GoalInsight> goals;

  static InsightsData compute({
    required List<GoalModel> goals,
    required Map<String, List<CalendarDayModel>> entriesByGoalId,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = dayOnly(current);
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final sevenDaysAgo = DateTime(today.year, today.month, today.day - 6);

    var totalMinutes = 0;
    var completedDays = 0;
    var longest = 0;
    var active = 0;
    var met = 0;
    var eligible = 0;
    var last7Minutes = 0;
    final weekday = {for (var d = 1; d <= 7; d++) d: 0};
    final dailyMinutes = <DateTime, int>{};
    final dailyCompleted = <DateTime, int>{};
    final perGoal = <GoalInsight>[];

    for (final goal in goals) {
      final entries = entriesByGoalId[goal.id] ?? const <CalendarDayModel>[];
      var goalWeek = 0;
      var goalTotal = 0;
      var goalDone = 0;

      for (final e in entries) {
        final day = dayOnly(e.date);
        goalTotal += e.totalMinutesFocused;
        if (e.isCompleted) {
          goalDone++;
          dailyCompleted[day] = (dailyCompleted[day] ?? 0) + 1;
        }
        dailyMinutes[day] = (dailyMinutes[day] ?? 0) + e.totalMinutesFocused;
        if (!day.isBefore(weekStart) && !day.isAfter(today)) {
          weekday[day.weekday] = weekday[day.weekday]! + e.totalMinutesFocused;
          goalWeek += e.totalMinutesFocused;
        }
        if (!day.isBefore(sevenDaysAgo) && !day.isAfter(today)) {
          last7Minutes += e.totalMinutesFocused;
        }
      }

      final c = calculateCurrentStreak(
        entries,
        now: current,
        activeWeekdays: goal.activeWeekdays,
      );
      final l = calculateLongestStreak(
        entries,
        activeWeekdays: goal.activeWeekdays,
      );
      final consistency = calculateConsistency(
        entries,
        startDate: goal.createdAt,
        now: current,
        activeWeekdays: goal.activeWeekdays,
      );
      met += consistency.met;
      eligible += consistency.eligible;
      if (c > active) active = c;
      if (l > longest) longest = l;
      totalMinutes += goalTotal;
      completedDays += goalDone;

      perGoal.add(
        GoalInsight(
          goal: goal,
          currentStreak: c,
          longestStreak: l,
          weekMinutes: goalWeek,
          totalMinutes: goalTotal,
          completedDays: goalDone,
        ),
      );
    }

    // Heatmap ratio + perfect days use the goals scheduled on each day.
    final dailyRatio = <DateTime, double>{};
    var perfect = 0;
    for (var i = 0; i < 7 * 18; i++) {
      final day = DateTime(today.year, today.month, today.day - i);
      final activeGoals = goals.where((g) => g.isScheduledOn(day)).toList();
      if (activeGoals.isEmpty) continue;
      final target = activeGoals.fold<int>(0, (s, g) => s + g.targetMinutes);
      final minutes = dailyMinutes[day] ?? 0;
      dailyRatio[day] = target == 0 ? 0 : minutes / target;
      if (i < 30 && (dailyCompleted[day] ?? 0) >= activeGoals.length) {
        perfect++;
      }
    }

    return InsightsData(
      totalMinutes: totalMinutes,
      completedDays: completedDays,
      longestStreak: longest,
      activeStreak: active,
      consistency: eligible == 0 ? 0 : met / eligible,
      perfectDays: perfect,
      weekdayMinutes: weekday,
      weekMinutes: weekday.values.fold(0, (a, b) => a + b),
      dailyAverage: (last7Minutes / 7).round(),
      dailyRatio: dailyRatio,
      goals: perGoal,
    );
  }
}
