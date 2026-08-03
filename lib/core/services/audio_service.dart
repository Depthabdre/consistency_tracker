import 'package:flutter/services.dart';

abstract class AudioService {
  Future<void> playTransitionSound({required bool enabled});
  Future<void> stopSound();
}

class AudioServiceImpl implements AudioService {
  @override
  Future<void> playTransitionSound({required bool enabled}) async {
    if (!enabled) return;
    try {
      // Use system feedback chime/click safely across platforms
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Fallback cleanly if system audio is muted or unavailable
    }
  }

  @override
  Future<void> stopSound() async {
    // No-op for click feedback sound
  }
}
