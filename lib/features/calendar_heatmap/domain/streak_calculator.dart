import '../data/models/calendar_day_model.dart';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);

DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Set<DateTime> _completedDays(Iterable<CalendarDayModel> entries) => {
  for (final e in entries)
    if (e.isCompleted) dayOnly(e.date),
};

/// A rest day is outside [activeWeekdays]; it neither breaks nor extends a
/// streak unless it was completed anyway.
bool _isRest(DateTime day, Iterable<int>? activeWeekdays) =>
    activeWeekdays != null && !activeWeekdays.contains(day.weekday);

/// Consecutive completed days ending today (or yesterday, if today is
/// still in progress). A missed scheduled day breaks the streak.
int calculateCurrentStreak(
  Iterable<CalendarDayModel> entries, {
  DateTime? now,
  Iterable<int>? activeWeekdays,
}) {
  final done = _completedDays(entries);
  if (done.isEmpty) return 0;
  final earliest = done.reduce((a, b) => a.isBefore(b) ? a : b);

  var cursor = dayOnly(now ?? DateTime.now());
  if (!done.contains(cursor)) cursor = _previousDay(cursor);

  var streak = 0;
  while (!cursor.isBefore(earliest)) {
    if (done.contains(cursor)) {
      streak++;
    } else if (!_isRest(cursor, activeWeekdays)) {
      break;
    }
    cursor = _previousDay(cursor);
  }
  return streak;
}

/// Longest run of completed days ever recorded, skipping rest days.
int calculateLongestStreak(
  Iterable<CalendarDayModel> entries, {
  Iterable<int>? activeWeekdays,
}) {
  final days = _completedDays(entries).toList()..sort();
  if (days.isEmpty) return 0;

  var best = 0;
  var run = 0;
  for (var d = days.first; !d.isAfter(days.last); d = _nextDay(d)) {
    if (days.contains(d)) {
      run++;
      if (run > best) best = run;
    } else if (!_isRest(d, activeWeekdays)) {
      run = 0;
    }
  }
  return best;
}

/// Completed vs eligible days over the last [windowDays] days (only counting
/// days on or after [startDate]). Today only counts once it is completed, and
/// rest days only count when completed.
({int met, int eligible}) calculateConsistency(
  Iterable<CalendarDayModel> entries, {
  required DateTime startDate,
  DateTime? now,
  int windowDays = 30,
  Iterable<int>? activeWeekdays,
}) {
  final today = dayOnly(now ?? DateTime.now());
  final start = dayOnly(startDate);
  final done = _completedDays(entries);

  var eligible = 0;
  var met = 0;
  for (var i = 0; i < windowDays; i++) {
    final day = DateTime(today.year, today.month, today.day - i);
    if (day.isBefore(start)) break;
    final completed = done.contains(day);
    if (!completed && (i == 0 || _isRest(day, activeWeekdays))) continue;
    eligible++;
    if (completed) met++;
  }
  return (met: met, eligible: eligible);
}
