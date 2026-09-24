import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/calendar_day_model.dart';
import '../../domain/streak_calculator.dart';

/// Month calendar. Cells shrink to fit a bounded height so the whole month
/// is visible without scrolling.
class CalendarGridWidget extends StatelessWidget {
  const CalendarGridWidget({
    super.key,
    required this.currentMonth,
    required this.goalStartDate,
    required this.targetMinutes,
    required this.entries,
    required this.onDayTap,
    this.accent = AppColors.primary,
    this.maxCellHeight = 52,
    this.activeWeekdays = const [1, 2, 3, 4, 5, 6, 7],
  });

  final DateTime currentMonth;
  final DateTime goalStartDate;
  final int targetMinutes;
  final List<CalendarDayModel> entries;
  final ValueChanged<CalendarDayModel> onDayTap;
  final Color accent;
  final double maxCellHeight;
  final List<int> activeWeekdays;

  static const double _gap = 6;
  static const double _labelHeight = 18;

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    final start = dayOnly(goalStartDate);
    final byDay = {for (final e in entries) dayOnly(e.date): e};
    final first = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    final leading = first.weekday - 1;
    final weeks = ((leading + daysInMonth) / 7).ceil();
    final weekdayLabels = List.generate(
      7,
      (i) => DateFormat.E().format(DateTime(2024, 1, 1 + i)),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - _gap * 6) / 7;
        var cellHeight = math.min(cellWidth, maxCellHeight);
        if (constraints.hasBoundedHeight) {
          final fit =
              (constraints.maxHeight - _labelHeight - 8 - _gap * (weeks - 1)) /
              weeks;
          cellHeight = math.min(cellHeight, fit);
        }
        cellHeight = cellHeight.clamp(24.0, maxCellHeight);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _labelHeight,
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: Text(
                        weekdayLabels[i],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (var w = 0; w < weeks; w++) ...[
              if (w > 0) const SizedBox(height: _gap),
              SizedBox(
                height: cellHeight,
                child: Row(
                  children: [
                    for (var d = 0; d < 7; d++) ...[
                      if (d > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: _cell(
                          w * 7 + d - leading + 1,
                          daysInMonth,
                          byDay,
                          today,
                          start,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _cell(
    int dayNumber,
    int daysInMonth,
    Map<DateTime, CalendarDayModel> byDay,
    DateTime today,
    DateTime start,
  ) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox.shrink();
    }
    final date = DateTime(currentMonth.year, currentMonth.month, dayNumber);
    final entry = byDay[date];
    return _DayCell(
      date: date,
      entry: entry,
      accent: accent,
      isToday: date == today,
      isFuture: date.isAfter(today),
      isBeforeStart: date.isBefore(start),
      isRestDay: !activeWeekdays.contains(date.weekday),
      onTap: () => onDayTap(
        entry ??
            CalendarDayModel(
              date: date,
              totalMinutesFocused: 0,
              targetMinutes: targetMinutes,
              isCompleted: false,
            ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entry,
    required this.accent,
    required this.isToday,
    required this.isFuture,
    required this.isBeforeStart,
    required this.onTap,
    this.isRestDay = false,
  });

  final DateTime date;
  final CalendarDayModel? entry;
  final Color accent;
  final bool isToday;
  final bool isFuture;
  final bool isBeforeStart;
  final bool isRestDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = entry?.isCompleted ?? false;
    final minutes = entry?.totalMinutesFocused ?? 0;
    final missed =
        !isFuture && !isToday && !isBeforeStart && !completed && !isRestDay;
    final inactive = isFuture || isBeforeStart || isRestDay;

    final Color fill;
    final Color textColor;
    if (completed) {
      fill = accent;
      textColor = AppColors.background;
    } else if (minutes > 0) {
      fill = accent.withValues(alpha: 0.22);
      textColor = AppColors.textPrimary;
    } else if (missed) {
      fill = AppColors.danger.withValues(alpha: 0.1);
      textColor = AppColors.danger.withValues(alpha: 0.85);
    } else if (inactive) {
      fill = Colors.transparent;
      textColor = AppColors.textFaint;
    } else {
      fill = AppColors.surfaceHigh.withValues(alpha: 0.6);
      textColor = AppColors.textSecondary;
    }

    final status = completed
        ? 'target met'
        : missed
        ? 'missed, $minutes minutes'
        : isRestDay
        ? 'rest day'
        : isToday
        ? 'today, $minutes minutes'
        : 'upcoming';

    return Pressable(
      onTap: isBeforeStart ? null : onTap,
      pressedScale: 0.94,
      haptic: false,
      semanticLabel: '${DateFormat.MMMMd().format(date)}, $status',
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: isToday
              ? Border.all(color: AppColors.textPrimary, width: 1.5)
              : null,
        ),
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: completed || isToday
                ? FontWeight.w600
                : FontWeight.w400,
            color: textColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
