import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/goals/data/models/reminder_time_model.dart';

void main() {
  group('ReminderTimeModel QA Skill Unit Tests', () {
    test(
      'TC-P0-01 (Positive): Valid 09:30 AM serialization and formatting',
      () {
        const model = ReminderTimeModel(hour: 9, minute: 30);
        final json = model.toJson();

        expect(json['hour'], equals(9));
        expect(json['minute'], equals(30));
        expect(model.formattedTime, equals('9:30 AM'));

        final reconstructed = ReminderTimeModel.fromJson(json);
        expect(reconstructed, equals(model));
      },
    );

    test('TC-P0-02 (Positive): Valid 18:45 PM formatting', () {
      const model = ReminderTimeModel(hour: 18, minute: 45);
      expect(model.formattedTime, equals('6:45 PM'));
    });

    test('TC-B0-01 (Boundary): Midnight 00:00 formatting', () {
      const model = ReminderTimeModel(hour: 0, minute: 0);
      expect(model.formattedTime, equals('12:00 AM'));
    });

    test('TC-B0-02 (Boundary): Noon 12:00 formatting', () {
      const model = ReminderTimeModel(hour: 12, minute: 0);
      expect(model.formattedTime, equals('12:00 PM'));
    });

    test('TC-N1-01 (Negative): Invalid hour > 23 is clamped to 23', () {
      final model = ReminderTimeModel.fromJson({'hour': 25, 'minute': 30});
      expect(model.hour, equals(23));
      expect(model.minute, equals(30));
    });

    test('TC-N1-02 (Negative): Invalid minute > 59 is clamped to 59', () {
      final model = ReminderTimeModel.fromJson({'hour': 10, 'minute': 90});
      expect(model.hour, equals(10));
      expect(model.minute, equals(59));
    });

    test(
      'TC-C0-01 (Monkey/Chaos): Corrupted string inputs fallback to default 09:00 AM',
      () {
        final model = ReminderTimeModel.fromJson({
          'hour': 'invalid',
          'minute': null,
        });
        expect(model.hour, equals(9));
        expect(model.minute, equals(0));
        expect(model.formattedTime, equals('9:00 AM'));
      },
    );
  });
}
