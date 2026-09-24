import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class WeeklyFocusChart extends StatelessWidget {
  final Map<int, int> weekdayMinutes; // 1 = Mon ... 7 = Sun
  final int? dailyTarget;

  const WeeklyFocusChart({
    super.key,
    required this.weekdayMinutes,
    this.dailyTarget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final currentWeekday = DateTime.now().weekday;
    final peak = weekdayMinutes.values.fold<int>(0, math.max);
    final maxMins = math.max(60, math.max(peak, dailyTarget ?? 0));
    final total = weekdayMinutes.values.fold<int>(0, (a, b) => a + b);
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const chartHeight = 120.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Focus Distribution',
                  style: theme.titleSmall,
                ),
              ),
              Text(
                '$total min',
                style: theme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: chartHeight + 46,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final minutes = weekdayMinutes[weekday] ?? 0;
                final isToday = weekday == currentWeekday;
                final ratio = (minutes / maxMins).clamp(0.0, 1.0);
                final hitTarget =
                    dailyTarget != null &&
                    dailyTarget! > 0 &&
                    minutes >= dailyTarget!;

                return Expanded(
                  child: Semantics(
                    label: '${dayLabels[index]}: $minutes minutes',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 16,
                            child: minutes > 0
                                ? Text(
                                    '${minutes}m',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio),
                            duration: AppMotion.slow,
                            curve: AppMotion.standard,
                            builder: (context, v, _) => Container(
                              height: math.max(4, chartHeight * v),
                              decoration: BoxDecoration(
                                color: minutes == 0
                                    ? AppColors.surfaceHigh
                                    : hitTarget
                                    ? AppColors.success
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dayLabels[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isToday
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Activity grid across all goals (columns = weeks, rows = weekdays).
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.dailyRatio, this.weeks = 18});

  final Map<DateTime, double> dailyRatio;
  final int weeks;

  static Color colorFor(double? ratio) {
    if (ratio == null) return AppColors.surfaceHigh.withValues(alpha: 0.35);
    if (ratio <= 0) return AppColors.surfaceHigh;
    if (ratio < 0.5) return AppColors.primary.withValues(alpha: 0.35);
    if (ratio < 1) return AppColors.primary.withValues(alpha: 0.65);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastMonday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final firstMonday = DateTime(
      lastMonday.year,
      lastMonday.month,
      lastMonday.day - 7 * (weeks - 1),
    );
    final activeDays = dailyRatio.values.where((r) => r > 0).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Activity', style: theme.titleSmall)),
              Text(
                '$activeDays active days · $weeks weeks',
                style: theme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 3.0;
              final cell = math.min(
                14.0,
                (constraints.maxWidth - gap * (weeks - 1)) / weeks,
              );
              return SizedBox(
                height: cell * 7 + gap * 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(weeks, (w) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (d) {
                        final day = DateTime(
                          firstMonday.year,
                          firstMonday.month,
                          firstMonday.day + w * 7 + d,
                        );
                        final future = day.isAfter(today);
                        return Container(
                          width: cell,
                          height: cell,
                          decoration: BoxDecoration(
                            color: future
                                ? Colors.transparent
                                : colorFor(dailyRatio[day]),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: theme.bodySmall),
              const SizedBox(width: 6),
              for (final r in [0.0, 0.3, 0.7, 1.0])
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: colorFor(r),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 6),
              Text('Target met', style: theme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
