import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/focus_timer/data/models/focus_session_model.dart';

void main() {
  group('FocusSessionModel', () {
    final now = DateTime(2026, 8, 3, 11, 0, 0);
    final session = FocusSessionModel(
      id: 'session-1',
      goalId: 'goal-1',
      durationMinutes: 30,
      timestamp: now,
      completedTargetMet: true,
    );

    test('Positive: should convert to JSON and back cleanly', () {
      final json = session.toJson();
      final fromJson = FocusSessionModel.fromJson(json);

      expect(fromJson.id, equals(session.id));
      expect(fromJson.goalId, equals(session.goalId));
      expect(fromJson.durationMinutes, equals(30));
      expect(fromJson.completedTargetMet, isTrue);
      expect(fromJson, equals(session));
    });

    test('Edge Case: fromJson should default completedTargetMet to false if missing', () {
      final minimalJson = {
        'id': 's2',
        'goalId': 'g2',
        'durationMinutes': 15,
        'timestamp': '2026-08-03T10:00:00.000',
      };

      final parsed = FocusSessionModel.fromJson(minimalJson);

      expect(parsed.id, equals('s2'));
      expect(parsed.completedTargetMet, isFalse);
    });

    test('Edge Case: 0 duration focus session should parse cleanly', () {
      final zeroSession = FocusSessionModel(
        id: 's0',
        goalId: 'g1',
        durationMinutes: 0,
        timestamp: now,
        completedTargetMet: false,
      );

      final json = zeroSession.toJson();
      final fromJson = FocusSessionModel.fromJson(json);

      expect(fromJson.durationMinutes, equals(0));
      expect(fromJson.completedTargetMet, isFalse);
    });
  });
}
