import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/session_phase.dart';

class PhaseTimelineWidget extends StatelessWidget {
  final List<SessionPhase> phases;
  final int currentPhaseIndex;

  const PhaseTimelineWidget({
    super.key,
    required this.phases,
    required this.currentPhaseIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF26282E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOutline, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(phases.length, (index) {
            final phase = phases[index];
            final bool isActive = index == currentPhaseIndex;
            final bool isPast = index < currentPhaseIndex;
            final bool isFocus = phase.type == SessionPhaseType.focus;

            final Color activeColor = isFocus
                ? const Color(0xFF53B5EA)
                : const Color(0xFF7ED39A);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor.withValues(alpha: 0.25)
                        : isPast
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? activeColor
                          : isPast
                          ? Colors.white24
                          : const Color(0xFF404040),
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFocus ? Icons.timer_rounded : Icons.local_cafe_rounded,
                        size: 14,
                        color: isActive
                            ? activeColor
                            : isPast
                            ? Colors.white54
                            : const Color(0xFFA0A0A0),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${isFocus ? 'Focus' : 'Break'} ${phase.labelMinutes}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : isPast
                              ? Colors.white60
                              : const Color(0xFFA0A0A0),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < phases.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF606060),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
