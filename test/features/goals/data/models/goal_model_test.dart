import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';

void main() {
  group('GoalModel', () {
    const goal = GoalModel(
      id: '1',
      title: 'Flutter Coding',
      description: 'Build consistency tracker features daily',
      targetMinutes: 30,
      reminderTimeHour: 9,
      reminderTimeMinute: 0,
      motivationalQuote: 'Consistency is what transforms average into excellence.',
      colorHex: '#6366F1',
      isActive: true,
    );

    test('Positive: should convert GoalModel to JSON map and back correctly', () {
      final jsonMap = goal.toJson();
      final fromJsonGoal = GoalModel.fromJson(jsonMap);

      expect(fromJsonGoal, equals(goal));
      expect(jsonMap['targetMinutes'], equals(30));
      expect(jsonMap['title'], equals('Flutter Coding'));
    });

    test('Positive: copyWith should return updated goal instance', () {
      final updated = goal.copyWith(targetMinutes: 45, title: 'Updated Title');
      expect(updated.targetMinutes, equals(45));
      expect(updated.title, equals('Updated Title'));
      expect(updated.description, equals(goal.description));
    });

    test('Edge Case: fromJson should handle missing optional fields with defaults', () {
      final minimalJson = {
        'id': 'g2',
        'title': 'Minimal Goal',
      };

      final goalFromJson = GoalModel.fromJson(minimalJson);

      expect(goalFromJson.id, equals('g2'));
      expect(goalFromJson.title, equals('Minimal Goal'));
      expect(goalFromJson.description, equals(''));
      expect(goalFromJson.targetMinutes, equals(20));
      expect(goalFromJson.colorHex, equals('#6366F1'));
      expect(goalFromJson.isActive, isTrue);
    });

    test('Edge Case: goal equality should consider all properties', () {
      const sameGoal = GoalModel(
        id: '1',
        title: 'Flutter Coding',
        description: 'Build consistency tracker features daily',
        targetMinutes: 30,
        reminderTimeHour: 9,
        reminderTimeMinute: 0,
        motivationalQuote: 'Consistency is what transforms average into excellence.',
        colorHex: '#6366F1',
        isActive: true,
      );

      expect(goal, equals(sameGoal));
    });

    test('Negative Case: copyWith with no parameters should return equal instance', () {
      final copied = goal.copyWith();
      expect(copied, equals(goal));
    });
  });
}
