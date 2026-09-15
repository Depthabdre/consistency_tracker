import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/calendar_heatmap/data/models/calendar_day_model.dart';
import 'package:consistency_tracker/features/calendar_heatmap/presentation/reusable_widgets/day_detail_bottom_sheet.dart';

void main() {
  group('DayDetailBottomSheet Widget Tests', () {
    testWidgets(
      'renders verified focus minutes, target minutes, and completed status badge',
      (tester) async {
        final day = CalendarDayModel(
          date: DateTime(2026, 9, 15),
          totalMinutesFocused: 45,
          targetMinutes: 45,
          isCompleted: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DayDetailBottomSheet(
                day: day,
                goalTitle: 'Daily Flutter Focus',
                goalStartDate: DateTime(2026, 9, 1),
              ),
            ),
          ),
        );

        // Verify Goal Title & Metrics
        expect(find.text('Daily Flutter Focus'), findsOneWidget);
        expect(find.text('Target Completed'), findsOneWidget);
        expect(find.text('45 / 45 mins'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(find.textContaining('Proof-of-work'), findsOneWidget);

        // Verify no cheat / manual mutation buttons exist
        expect(find.text('Mark Completed'), findsNothing);
        expect(find.text('+15m'), findsNothing);
        expect(find.text('+30m'), findsNothing);
      },
    );

    testWidgets('renders missed target status for uncompleted past days', (
      tester,
    ) async {
      final pastDay = CalendarDayModel(
        date: DateTime(2026, 1, 5),
        totalMinutesFocused: 10,
        targetMinutes: 30,
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayDetailBottomSheet(
              day: pastDay,
              goalTitle: 'Reading Habit',
              goalStartDate: DateTime(2026, 1, 1),
            ),
          ),
        ),
      );

      expect(find.text('Missed Target'), findsOneWidget);
      expect(find.text('10 / 30 mins'), findsOneWidget);
    });
  });
}
