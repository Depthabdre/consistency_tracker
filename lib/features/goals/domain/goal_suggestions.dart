class GoalTemplate {
  const GoalTemplate({
    required this.title,
    required this.minutes,
    required this.keywords,
    required this.descriptions,
  });

  final String title;
  final int minutes;
  final List<String> keywords;
  final List<String> descriptions;
}

const List<GoalTemplate> goalTemplates = [
  GoalTemplate(
    title: 'Deep work',
    minutes: 90,
    keywords: ['deep', 'work', 'focus', 'project', 'job', 'business'],
    descriptions: [
      'Uninterrupted time on my most important project',
      'Ship one meaningful piece of work every day',
      'No email or chat during this block',
    ],
  ),
  GoalTemplate(
    title: 'Reading',
    minutes: 20,
    keywords: ['read', 'book', 'novel', 'pages', 'kindle'],
    descriptions: [
      'Read at least 10 pages',
      'Finish one book every month',
      'Read before bed instead of scrolling',
    ],
  ),
  GoalTemplate(
    title: 'Coding practice',
    minutes: 45,
    keywords: [
      'code',
      'coding',
      'program',
      'dev',
      'flutter',
      'dart',
      'leetcode',
      'algorithm',
      'software',
      'app',
      'build',
      'python',
      'javascript',
    ],
    descriptions: [
      'Build features for my side project',
      'Solve one algorithm problem',
      'Learn something new in my stack',
    ],
  ),
  GoalTemplate(
    title: 'Exercise',
    minutes: 30,
    keywords: [
      'exercise',
      'workout',
      'gym',
      'run',
      'fitness',
      'walk',
      'yoga',
      'train',
      'cardio',
      'strength',
      'sport',
    ],
    descriptions: [
      'Move my body and get my heart rate up',
      'Follow my training plan',
      'Stretch and stay mobile',
    ],
  ),
  GoalTemplate(
    title: 'Meditation',
    minutes: 10,
    keywords: ['meditat', 'mindful', 'breath', 'calm', 'relax', 'stress'],
    descriptions: [
      'Sit quietly and focus on my breathing',
      'Start the day calm and clear',
      'A guided session with my phone away',
    ],
  ),
  GoalTemplate(
    title: 'Writing',
    minutes: 30,
    keywords: ['write', 'writing', 'journal', 'blog', 'essay', 'story'],
    descriptions: [
      'Write 300 words, no editing',
      'Journal about the day',
      'Draft my next article',
    ],
  ),
  GoalTemplate(
    title: 'Language learning',
    minutes: 20,
    keywords: [
      'language',
      'spanish',
      'french',
      'german',
      'english',
      'arabic',
      'japanese',
      'chinese',
      'italian',
      'vocab',
      'duolingo',
    ],
    descriptions: [
      'Practice vocabulary and listening',
      'Complete today’s lesson',
      'Have one short conversation',
    ],
  ),
  GoalTemplate(
    title: 'Study',
    minutes: 60,
    keywords: [
      'study',
      'exam',
      'course',
      'class',
      'homework',
      'learn',
      'revision',
      'school',
      'university',
    ],
    descriptions: [
      'Review notes and do practice questions',
      'Work through one chapter or module',
      'Prepare steadily for my exam',
    ],
  ),
  GoalTemplate(
    title: 'Music practice',
    minutes: 30,
    keywords: [
      'music',
      'guitar',
      'piano',
      'sing',
      'violin',
      'drum',
      'instrument',
      'practice',
    ],
    descriptions: [
      'Practice scales and technique',
      'Learn a new piece section by section',
      'Play through my repertoire',
    ],
  ),
  GoalTemplate(
    title: 'Design',
    minutes: 45,
    keywords: ['design', 'draw', 'sketch', 'art', 'paint', 'ui', 'ux', 'figma'],
    descriptions: [
      'Sketch or design something new',
      'Study and recreate great work',
      'Build my portfolio one piece at a time',
    ],
  ),
];

const List<String> _genericDescriptions = [
  'Show up every day, even for a few minutes',
  'Steady progress over perfect progress',
  'Protect time for what matters to me',
];

/// Title templates matching [query] (by title or keyword). An empty query
/// returns the most common templates.
List<GoalTemplate> titleSuggestions(String query, {int limit = 6}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return goalTemplates.take(limit).toList();
  final matches = goalTemplates.where((t) {
    final title = t.title.toLowerCase();
    if (title == q) return false;
    return title.contains(q) ||
        t.keywords.any((k) => k.startsWith(q) || q.contains(k));
  });
  return matches.take(limit).toList();
}

/// The template that best fits a free-form title, if any.
GoalTemplate? matchTemplate(String title) {
  final t = title.trim().toLowerCase();
  if (t.isEmpty) return null;
  GoalTemplate? best;
  var bestScore = 0;
  for (final template in goalTemplates) {
    var score = template.title.toLowerCase() == t ? 10 : 0;
    for (final k in template.keywords) {
      if (t.contains(k)) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      best = template;
    }
  }
  return best;
}

/// Description ideas tailored to [title]; generic ones when nothing matches.
List<String> descriptionSuggestions(String title) {
  if (title.trim().isEmpty) return const [];
  return matchTemplate(title)?.descriptions ?? _genericDescriptions;
}
