import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_day_model.dart';

class DayDetailBottomSheet extends StatelessWidget {
  final CalendarDayModel day;
  final String goalTitle;
  final DateTime goalStartDate;
  final Color accent;

  const DayDetailBottomSheet({
    super.key,
    required this.day,
    required this.goalTitle,
    required this.goalStartDate,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
    final startDateOnly = DateTime(
      goalStartDate.year,
      goalStartDate.month,
      goalStartDate.day,
    );

    final isToday = dayDate.isAtSameMomentAs(today);
    final isPast = dayDate.isBefore(today);
    final isBeforeStart = dayDate.isBefore(startDateOnly);

    final progressRatio = day.targetMinutes > 0
        ? (day.totalMinutesFocused / day.targetMinutes).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progressRatio * 100).toInt();

    final (
      Color statusColor,
      String statusText,
      IconData statusIcon,
    ) = day.isCompleted
        ? (AppColors.success, 'Target Completed', Icons.task_alt_rounded)
        : isPast && !isBeforeStart
        ? (AppColors.danger, 'Missed Target', Icons.cancel_rounded)
        : isToday
        ? (accent, 'In Progress Today', Icons.hourglass_top_rounded)
        : (AppColors.textMuted, 'Upcoming Day', Icons.schedule_rounded);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DateFormat.yMMMMEEEEd().format(day.date),
              style: theme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(goalTitle, style: theme.bodyMedium?.copyWith(color: accent)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: statusColor.withValues(alpha: 0.28)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusText,
                          style: theme.titleSmall?.copyWith(color: statusColor),
                        ),
                      ),
                      Text(
                        '$progressPercent%',
                        style: theme.titleMedium?.copyWith(
                          color: statusColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Verified focus', style: theme.bodySmall),
                      const Spacer(),
                      Text(
                        '${day.totalMinutesFocused} / ${day.targetMinutes} mins',
                        style: theme.titleSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Proof-of-work: minutes are only logged through real focus sessions, so every streak is honest.',
                    style: theme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
