import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../goals/data/models/goal_model.dart';

/// Summary shown after a session has been logged to the calendar.
Future<void> showSessionCompleteDialog(
  BuildContext context, {
  required GoalModel goal,
  required int sessionMinutes,
  required int todayMinutes,
  required bool targetMet,
  required int streak,
}) {
  HapticFeedback.mediumImpact();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SessionCompleteDialog(
      goal: goal,
      sessionMinutes: sessionMinutes,
      todayMinutes: todayMinutes,
      targetMet: targetMet,
      streak: streak,
    ),
  );
}

class _SessionCompleteDialog extends StatelessWidget {
  const _SessionCompleteDialog({
    required this.goal,
    required this.sessionMinutes,
    required this.todayMinutes,
    required this.targetMet,
    required this.streak,
  });

  final GoalModel goal;
  final int sessionMinutes;
  final int todayMinutes;
  final bool targetMet;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final remaining = (goal.targetMinutes - todayMinutes).clamp(0, 1 << 30);
    final progress = goal.targetMinutes == 0
        ? 1.0
        : todayMinutes / goal.targetMinutes;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (targetMet ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: targetMet ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                targetMet ? 'Daily target reached' : 'Session logged',
                style: theme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${formatMinutes(sessionMinutes)} added to ${goal.title}',
                style: theme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StatBlock(
                      value: '$todayMinutes/${goal.targetMinutes} min',
                      label: 'Today',
                    ),
                  ),
                  Expanded(
                    child: StatBlock(
                      value: '$streak ${streak == 1 ? 'day' : 'days'}',
                      label: 'Streak',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ProgressBar(
                value: progress,
                color: targetMet ? AppColors.success : AppColors.primary,
                height: 6,
              ),
              const SizedBox(height: 12),
              Text(
                targetMet
                    ? 'Today is marked complete on your calendar.'
                    : '${formatMinutes(remaining)} left to reach today’s target.',
                style: theme.bodySmall,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
