import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/core/utils/time_formatter.dart';

void main() {
  group('formatSecondsDynamic', () {
    test('Positive: should format minutes (>= 60s) with m suffix', () {
      expect(formatSecondsDynamic(1500), equals('25m'));
      expect(formatSecondsDynamic(120), equals('2m'));
      expect(formatSecondsDynamic(60), equals('1m'));
    });

    test('Positive: should format seconds (< 60s) with s suffix', () {
      expect(formatSecondsDynamic(59), equals('59s'));
      expect(formatSecondsDynamic(45), equals('45s'));
      expect(formatSecondsDynamic(9), equals('9s'));
    });

    test('Edge Case: 0 seconds should return 0s', () {
      expect(formatSecondsDynamic(0), equals('0s'));
    });

    test('Edge Case: negative seconds should be clamped to 0s', () {
      expect(formatSecondsDynamic(-10), equals('0s'));
    });

    test(
      'Edge Case: large duration should format into total minutes with m suffix',
      () {
        expect(formatSecondsDynamic(7200), equals('120m'));
      },
    );
  });
}
