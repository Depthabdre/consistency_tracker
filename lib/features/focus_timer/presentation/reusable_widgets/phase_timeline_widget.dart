import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/session_phase.dart';

/// Proportional focus/break segments. With [currentPhaseIndex] < 0 it renders
/// as a plan preview.
class PhaseTimelineWidget extends StatelessWidget {
  const PhaseTimelineWidget({
    super.key,
    required this.phases,
    required this.focusColor,
    this.currentPhaseIndex = -1,
    this.currentPhaseProgress = 0,
    this.height = 8,
  });

  final List<SessionPhase> phases;
  final Color focusColor;
  final int currentPhaseIndex;
  final double currentPhaseProgress;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty) return const SizedBox.shrink();
    final preview = currentPhaseIndex < 0;

    return Row(
      children: [
        for (var i = 0; i < phases.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            flex: (phases[i].durationSeconds ~/ 60).clamp(1, 1000),
            child: _Segment(
              color: phases[i].type == SessionPhaseType.focus
                  ? focusColor
                  : AppColors.success,
              fill: preview
                  ? 1
                  : i < currentPhaseIndex
                  ? 1
                  : i == currentPhaseIndex
                  ? currentPhaseProgress
                  : 0,
              dimmed: preview && phases[i].type == SessionPhaseType.breakTime,
              height: height,
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.color,
    required this.fill,
    required this.dimmed,
    required this.height,
  });

  final Color color;
  final double fill;
  final bool dimmed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: AppColors.surfaceHigh,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fill.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1000),
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: dimmed ? color.withValues(alpha: 0.55) : color,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
