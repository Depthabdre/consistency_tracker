import 'package:flutter/material.dart';

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
              backgroundColor: const Color(0xFF53B5EA),
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
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 20),
            label: Text(isPaused ? 'Resume session' : 'Pause session'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: onStop,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD0D0D0),
              side: const BorderSide(color: Color(0xFF4F4F4F)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: const Icon(Icons.stop, size: 20),
            label: const Text('Stop session'),
          ),
        ),
      ],
    );
  }
}
