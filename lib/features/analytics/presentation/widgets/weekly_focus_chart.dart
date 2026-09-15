import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WeeklyFocusChart extends StatelessWidget {
  final Map<int, int> weekdayMinutes; // 1 = Mon ... 7 = Sun

  const WeeklyFocusChart({super.key, required this.weekdayMinutes});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Mon ... 7 = Sun
    final maxMins = weekdayMinutes.values.isEmpty
        ? 60
        : math.max(60, weekdayMinutes.values.reduce(math.max));

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderOutline, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Focus Distribution',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: AppTheme.accentCyan, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Verified focus minutes logged this week (Mon–Sun)',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final minutes = weekdayMinutes[weekday] ?? 0;
                final isToday = weekday == currentWeekday;
                final double barRatio = (minutes / maxMins).clamp(0.06, 1.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (minutes > 0)
                          Text(
                            '${minutes}m',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? AppTheme.accentCyan
                                  : AppTheme.textMuted,
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: barRatio,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppTheme.accentCyan
                                      : (minutes > 0
                                            ? AppTheme.accentIndigo
                                            : const Color(0xFF262626)),
                                  borderRadius: BorderRadius.circular(5),
                                  border: isToday
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 1.2,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayLabels[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? AppTheme.accentCyan
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
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
