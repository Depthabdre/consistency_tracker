import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/goal_model.dart';

class GoalCardWidget extends StatelessWidget {
  final GoalModel goal;
  final int todayFocusedMinutes;
  final VoidCallback onStartFocus;
  final VoidCallback onViewCalendar;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const GoalCardWidget({
    super.key,
    required this.goal,
    this.todayFocusedMinutes = 0,
    required this.onStartFocus,
    required this.onViewCalendar,
    required this.onDelete,
    this.onEdit,
  });

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('ff$clean', radix: 16));
    } catch (_) {
      return AppTheme.accentCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(goal.colorHex);
    final isTargetMet = todayFocusedMinutes >= goal.targetMinutes;
    final progressRatio = goal.targetMinutes > 0
        ? (todayFocusedMinutes / goal.targetMinutes).clamp(0.0, 1.0)
        : 0.0;
    final reminders = goal.activeReminderTimes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTargetMet ? AppTheme.successGreen : AppTheme.borderOutline,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isTargetMet)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.successGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppTheme.successGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Target Completed Today',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    '${goal.targetMinutes}m target',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  color: AppTheme.surfaceCard,
                  onSelected: (val) {
                    if (val == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: AppTheme.accentCyan,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Edit Goal',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFF43F5E),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Goal',
                            style: TextStyle(color: Color(0xFFF43F5E)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (goal.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                goal.description,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Active Reminder Chips
            if (reminders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: reminders.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.borderOutline.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 13,
                            color: AppTheme.accentCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            r.formattedTime,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Daily Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today: $todayFocusedMinutes / ${goal.targetMinutes} mins',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isTargetMet
                        ? AppTheme.successGreen
                        : AppTheme.textMuted,
                    fontWeight: isTargetMet ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Text(
                  '${(progressRatio * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progressRatio),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: animatedValue,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF262626),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isTargetMet ? AppTheme.successGreen : accentColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewCalendar,
                    icon: const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                    ),
                    label: const Text('Heatmap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.borderOutline),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onStartFocus,
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: Colors.black,
                    ),
                    label: const Text('Start Focus'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
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
