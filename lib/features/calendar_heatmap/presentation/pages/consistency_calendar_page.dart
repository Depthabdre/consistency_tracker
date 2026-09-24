import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/presentation/bloc/goal_bloc.dart';
import '../../../goals/presentation/bloc/goal_state.dart';
import '../../../goals/presentation/goal_actions.dart';
import '../../data/models/calendar_day_model.dart';
import '../../domain/streak_calculator.dart';
import '../reusable_widgets/calendar_grid_widget.dart';
import '../reusable_widgets/day_detail_bottom_sheet.dart';
import '../reusable_widgets/streak_counter_widget.dart';

/// Goal detail: stats and the monthly calendar. On wide windows everything
/// fits on one screen; on phones it scrolls.
class ConsistencyCalendarPage extends StatefulWidget {
  final GoalModel goal;
  final ValueChanged<GoalModel>? onStartFocus;

  const ConsistencyCalendarPage({
    super.key,
    required this.goal,
    this.onStartFocus,
  });

  @override
  State<ConsistencyCalendarPage> createState() =>
      _ConsistencyCalendarPageState();
}

class _ConsistencyCalendarPageState extends State<ConsistencyCalendarPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  DateTime get _firstMonth =>
      DateTime(widget.goal.createdAt.year, widget.goal.createdAt.month);

  DateTime get _lastMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get _canGoBack => _month.isAfter(_firstMonth);
  bool get _canGoForward => _month.isBefore(_lastMonth);

  void _changeMonth(int delta) {
    if (delta < 0 && !_canGoBack) return;
    if (delta > 0 && !_canGoForward) return;
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalBloc, GoalState>(
      buildWhen: (prev, curr) =>
          !(curr is GoalLoadingState && prev is GoalLoadedState),
      builder: (context, state) {
        final loaded = state is GoalLoadedState ? state : null;
        final goal = loaded?.goals
            .where((g) => g.id == widget.goal.id)
            .firstOrNull;

        if (loaded != null && goal == null) {
          // Goal was deleted while this page was open.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).maybePop();
          });
          return const Scaffold(backgroundColor: AppColors.background);
        }

        final current = goal ?? widget.goal;
        return _buildPage(
          context,
          current,
          loaded?.entriesFor(current.id) ?? const [],
          loaded?.todayMinutesFor(current.id) ?? 0,
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    GoalModel goal,
    List<CalendarDayModel> entries,
    int todayMinutes,
  ) {
    final accent = colorFromHex(goal.colorHex);
    final consistency = calculateConsistency(
      entries,
      startDate: goal.createdAt,
      activeWeekdays: goal.activeWeekdays,
    );
    final stats = StreakCounterWidget(
      currentStreak: calculateCurrentStreak(
        entries,
        activeWeekdays: goal.activeWeekdays,
      ),
      bestStreak: calculateLongestStreak(
        entries,
        activeWeekdays: goal.activeWeekdays,
      ),
      completionRate: consistency.eligible == 0
          ? '—'
          : '${(consistency.met / consistency.eligible * 100).round()}%',
      totalFocus: formatMinutes(
        entries.fold<int>(0, (s, e) => s + e.totalMinutesFocused),
      ),
    );

    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          AppIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit goal',
            onTap: () => openGoalEditor(context, goal: goal),
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete goal',
            color: AppColors.danger,
            onTap: () => deleteGoalWithUndo(context, goal),
          ),
        ],
      ),
    );

    final startButton = widget.onStartFocus == null
        ? null
        : PrimaryButton(
            label: todayMinutes >= goal.targetMinutes
                ? 'Start another session'
                : 'Start focus',
            icon: Icons.play_arrow_rounded,
            onPressed: () => widget.onStartFocus!(goal),
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 760 && constraints.maxHeight >= 500;

            if (wide) {
              return Column(
                children: [
                  topBar,
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: math.min(340, constraints.maxWidth * 0.36),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _GoalHeader(goal: goal, accent: accent),
                                        const SizedBox(height: 20),
                                        _TodayCard(
                                          goal: goal,
                                          todayMinutes: todayMinutes,
                                          accent: accent,
                                        ),
                                        const SizedBox(height: 12),
                                        stats,
                                      ],
                                    ),
                                  ),
                                ),
                                if (startButton != null) ...[
                                  const SizedBox(height: 16),
                                  startButton,
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _calendarCard(goal, entries, accent, true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final gutter = math.max(20.0, (constraints.maxWidth - 640) / 2);
            return Column(
              children: [
                topBar,
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 24),
                    children: [
                      _GoalHeader(goal: goal, accent: accent),
                      const SizedBox(height: 16),
                      _TodayCard(
                        goal: goal,
                        todayMinutes: todayMinutes,
                        accent: accent,
                      ),
                      const SizedBox(height: 12),
                      stats,
                      const SizedBox(height: 12),
                      _calendarCard(goal, entries, accent, false),
                    ],
                  ),
                ),
                if (startButton != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 12),
                    child: SizedBox(width: double.infinity, child: startButton),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _calendarCard(
    GoalModel goal,
    List<CalendarDayModel> entries,
    Color accent,
    bool expand,
  ) {
    final theme = Theme.of(context).textTheme;
    final grid = AnimatedSwitcher(
      duration: AppMotion.fast,
      child: CalendarGridWidget(
        key: ValueKey(_month),
        currentMonth: _month,
        goalStartDate: goal.createdAt,
        targetMinutes: goal.targetMinutes,
        entries: entries,
        accent: accent,
        activeWeekdays: goal.activeWeekdays,
        maxCellHeight: expand ? 56 : 42,
        onDayTap: (day) => showModalBottomSheet<void>(
          context: context,
          builder: (_) => DayDetailBottomSheet(
            day: day,
            goalTitle: goal.title,
            goalStartDate: goal.createdAt,
            accent: accent,
          ),
        ),
      ),
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -200) _changeMonth(1);
          if (v > 200) _changeMonth(-1);
        },
        child: Column(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_month),
                    style: theme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: _canGoBack ? () => _changeMonth(-1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: _canGoForward ? () => _changeMonth(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (expand) Expanded(child: grid) else grid,
            const SizedBox(height: 12),
            _Legend(accent: accent, showRest: goal.hasRestDays),
          ],
        ),
      ),
    );
  }
}

