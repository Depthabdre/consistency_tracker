import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_day_model.dart';

class CalendarGridWidget extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime goalStartDate;
  final int targetMinutes;
  final List<CalendarDayModel> entries;
  final Function(CalendarDayModel day) onDayTap;

  const CalendarGridWidget({
    super.key,
    required this.currentMonth,
    required this.goalStartDate,
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isBeforeDay(DateTime a, DateTime b) {
    final dateA = DateTime(a.year, a.month, a.day);
    final dateB = DateTime(b.year, b.month, b.day);
    return dateA.isBefore(dateB);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDateOnly = DateTime(goalStartDate.year, goalStartDate.month, goalStartDate.day);

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
              final cellDate = DateTime(date.year, date.month, date.day);

              final isBeforeStart = cellDate.isBefore(startDateOnly);
              final isToday = _isSameDay(cellDate, today);
              final isPastAfterStart = _isBeforeDay(cellDate, today) && !isBeforeStart;

              final entry = _findEntryForDay(date);
              final focusedMins = entry?.totalMinutesFocused ?? 0;
              final isCompleted = focusedMins >= targetMinutes;
              final isMissedPastDay = isPastAfterStart && !isCompleted;

              // Grid cell styling based on exact state rules
              Color cellBgColor = const Color(0xFF262626);
              Color cellBorderColor = const Color(0xFF3A3A3A);
              Widget cellContent;

              if (isBeforeStart) {
                // Rule 1: Days before goal start date are disabled non-interactive
                cellBgColor = const Color(0xFF1E1E1E);
                cellBorderColor = const Color(0xFF2A2A2A);
                cellContent = Text(
                  '$dayNumber',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A4A4A),
                  ),
                );
              } else if (isCompleted) {
                // Rule 2: Green checkmark ONLY when targetMinutes is met
                cellBgColor = AppTheme.successGreen;
                cellBorderColor = AppTheme.successGreen;
                cellContent = const Icon(Icons.check, size: 18, color: Colors.black);
              } else if (isMissedPastDay) {
                // Rule 3: Missed past day after goal start date shows X icon
                cellBgColor = const Color(0xFF3A2024);
                cellBorderColor = const Color(0xFFF43F5E);
                cellContent = const Icon(Icons.close, size: 16, color: Color(0xFFF43F5E));
              } else if (isToday) {
                // Rule 4: Today cell with progress cyan border
                cellBgColor = AppTheme.accentCyan.withValues(alpha: 0.15);
                cellBorderColor = AppTheme.accentCyan;
                cellContent = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                    if (focusedMins > 0)
                      Text(
                        '${focusedMins}m',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                  ],
                );
              } else {
                // Rule 5: Future days after today
                cellContent = Text(
                  '$dayNumber',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                );
              }

              return GestureDetector(
                onTap: isBeforeStart
                    ? null
                    : () {
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
                    color: cellBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cellBorderColor,
                      width: isToday ? 1.8 : 1.0,
                    ),
                  ),
                  child: Center(child: cellContent),
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
