import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../calendar_heatmap/domain/streak_calculator.dart';
import '../../../focus_timer/presentation/bloc/focus_timer_bloc.dart';
import '../../../focus_timer/presentation/bloc/focus_timer_state.dart';
import '../../data/models/goal_model.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import '../goal_actions.dart';
import '../reusable_widgets/goal_card_widget.dart';

enum _GoalFilter { all, todo, done }

class GoalsListPage extends StatefulWidget {
  final void Function(GoalModel goal) onStartFocus;
  final void Function(GoalModel goal) onViewCalendar;

  const GoalsListPage({
    super.key,
    required this.onStartFocus,
    required this.onViewCalendar,
  });

  @override
  State<GoalsListPage> createState() => _GoalsListPageState();
}

class _GoalsListPageState extends State<GoalsListPage> {
  _GoalFilter _filter = _GoalFilter.all;

  Future<void> _refresh() async {
    final bloc = context.read<GoalBloc>()..add(const LoadGoalsEvent());
    await bloc.stream.firstWhere(
      (s) => s is GoalLoadedState || s is GoalErrorState,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<GoalBloc, GoalState>(
        // Keep showing current data during background reloads (no flicker).
        buildWhen: (prev, curr) =>
            !(curr is GoalLoadingState && prev is GoalLoadedState),
        builder: (context, state) {
          if (state is GoalErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Couldn’t load your goals',
                  message: state.message,
                  action: OutlinedButton(
                    onPressed: () =>
                        context.read<GoalBloc>().add(const LoadGoalsEvent()),
                    child: const Text('Try again'),
                  ),
                ),
              ),
            );
          }
          if (state is GoalLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! GoalLoadedState) return const SizedBox.shrink();
          return _buildLoaded(context, state);
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, GoalLoadedState state) {
    final goals = state.goals;
    final doneGoals = goals
        .where((g) => state.todayMinutesFor(g.id) >= g.targetMinutes)
        .toList();
    final now = DateTime.now();
    final todoGoals = goals
        .where((g) => !doneGoals.contains(g) && g.isActiveOn(now))
        .toList();
    final visible = switch (_filter) {
      _GoalFilter.all => goals,
      _GoalFilter.todo => todoGoals,
      _GoalFilter.done => doneGoals,
    };
    final timerState = context.watch<FocusTimerBloc>().state;
    final liveGoalId = switch (timerState) {
      FocusTimerRunningState s => s.goalId,
      FocusTimerPausedState s => s.goalId,
      _ => null,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = math.max(20.0, (constraints.maxWidth - 720) / 2);
        final bottom = MediaQuery.paddingOf(context).bottom + 24;
        final compact = constraints.maxWidth < 480;

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceRaised,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverSafeArea(
                bottom: false,
                sliver: SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 0),
                  sliver: SliverToBoxAdapter(
                    child: PageHeader(
                      title: 'Today',
                      subtitle: DateFormat(
                        'EEEE, MMMM d',
                      ).format(DateTime.now()),
                      actions: [
                        if (compact)
                          AppIconButton(
                            icon: Icons.add_rounded,
                            tooltip: 'New goal',
                            filled: true,
                            onTap: () => openGoalEditor(context),
                          )
                        else
                          FilledButton.icon(
                            onPressed: () => openGoalEditor(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New goal'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (goals.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 24, gutter, bottom),
                    child: Center(
                      child: EmptyState(
                        icon: Icons.flag_outlined,
                        title: 'No goals yet',
                        message:
                            'Pick something you want to do every day and set a daily minimum. Every focus session counts toward it.',
                        action: SizedBox(
                          width: 220,
                          child: PrimaryButton(
                            label: 'Create a goal',
                            icon: Icons.add_rounded,
                            onPressed: () => openGoalEditor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 0),
                  sliver: SliverToBoxAdapter(
                    child: _TodaySummary(state: state),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 12),
                  sliver: SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: SegmentedPills<_GoalFilter>(
                          value: _filter,
                          onChanged: (f) => setState(() => _filter = f),
                          options: [
                            (_GoalFilter.all, 'All ${goals.length}'),
                            (_GoalFilter.todo, 'To do ${todoGoals.length}'),
                            (_GoalFilter.done, 'Done ${doneGoals.length}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, bottom),
                    sliver: SliverToBoxAdapter(
                      child: AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _filter == _GoalFilter.done
                              ? 'Nothing completed yet today.'
                              : 'All done for today.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, bottom),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final goal = visible[i];
                        return GoalCardWidget(
                          key: ValueKey(goal.id),
                          goal: goal,
                          todayFocusedMinutes: state.todayMinutesFor(goal.id),
                          entries: state.entriesFor(goal.id),
                          isLive: liveGoalId == goal.id,
                          onStartFocus: () => widget.onStartFocus(goal),
                          onOpen: () => widget.onViewCalendar(goal),
                          onMore: (anchor) => showGoalActions(
                            context,
                            goal: goal,
                            anchor: anchor,
                            onOpenHistory: () => widget.onViewCalendar(goal),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.state});

  final GoalLoadedState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final goals = state.goals
        .where(
          (g) =>
              g.isActiveOn(now) ||
              state.todayMinutesFor(g.id) >= g.targetMinutes,
        )
        .toList();

    var focused = 0;
    var capped = 0;
    var target = 0;
    var done = 0;
    var bestStreak = 0;
    for (final g in state.goals) {
      bestStreak = math.max(
        bestStreak,
        calculateCurrentStreak(
          state.entriesFor(g.id),
          activeWeekdays: g.activeWeekdays,
        ),
      );
    }
    for (final g in goals) {
      final mins = state.todayMinutesFor(g.id);
      focused += mins;
      capped += math.min(mins, g.targetMinutes);
      target += g.targetMinutes;
      if (mins >= g.targetMinutes) done++;
    }
    final progress = target == 0 ? 0.0 : capped / target;
    final allDone = done == goals.length;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goals.isEmpty
                      ? 'Rest day, nothing scheduled'
                      : allDone
                      ? 'All targets met today'
                      : '$done of ${goals.length} done',
                  style: theme.titleMedium,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.titleSmall?.copyWith(
                  color: allDone ? AppColors.success : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(
            value: progress,
            height: 6,
            color: allDone ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StatBlock(
                  value: formatMinutes(focused),
                  label: 'Focused',
                ),
              ),
              Expanded(
                child: StatBlock(
                  value: formatMinutes(math.max(0, target - capped)),
                  label: 'Remaining',
                ),
              ),
              Expanded(
                child: StatBlock(
                  value: '$bestStreak ${bestStreak == 1 ? 'day' : 'days'}',
                  label: 'Best streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          _WeekStrip(state: state),
        ],
      ),
    );
  }
}

/// Last 7 days; filled when every goal hit its target that day.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.state});

  final GoalLoadedState state;

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    final theme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = DateTime(today.year, today.month, today.day - (6 - i));
        final active = state.goals.where((g) => g.isScheduledOn(day)).toList();
        var completed = 0;
        for (final g in active) {
          final hit = i == 6
              ? state.todayMinutesFor(g.id) >= g.targetMinutes
              : state
                    .entriesFor(g.id)
                    .any((e) => e.isCompleted && isSameDay(e.date, day));
          if (hit) completed++;
        }
        final isToday = i == 6;
        final perfect = active.isNotEmpty && completed == active.length;
        final partial = completed > 0 && !perfect;

        return Semantics(
          label:
              '${DateFormat('EEEE').format(day)}: $completed of ${active.length} goals done',
          child: Column(
            children: [
              Text(
                DateFormat('E').format(day),
                style: theme.labelSmall?.copyWith(
                  color: isToday ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: perfect
                      ? AppColors.primary
                      : partial
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: isToday
                      ? Border.all(color: AppColors.textSecondary)
                      : null,
                ),
                alignment: Alignment.center,
                child: perfect
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.onPrimary,
                      )
                    : Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active.isEmpty
                              ? AppColors.textFaint
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
