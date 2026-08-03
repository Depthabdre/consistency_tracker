import 'package:hive/hive.dart';
import '../models/calendar_day_model.dart';

abstract class CalendarLocalDataSource {
  Future<List<CalendarDayModel>> getCalendarEntries(String goalId);
  Future<bool> saveCalendarDay(String goalId, CalendarDayModel day);
  Future<CalendarDayModel> addFocusMinutesToToday({
    required String goalId,
    required int targetMinutes,
    required int minutesToAdd,
  });
}

class CalendarLocalDataSourceImpl implements CalendarLocalDataSource {
  static const String boxPrefix = 'calendar_box_';

  @override
  Future<List<CalendarDayModel>> getCalendarEntries(String goalId) async {
    final box = await Hive.openBox('$boxPrefix$goalId');
    final rawList = box.values.toList();
    return rawList
        .map((e) => CalendarDayModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<bool> saveCalendarDay(String goalId, CalendarDayModel day) async {
    final box = await Hive.openBox('$boxPrefix$goalId');
    final key = '${day.date.year}-${day.date.month}-${day.date.day}';
    await box.put(key, day.toJson());
    return true;
  }

  @override
  Future<CalendarDayModel> addFocusMinutesToToday({
    required String goalId,
    required int targetMinutes,
    required int minutesToAdd,
  }) async {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    final box = await Hive.openBox('$boxPrefix$goalId');

    final raw = box.get(key);
    int existingMinutes = 0;
    if (raw != null) {
      final existingDay =
          CalendarDayModel.fromJson(Map<String, dynamic>.from(raw as Map));
      existingMinutes = existingDay.totalMinutesFocused;
    }

    final newTotalMinutes = existingMinutes + minutesToAdd;
    final isTargetMet = newTotalMinutes >= targetMinutes;

    final updatedDay = CalendarDayModel(
      date: DateTime(today.year, today.month, today.day),
      totalMinutesFocused: newTotalMinutes,
      targetMinutes: targetMinutes,
      isCompleted: isTargetMet,
    );

    await box.put(key, updatedDay.toJson());
    return updatedDay;
  }
}
