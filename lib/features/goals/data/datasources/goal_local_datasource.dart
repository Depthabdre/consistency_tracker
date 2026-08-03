import 'package:hive/hive.dart';
import '../models/goal_model.dart';

abstract class GoalLocalDataSource {
  Future<List<GoalModel>> getGoals();
  Future<bool> saveGoal(GoalModel goal);
  Future<bool> deleteGoal(String id);
}

class GoalLocalDataSourceImpl implements GoalLocalDataSource {
  static const String boxName = 'goals_box';

  @override
  Future<List<GoalModel>> getGoals() async {
    final box = await Hive.openBox(boxName);
    final rawData = box.values.toList();
    return rawData.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return GoalModel.fromJson(map);
    }).toList();
  }

  @override
  Future<bool> saveGoal(GoalModel goal) async {
    final box = await Hive.openBox(boxName);
    await box.put(goal.id, goal.toJson());
    return true;
  }

  @override
  Future<bool> deleteGoal(String id) async {
    final box = await Hive.openBox(boxName);
    await box.delete(id);
    return true;
  }
}
