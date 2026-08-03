import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_day_model.dart';

class CalendarGridWidget extends StatelessWidget {
  final DateTime currentMonth;
  final List<CalendarDayModel> entries;
  final Function(CalendarDayModel day) onDayTap;

  const CalendarGridWidget({
    super.key,
    required this.currentMonth,
    required this.entries,
    required this.onDayTap,
  });

  CalendarDayModel? _findEntryForDay(DateTime date) {
    for (final entry in entries) {
      if (entry.date.year == date.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day) {
        return entry;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday;

    final totalCells = daysInMonth + (firstWeekday - 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Weekday Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 16),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - (firstWeekday - 1) + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, dayNumber);
              final entry = _findEntryForDay(date);
              final isCompleted = entry?.isCompleted ?? false;
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return GestureDetector(
                onTap: () {
                  final targetDay = entry ??
                      CalendarDayModel(
                        date: date,
                        totalMinutesFocused: 0,
                        targetMinutes: 20,
                        isCompleted: false,
                      );
                  onDayTap(targetDay);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.success
                        : (isToday
                            ? AppTheme.primary.withValues(alpha: 0.25)
                            : AppTheme.background),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? AppTheme.primary
                          : (isCompleted
                              ? AppTheme.success
                              : Colors.white.withValues(alpha: 0.05)),
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: AppTheme.success.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? AppTheme.primary : AppTheme.textSecondary,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
