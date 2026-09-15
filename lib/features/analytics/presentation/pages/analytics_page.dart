import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../../calendar_heatmap/data/repositories/calendar_repository.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_state.dart';
import '../widgets/weekly_focus_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isLoading = true;
  int _totalAllTimeMinutes = 0;
  int _totalCompletedDays = 0;
  int _bestStreak = 0;
  int _consistencyScore = 0; // percentage
  Map<int, int> _weekdayMinutes = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
  Map<String, int> _weeklyMinutesByGoal = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final goalState = context.read<GoalBloc>().state;
    final calendarRepo = context.read<CalendarRepository>();

    List<GoalModel> goals = [];
    if (goalState is GoalLoadedState) {
      goals = goalState.goals;
    }

    if (goals.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    int allTimeMins = 0;
    int completedDaysCount = 0;
    int maxStreakFound = 0;
    final weekdayMap = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final goalMinsMap = <String, int>{};

    final now = DateTime.now();
    // Start of this week (Monday)
    final mondayOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
      mondayOfThisWeek.year,
      mondayOfThisWeek.month,
      mondayOfThisWeek.day,
    );
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Past 30 days for consistency score
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    int past30DaysTotal = 0;
    int past30DaysMet = 0;

    for (final goal in goals) {
      final entriesResult = await calendarRepo.getCalendarEntries(goal.id);
      entriesResult.fold(
        onSuccess: (entries) {
          int goalThisWeekMins = 0;

          // Streak calculation for this goal
          final sorted = List<CalendarDayModel>.from(entries)
            ..sort((a, b) => b.date.compareTo(a.date));
          int streak = 0;
          for (final entry in sorted) {
            if (entry.isCompleted) {
              streak++;
            } else {
              final isToday =
                  entry.date.year == now.year &&
                  entry.date.month == now.month &&
                  entry.date.day == now.day;
              if (!isToday) break;
            }
          }
          if (streak > maxStreakFound) maxStreakFound = streak;

          for (final entry in entries) {
            allTimeMins += entry.totalMinutesFocused;
            if (entry.isCompleted) completedDaysCount++;

            // Weekly distribution
            if (!entry.date.isBefore(weekStart) &&
                entry.date.isBefore(weekEnd)) {
              final wd = entry.date.weekday;
              weekdayMap[wd] =
                  (weekdayMap[wd] ?? 0) + entry.totalMinutesFocused;
              goalThisWeekMins += entry.totalMinutesFocused;
            }

            // 30 day consistency check
            if (!entry.date.isBefore(thirtyDaysAgo) &&
                !entry.date.isAfter(now)) {
              past30DaysTotal++;
              if (entry.isCompleted) past30DaysMet++;
            }
          }

          goalMinsMap[goal.id] = goalThisWeekMins;
        },
        onFailure: (_) {},
      );
    }

    final score = past30DaysTotal > 0
        ? ((past30DaysMet / past30DaysTotal) * 100).round()
        : (completedDaysCount > 0 ? 100 : 0);

    if (mounted) {
      setState(() {
        _totalAllTimeMinutes = allTimeMins;
        _totalCompletedDays = completedDaysCount;
        _bestStreak = maxStreakFound;
        _consistencyScore = score;
        _weekdayMinutes = weekdayMap;
        _weeklyMinutesByGoal = goalMinsMap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Consistency Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth < 600 ? 460 : 700;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accentCyan,
                          ),
                        )
                      : BlocBuilder<GoalBloc, GoalState>(
                          builder: (context, goalState) {
                            final goals = goalState is GoalLoadedState
                                ? goalState.goals
                                : <GoalModel>[];

                            if (goals.isEmpty) {
                              return Center(
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  margin: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppTheme.borderOutline,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_graph_rounded,
                                        size: 48,
                                        color: AppTheme.accentCyan,
                                      ),
                                      SizedBox(height: 14),
                                      Text(
                                        'No Analytics Yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Create target goals and complete focus sessions to see your progress insights here.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final hours = _totalAllTimeMinutes ~/ 60;
                            final mins = _totalAllTimeMinutes % 60;
                            final totalHoursStr = hours > 0
                                ? '${hours}h ${mins}m'
                                : '${mins}m';

                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Metric Summary Cards
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Total Focus',
                                          value: totalHoursStr,
                                          subtitle: 'All-time verified',
                                          icon: Icons.schedule_rounded,
                                          color: AppTheme.accentCyan,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Best Streak',
                                          value: '$_bestStreak days',
                                          subtitle: 'Consecutive targets',
                                          icon: Icons.whatshot_rounded,
                                          color: AppTheme.warningOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Targets Met',
                                          value: '$_totalCompletedDays',
                                          subtitle: 'Days completed',
                                          icon: Icons.task_alt_rounded,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Consistency',
                                          value: '$_consistencyScore%',
                                          subtitle: 'Last 30 days',
                                          icon: Icons.donut_large_rounded,
                                          color: AppTheme.accentIndigo,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Weekly Chart
                                  WeeklyFocusChart(
                                    weekdayMinutes: _weekdayMinutes,
                                  ),
                                  const SizedBox(height: 20),

                                  // Goal Breakdown Header
                                  const Text(
                                    'This Week by Goal',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  ...goals.map((g) {
                                    final thisWeekMins =
                                        _weeklyMinutesByGoal[g.id] ?? 0;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceCard,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppTheme.borderOutline,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              g.title,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${thisWeekMins}m this week',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.accentCyan,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOutline, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textMuted,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
