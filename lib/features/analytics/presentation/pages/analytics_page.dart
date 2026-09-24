import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_event.dart';
import '../../../goals/presentation/bloc/goal_state.dart';
import '../../domain/insights_calculator.dart';
import '../widgets/weekly_focus_chart.dart';

/// Derives everything from [GoalBloc], so it is always in sync with sessions.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key, this.onOpenGoal});

  final ValueChanged<GoalModel>? onOpenGoal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<GoalBloc, GoalState>(
        buildWhen: (prev, curr) =>
            !(curr is GoalLoadingState && prev is GoalLoadedState),
        builder: (context, state) {
          if (state is GoalLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          final loaded = state is GoalLoadedState
              ? state
              : const GoalLoadedState([]);
          return _InsightsView(
            goals: loaded.goals,
            data: InsightsData.compute(
              goals: loaded.goals,
              entriesByGoalId: loaded.entriesByGoalId,
            ),
            onOpenGoal: onOpenGoal,
          );
        },
      ),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView({
    required this.goals,
    required this.data,
    required this.onOpenGoal,
  });

  final List<GoalModel> goals;
  final InsightsData data;
  final ValueChanged<GoalModel>? onOpenGoal;

  String _days(int n) => '$n ${n == 1 ? 'day' : 'days'}';

  @override
  Widget build(BuildContext context) {
    final dailyTarget = goals.fold<int>(0, (s, g) => s + g.targetMinutes);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = math.max(20.0, (constraints.maxWidth - 960) / 2);
        final bottom = MediaQuery.paddingOf(context).bottom + 24;
        final twoColumn = constraints.maxWidth >= 900;

        final weekly = WeeklyFocusChart(
          weekdayMinutes: data.weekdayMinutes,
          dailyTarget: dailyTarget,
        );
        final heatmap = ActivityHeatmap(dailyRatio: data.dailyRatio);

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceRaised,
          onRefresh: () async {
            final bloc = context.read<GoalBloc>()..add(const LoadGoalsEvent());
            await bloc.stream.firstWhere(
              (s) => s is GoalLoadedState || s is GoalErrorState,
            );
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 20),
                  sliver: const SliverToBoxAdapter(
                    child: PageHeader(
                      title: 'Insights',
                      subtitle: 'Your consistency across all goals',
                    ),
                  ),
                ),
              ),
              if (goals.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, bottom),
                    child: const Center(
                      child: EmptyState(
                        icon: Icons.bar_chart_rounded,
                        title: 'No insights yet',
                        message:
                            'Create a goal and finish a focus session. Streaks, trends and your completion rate will show up here.',
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, bottom),
                  sliver: SliverList.list(
                    children: [
                      StatRow(
                        stats: [
                          StatBlock(
                            value: '${(data.consistency * 100).round()}%',
                            label: 'Completion · 30 days',
                          ),
                          StatBlock(
                            value: _days(data.activeStreak),
                            label: 'Current streak',
                          ),
                          StatBlock(
                            value: _days(data.longestStreak),
                            label: 'Longest streak',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StatRow(
                        stats: [
                          StatBlock(
                            value: formatMinutes(data.totalMinutes),
                            label: 'Total focus',
                          ),
                          StatBlock(
                            value: formatMinutes(data.dailyAverage),
                            label: 'Daily average · 7 days',
                          ),
                          StatBlock(
                            value: '${data.perfectDays}',
                            label: 'Perfect days · 30 days',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (twoColumn)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: weekly),
                            const SizedBox(width: 16),
                            Expanded(child: heatmap),
                          ],
                        )
                      else ...[
                        weekly,
                        const SizedBox(height: 16),
                        heatmap,
                      ],
                      const SizedBox(height: 24),
                      const SectionLabel('This week by goal'),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < data.goals.length; i++) ...[
                              if (i > 0) const Divider(),
                              _GoalWeekRow(
                                insight: data.goals[i],
                                onTap: onOpenGoal == null
                                    ? null
                                    : () => onOpenGoal!(data.goals[i].goal),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GoalWeekRow extends StatelessWidget {
  const _GoalWeekRow({required this.insight, this.onTap});

  final GoalInsight insight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final accent = colorFromHex(insight.goal.colorHex);
    final ratio = insight.weeklyTarget == 0
        ? 0.0
        : insight.weekMinutes / insight.weeklyTarget;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight.goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall,
                  ),
                ),
                Text(
                  '${formatMinutes(insight.weekMinutes)} of ${formatMinutes(insight.weeklyTarget)}',
                  style: theme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ProgressBar(value: ratio, color: accent),
            const SizedBox(height: 8),
            Text(
              'Current streak ${insight.currentStreak} · best ${insight.longestStreak} · ${insight.completedDays} days completed',
              style: theme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
