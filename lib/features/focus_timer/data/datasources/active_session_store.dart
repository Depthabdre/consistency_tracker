import 'package:hive/hive.dart';
import '../../domain/entities/session_phase.dart';

/// Persisted state of an in-progress session so it survives app restarts.
class ActiveSessionSnapshot {
  const ActiveSessionSnapshot({
    required this.goalId,
    required this.targetMinutes,
    required this.phases,
    required this.currentPhaseIndex,
    required this.remainingSecondsInPhase,
    required this.elapsedSeconds,
    required this.accumulatedFocusSeconds,
    required this.paused,
    this.targetEndTime,
    this.soundEnabled = true,
    this.notificationsEnabled = true,
  });

  final String goalId;
  final int targetMinutes;
  final List<SessionPhase> phases;
  final int currentPhaseIndex;
  final int remainingSecondsInPhase;
  final int elapsedSeconds;
  final int accumulatedFocusSeconds;
  final bool paused;
  final DateTime? targetEndTime;
  final bool soundEnabled;
  final bool notificationsEnabled;

  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'targetMinutes': targetMinutes,
    'phases': [
      for (final p in phases)
        {
          'type': p.type.name,
          'durationSeconds': p.durationSeconds,
          'labelMinutes': p.labelMinutes,
        },
    ],
    'currentPhaseIndex': currentPhaseIndex,
    'remainingSecondsInPhase': remainingSecondsInPhase,
    'elapsedSeconds': elapsedSeconds,
    'accumulatedFocusSeconds': accumulatedFocusSeconds,
    'paused': paused,
    'targetEndTime': targetEndTime?.toIso8601String(),
    'soundEnabled': soundEnabled,
    'notificationsEnabled': notificationsEnabled,
  };

  static ActiveSessionSnapshot? tryParse(Map<String, dynamic> json) {
    try {
      final phases = [
        for (final raw in json['phases'] as List)
          SessionPhase(
            type: SessionPhaseType.values.byName(raw['type'] as String),
            durationSeconds: raw['durationSeconds'] as int,
            labelMinutes: raw['labelMinutes'] as int,
          ),
      ];
      final index = json['currentPhaseIndex'] as int;
      if (phases.isEmpty || index < 0 || index >= phases.length) return null;
      final end = json['targetEndTime'] as String?;
      return ActiveSessionSnapshot(
        goalId: json['goalId'] as String,
        targetMinutes: json['targetMinutes'] as int,
        phases: phases,
        currentPhaseIndex: index,
        remainingSecondsInPhase: json['remainingSecondsInPhase'] as int,
        elapsedSeconds: json['elapsedSeconds'] as int,
        accumulatedFocusSeconds: json['accumulatedFocusSeconds'] as int,
        paused: json['paused'] as bool,
        targetEndTime: end == null ? null : DateTime.tryParse(end),
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }
}

abstract class ActiveSessionStore {
  Future<ActiveSessionSnapshot?> load();
  Future<void> save(ActiveSessionSnapshot snapshot);
  Future<void> clear();
}

class HiveActiveSessionStore implements ActiveSessionStore {
  static const _boxName = 'active_session_box';
  static const _key = 'current';

  @override
  Future<ActiveSessionSnapshot?> load() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_key);
    if (raw is! Map) return null;
    return ActiveSessionSnapshot.tryParse(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> save(ActiveSessionSnapshot snapshot) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_key, snapshot.toJson());
  }

  @override
  Future<void> clear() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_key);
  }
}

/// Default store that keeps nothing; used in tests and when unconfigured.
class NoopActiveSessionStore implements ActiveSessionStore {
  const NoopActiveSessionStore();

  @override
  Future<ActiveSessionSnapshot?> load() async => null;

  @override
  Future<void> save(ActiveSessionSnapshot snapshot) async {}

  @override
  Future<void> clear() async {}
}
