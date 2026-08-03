import 'package:hive/hive.dart';
import '../models/calendar_day_model.dart';

abstract class CalendarLocalDataSource {
  Future<List<CalendarDayModel>> getCalendarEntries(String goalId);
  Future<bool> saveCalendarDay(String goalId, CalendarDayModel day);
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
}
