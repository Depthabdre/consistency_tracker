import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';

void main() {
  group('GoalModel with createdAt', () {
    final now = DateTime(2026, 8, 1);
    final goal = GoalModel(
      id: '1',
      title: 'Flutter Coding',
      description: 'Build consistency tracker features daily',
      targetMinutes: 30,
      reminderTimeHour: 9,
      reminderTimeMinute: 0,
      motivationalQuote: 'Consistency is what transforms average into excellence.',
      colorHex: '#6366F1',
      createdAt: now,
      isActive: true,
    );

    test('Positive: should convert createdAt to JSON and back correctly', () {
      final jsonMap = goal.toJson();
      final fromJsonGoal = GoalModel.fromJson(jsonMap);

      expect(fromJsonGoal.createdAt.year, equals(2026));
      expect(fromJsonGoal.createdAt.month, equals(8));
      expect(fromJsonGoal.createdAt.day, equals(1));
      expect(fromJsonGoal, equals(goal));
    });

    test('Edge Case: fromJson without createdAt should default to current DateTime', () {
      final jsonWithoutDate = {
        'id': 'g2',
        'title': 'Legacy Goal',
        'targetMinutes': 25,
      };

      final parsed = GoalModel.fromJson(jsonWithoutDate);

      expect(parsed.id, equals('g2'));
      expect(parsed.createdAt, isA<DateTime>());
    });
  });
}
