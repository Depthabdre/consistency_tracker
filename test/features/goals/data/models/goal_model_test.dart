import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/goals/data/models/goal_model.dart';
import 'package:consistency_tracker/features/goals/data/models/reminder_time_model.dart';

void main() {
  group('GoalModel with createdAt & Edge Cases', () {
    final now = DateTime(2026, 8, 1);
    final goal = GoalModel(
      id: '1',
      title: 'Flutter Coding 🎯🚀',
      description: 'Build consistency tracker features daily',
      targetMinutes: 30,
      reminderTimeHour: 9,
      reminderTimeMinute: 0,
      reminderTimes: const [ReminderTimeModel(hour: 9, minute: 0)],
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

    test('Edge Case: handle unicode emojis and special characters in title and quote', () {
      final unicodeGoal = goal.copyWith(
        title: '🎯 Coding / & <script>alert("xss")</script> 🚀',
        motivationalQuote: '¡Hola! 🌟 Success is 100% effort & persistence.',
      );

      final json = unicodeGoal.toJson();
      final fromJson = GoalModel.fromJson(json);

      expect(fromJson.title, equals('🎯 Coding / & <script>alert("xss")</script> 🚀'));
      expect(fromJson.motivationalQuote, contains('¡Hola! 🌟'));
    });

    test('Edge Case: handle massive description strings (10,000 characters)', () {
      final longDesc = 'A' * 10000;
      final longGoal = goal.copyWith(description: longDesc);

      final json = longGoal.toJson();
      final fromJson = GoalModel.fromJson(json);

      expect(fromJson.description.length, equals(10000));
    });

    test('Edge Case: fromJson without createdAt should default to current DateTime', () {
      final jsonWithoutDate = {
        'id': 'g2',
        'title': 'Legacy Goal',
        'targetMinutes': 25,
      };

      final parsed = GoalModel.fromJson(jsonWithoutDate);

      expect(parsed.id, equals('g2'));
      expect(parsed.title, equals('Legacy Goal'));
      expect(parsed.targetMinutes, equals(25));
      expect(parsed.createdAt, isNotNull);
      expect(parsed.reminderTimes.length, equals(1));
    });

    test('Negative: fromJson with invalid targetMinutes string falls back safely', () {
      final invalidJson = {
        'id': 'g3',
        'title': 'Corrupted Goal',
        'targetMinutes': 'not_a_number',
      };

      final parsed = GoalModel.fromJson(invalidJson);

      expect(parsed.targetMinutes, equals(20)); // default fallback
    });
  });
}
