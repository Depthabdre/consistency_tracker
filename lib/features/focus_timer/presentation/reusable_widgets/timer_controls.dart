import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class TimerControls extends StatelessWidget {
  const TimerControls({
    super.key,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onMinimize,
    this.color = AppColors.primary,
  });

  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onMinimize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoundControl(
          icon: Icons.stop_rounded,
          label: 'End',
          size: 52,
          onTap: onStop,
        ),
        const SizedBox(width: 24),
        _RoundControl(
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          label: isPaused ? 'Resume' : 'Pause',
          size: 72,
          color: color,
          primary: true,
          onTap: isPaused ? onResume : onPause,
        ),
        const SizedBox(width: 24),
        _RoundControl(
          icon: Icons.keyboard_arrow_down_rounded,
          label: 'Minimize',
          size: 52,
          onTap: onMinimize,
        ),
      ],
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.size,
    required this.onTap,
    this.color = AppColors.textPrimary,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;
  final Color color;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(size),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppMotion.medium,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary ? color : AppColors.surface,
              border: primary
                  ? null
                  : Border.all(color: AppColors.borderStrong),
            ),
            child: Icon(
              icon,
              size: size * 0.42,
              color: primary ? AppColors.background : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
