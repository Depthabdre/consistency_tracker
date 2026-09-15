import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/analytics/presentation/widgets/weekly_focus_chart.dart';

void main() {
  group('WeeklyFocusChart Tests', () {
    testWidgets('renders weekly focus distribution and 7 weekday columns', (
      tester,
    ) async {
      final weekdayMinutes = {
        1: 30, // Monday
        2: 45, // Tuesday
        3: 60, // Wednesday
        4: 0,
        5: 25,
        6: 0,
        7: 15,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyFocusChart(weekdayMinutes: weekdayMinutes),
          ),
        ),
      );

      expect(find.text('Weekly Focus Distribution'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
      expect(find.text('60m'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);

      // Verify day letters
      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });
  });
}
