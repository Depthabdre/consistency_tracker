import 'package:flutter/services.dart';

abstract class AudioService {
  Future<void> playTransitionSound({required bool enabled});
  Future<void> stopSound();
  Future<void> triggerLightHaptic();
  Future<void> triggerMediumHaptic();
}

class AudioServiceImpl implements AudioService {
  @override
  Future<void> playTransitionSound({required bool enabled}) async {
    if (!enabled) return;
    try {
      await HapticFeedback.mediumImpact();
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

  @override
  Future<void> triggerLightHaptic() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  @override
  Future<void> triggerMediumHaptic() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
