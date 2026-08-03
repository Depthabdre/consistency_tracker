import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/core/utils/time_formatter.dart';

void main() {
  group('formatSecondsDynamic', () {
    test('Positive: should format standard minutes and seconds correctly', () {
      expect(formatSecondsDynamic(150), equals('02:30'));
      expect(formatSecondsDynamic(3600), equals('60:00'));
    });

    test('Positive: should format single digit seconds with leading zero', () {
      expect(formatSecondsDynamic(65), equals('01:05'));
      expect(formatSecondsDynamic(9), equals('00:09'));
    });

    test('Edge Case: 0 seconds should return 00:00', () {
      expect(formatSecondsDynamic(0), equals('00:00'));
    });

    test('Edge Case: negative seconds should be clamped to 00:00', () {
      expect(formatSecondsDynamic(-10), equals('00:00'));
    });

    test('Edge Case: large duration should format hours into total minutes', () {
      expect(formatSecondsDynamic(7200), equals('120:00'));
    });
  });
}
