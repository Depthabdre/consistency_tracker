import 'package:flutter_test/flutter_test.dart';
import 'package:consistency_tracker/features/goals/domain/goal_suggestions.dart';

void main() {
  group('titleSuggestions', () {
    test('empty query returns popular templates', () {
      expect(titleSuggestions('').length, 6);
    });

    test('matches by title prefix and by keyword', () {
      expect(titleSuggestions('rea').map((t) => t.title), contains('Reading'));
      expect(titleSuggestions('gym').map((t) => t.title), contains('Exercise'));
    });

    test('hides a template the user already typed exactly', () {
      expect(
        titleSuggestions('Reading').map((t) => t.title),
        isNot(contains('Reading')),
      );
    });

    test('unrelated text yields nothing', () {
      expect(titleSuggestions('zzzz'), isEmpty);
    });
  });

  group('descriptionSuggestions', () {
    test('tailors ideas to the title', () {
      expect(
        descriptionSuggestions('Flutter side project coding'),
        contains('Build features for my side project'),
      );
      expect(
        descriptionSuggestions('Morning run'),
        contains('Follow my training plan'),
      );
    });

    test('falls back to generic ideas for unknown titles', () {
      expect(descriptionSuggestions('Gardening'), isNotEmpty);
    });

    test('empty title gives no suggestions', () {
      expect(descriptionSuggestions('  '), isEmpty);
    });
  });

  test('matchTemplate prefers an exact title', () {
    expect(matchTemplate('Study')?.title, 'Study');
    expect(matchTemplate('Read a book')?.title, 'Reading');
  });
}