class _GoalHeader extends StatelessWidget {
  const _GoalHeader({required this.goal, required this.accent});

  final GoalModel goal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final reminders = goal.activeReminderTimes
        .map((r) => r.formattedTime)
        .join(', ');
    return Column(
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
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${formatMinutes(goal.targetMinutes)} · ${goal.scheduleLabel} · since ${DateFormat('MMM d, y').format(goal.createdAt)}',
                style: theme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          goal.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.headlineMedium,
        ),
        if (goal.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            goal.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium,
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Reminders at $reminders',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.goal,
    required this.todayMinutes,
    required this.accent,
  });

  final GoalModel goal;
  final int todayMinutes;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final done = todayMinutes >= goal.targetMinutes;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Today', style: theme.titleSmall),
              const Spacer(),
              Text(
                done
                    ? 'Done · $todayMinutes min'
                    : '$todayMinutes / ${goal.targetMinutes} min',
                style: theme.bodySmall?.copyWith(
                  color: done ? AppColors.success : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(
            value: goal.targetMinutes == 0
                ? 0
                : todayMinutes / goal.targetMinutes,
            color: done ? AppColors.success : accent,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.accent, this.showRest = false});

  final Color accent;
  final bool showRest;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, Color color, {bool outline = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: outline
                  ? Border.all(color: AppColors.textPrimary, width: 1.5)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        item('Target met', accent),
        item('Partial', accent.withValues(alpha: 0.22)),
        item('Missed', AppColors.danger.withValues(alpha: 0.25)),
        if (showRest)
          item('Rest day', AppColors.surfaceHigh.withValues(alpha: 0.3)),
        item('Today', Colors.transparent, outline: true),
      ],
    );
  }
}
