import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TimerControls extends StatelessWidget {
  const TimerControls({
    super.key,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            onPressed: isPaused ? onResume : onPause,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 20,
            ),
            label: Text(isPaused ? 'Resume session' : 'Pause session'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: onStop,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.borderOutline),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: const Icon(Icons.stop_rounded, size: 20),
            label: const Text('Stop session'),
          ),
        ),
      ],
    );
  }
}
