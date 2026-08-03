import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_day_model.dart';

class CalendarGridWidget extends StatelessWidget {
  final DateTime currentMonth;
  final int targetMinutes;
  final List<CalendarDayModel> entries;
  final Function(CalendarDayModel day) onDayTap;

  const CalendarGridWidget({
    super.key,
    required this.currentMonth,
    required this.targetMinutes,
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
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOutline, width: 1.2),
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
          const SizedBox(height: 14),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - (firstWeekday - 1) + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, dayNumber);
              final entry = _findEntryForDay(date);
              final isCompleted = entry?.isCompleted ?? false;
              final focusedMins = entry?.totalMinutesFocused ?? 0;
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return GestureDetector(
                onTap: () {
                  final targetDay = entry ??
                      CalendarDayModel(
                        date: date,
                        totalMinutesFocused: 0,
                        targetMinutes: targetMinutes,
                        isCompleted: false,
                      );
                  onDayTap(targetDay);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.successGreen
                        : (isToday
                            ? AppTheme.accentCyan.withValues(alpha: 0.15)
                            : const Color(0xFF262626)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? AppTheme.accentCyan
                          : (isCompleted
                              ? AppTheme.successGreen
                              : const Color(0xFF3A3A3A)),
                      width: isToday ? 1.8 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.black)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
                                  color: isToday ? AppTheme.accentCyan : AppTheme.textSecondary,
                                ),
                              ),
                              if (focusedMins > 0 && !isCompleted)
                                Text(
                                  '${focusedMins}m',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.accentCyan,
                                  ),
                                ),
                            ],
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
      width: 30,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
