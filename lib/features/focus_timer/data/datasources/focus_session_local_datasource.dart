import 'package:hive/hive.dart';
import '../models/focus_session_model.dart';

abstract class FocusSessionLocalDataSource {
  Future<List<FocusSessionModel>> getSessionsForGoal(String goalId);
  Future<bool> saveSession(FocusSessionModel session);
}

class FocusSessionLocalDataSourceImpl implements FocusSessionLocalDataSource {
  static const String boxName = 'focus_sessions_box';

  @override
  Future<List<FocusSessionModel>> getSessionsForGoal(String goalId) async {
    final box = await Hive.openBox(boxName);
    final rawList = box.values.toList();
    return rawList
        .map((e) => FocusSessionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((s) => s.goalId == goalId)
        .toList();
  }

  @override
  Future<bool> saveSession(FocusSessionModel session) async {
    final box = await Hive.openBox(boxName);
    await box.put(session.id, session.toJson());
    return true;
  }
}
