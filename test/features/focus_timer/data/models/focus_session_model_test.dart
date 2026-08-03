import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/focus_timer/data/models/focus_session_model.dart';

void main() {
  group('FocusSessionModel', () {
    final now = DateTime.now();
    final session = FocusSessionModel(
      id: 'session-1',
      goalId: 'goal-1',
      durationMinutes: 30,
      timestamp: now,
      completedTargetMet: true,
    );

    test('should convert to JSON and back cleanly', () {
      final json = session.toJson();
      final fromJson = FocusSessionModel.fromJson(json);

      expect(fromJson.id, equals(session.id));
      expect(fromJson.goalId, equals(session.goalId));
      expect(fromJson.durationMinutes, equals(30));
      expect(fromJson.completedTargetMet, isTrue);
    });
  });
}
