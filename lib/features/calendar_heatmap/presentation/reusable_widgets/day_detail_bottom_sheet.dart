import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/calendar_day_model.dart';

class DayDetailBottomSheet extends StatelessWidget {
  final CalendarDayModel day;
  final String goalTitle;
  final DateTime goalStartDate;

  const DayDetailBottomSheet({
    super.key,
    required this.day,
    required this.goalTitle,
    required this.goalStartDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
    final startDateOnly = DateTime(
      goalStartDate.year,
      goalStartDate.month,
      goalStartDate.day,
    );

    final bool isToday = dayDate.isAtSameMomentAs(today);
    final bool isPast = dayDate.isBefore(today);
    final bool isBeforeStart = dayDate.isBefore(startDateOnly);

    final double progressRatio = day.targetMinutes > 0
        ? (day.totalMinutesFocused / day.targetMinutes).clamp(0.0, 1.0)
        : 0.0;
    final int progressPercent = (progressRatio * 100).toInt();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (day.isCompleted) {
      statusColor = AppTheme.successGreen;
      statusText = 'Target Completed';
      statusIcon = Icons.task_alt_rounded;
    } else if (isPast && !isBeforeStart) {
      statusColor = const Color(0xFFF43F5E);
      statusText = 'Missed Target';
      statusIcon = Icons.cancel_rounded;
    } else if (isToday) {
      statusColor = AppTheme.accentCyan;
      statusText = 'In Progress Today';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusColor = AppTheme.textMuted;
      statusText = 'Upcoming Day';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppTheme.borderOutline, width: 1.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMMEEEEd().format(day.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goalTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '$progressPercent%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Verified Focus Log Metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundStart,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderOutline),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Verified Focus Time',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    Text(
                      '${day.totalMinutesFocused} / ${day.targetMinutes} mins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF262626),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      day.isCompleted
                          ? AppTheme.successGreen
                          : AppTheme.accentCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Proof-of-Work Integrity Note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 16,
                color: AppTheme.accentCyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Proof-of-work: Focus minutes are logged exclusively through actual timer sessions to guarantee streak honesty.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderOutline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close Inspector'),
            ),
          ),
        ],
      ),
    );
  }
}
