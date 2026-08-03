String formatSecondsDynamic(int seconds) {
  final mins = (seconds ~/ 60).clamp(0, 9999);
  final secs = (seconds % 60).clamp(0, 59);
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}
