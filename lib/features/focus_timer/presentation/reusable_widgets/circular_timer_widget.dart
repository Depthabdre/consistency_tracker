import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/widgets/progress_ring.dart';

/// Large live countdown ring for the active phase.
class CircularProgressTimer extends StatelessWidget {
  const CircularProgressTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.color,
    required this.caption,
    this.size = 300,
    this.paused = false,
    this.endsAt,
  });

  final int remainingSeconds;
  final int totalSeconds;
  final Color color;
  final String caption;
  final double size;
  final bool paused;
  final DateTime? endsAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final progress = totalSeconds == 0
        ? 0.0
        : (1 - remainingSeconds / totalSeconds).clamp(0.0, 1.0);

    return Semantics(
      label: '${formatClock(remainingSeconds)} remaining',
      liveRegion: false,
      child: AnimatedOpacity(
        duration: AppMotion.medium,
        opacity: paused ? 0.55 : 1,
        child: ProgressRing(
          progress: progress,
          size: size,
          strokeWidth: size * 0.025,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.linear,
          color: color,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatClock(remainingSeconds),
                style: theme.displayLarge?.copyWith(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -size * 0.004,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: AppMotion.medium,
                child: Text(
                  paused ? 'Paused' : caption,
                  key: ValueKey(paused ? 'paused' : caption),
                  style: theme.bodySmall?.copyWith(
                    color: paused ? AppColors.warning : AppColors.textMuted,
                  ),
                ),
              ),
              if (endsAt != null && !paused) ...[
                const SizedBox(height: 6),
                Text(
                  'Ends ${formatTimeOfDay(endsAt!)}',
                  style: theme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
