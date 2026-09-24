import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../calendar_heatmap/data/models/calendar_day_model.dart';
import '../../../calendar_heatmap/domain/streak_calculator.dart';
import '../../data/models/goal_model.dart';

class GoalCardWidget extends StatelessWidget {
  const GoalCardWidget({
    super.key,
    required this.goal,
    required this.onStartFocus,
    required this.onOpen,
    required this.onMore,
    this.todayFocusedMinutes = 0,
    this.entries = const [],
    this.isLive = false,
  });

  final GoalModel goal;
  final int todayFocusedMinutes;
  final List<CalendarDayModel> entries;
  final bool isLive;
  final VoidCallback onStartFocus;
  final VoidCallback onOpen;

  /// Receives the context of the "more" button so menus can anchor to it.
  final ValueChanged<BuildContext> onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final accent = colorFromHex(goal.colorHex);
    final isDone = todayFocusedMinutes >= goal.targetMinutes;
    final progress = goal.targetMinutes == 0
        ? 0.0
        : todayFocusedMinutes / goal.targetMinutes;
    final streak = calculateCurrentStreak(
      entries,
      activeWeekdays: goal.activeWeekdays,
    );
    final isRestDay = !isDone && !goal.isActiveOn(DateTime.now());

    return AppCard(
      onTap: onOpen,
      semanticLabel:
          '${goal.title}, $todayFocusedMinutes of ${goal.targetMinutes} minutes today',
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
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
                    Flexible(
                      child: Text(
                        goal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleMedium,
                      ),
                    ),
                    if (isLive) ...[
                      const SizedBox(width: 8),
                      const InfoPill(
                        label: 'In session',
                        color: AppColors.primary,
                      ),
                    ] else if (isRestDay) ...[
                      const SizedBox(width: 8),
                      const InfoPill(label: 'Rest day'),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$todayFocusedMinutes / ${goal.targetMinutes} min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (isDone) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                    ],
                    const Spacer(),
                    if (streak > 0)
                      Flexible(
                        child: Text(
                          '$streak day streak',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ProgressBar(
                  value: progress,
                  color: isDone
                      ? AppColors.success
                      : isRestDay
                      ? AppColors.textMuted
                      : accent,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Tooltip(
            message: 'Start focus',
            child: Pressable(
              onTap: onStartFocus,
              pressedScale: 0.94,
              semanticLabel: 'Start focus on ${goal.title}',
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(Icons.play_arrow_rounded, color: accent, size: 22),
              ),
            ),
          ),
          Builder(
            builder: (anchor) => IconButton(
              tooltip: 'More',
              onPressed: () => onMore(anchor),
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
