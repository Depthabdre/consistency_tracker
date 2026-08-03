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
    );

    test('should convert GoalModel to JSON map and back correctly', () {
      final jsonMap = goal.toJson();
      final fromJsonGoal = GoalModel.fromJson(jsonMap);

      expect(fromJsonGoal, equals(goal));
      expect(jsonMap['targetMinutes'], equals(30));
      expect(jsonMap['title'], equals('Flutter Coding'));
    });

    test('copyWith should return updated goal instance', () {
      final updated = goal.copyWith(targetMinutes: 45);
      expect(updated.targetMinutes, equals(45));
      expect(updated.title, equals(goal.title));
    });
  });
}
