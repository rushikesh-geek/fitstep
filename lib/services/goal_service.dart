import 'package:firebase_database/firebase_database.dart';
import '../models/daily_data_model.dart';

class GoalService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Compute smart daily goal based on last 7 days average
  int computeSmartGoal(
    Map<String, DailyDataModel> last7DaysData,
    int lastSavedGoal,
  ) {
    if (last7DaysData.isEmpty) {
      return lastSavedGoal;
    }

    // Calculate average steps from last 7 days
    int totalSteps = 0;
    int daysWithData = 0;
    for (final data in last7DaysData.values) {
      if (data.steps > 0) {
        totalSteps += data.steps;
        daysWithData++;
      }
    }

    final avgSteps = daysWithData > 0 ? totalSteps ~/ daysWithData : 0;

    // Compute goal based on average
    int newGoal = avgSteps;
    if (avgSteps < 3000) {
      newGoal = avgSteps + 500;
    } else if (avgSteps <= 7000) {
      newGoal = avgSteps + 750;
    } else {
      newGoal = avgSteps + 1000;
    }

    // Check if user achieved goal in 5 of last 7 days
    int goalSuccessDays = 0;
    for (final data in last7DaysData.values) {
      if (data.steps >= lastSavedGoal) {
        goalSuccessDays++;
      }
    }

    if (goalSuccessDays >= 5) {
      newGoal += 500;
    } else if (goalSuccessDays <= 2) {
      newGoal = (newGoal - 300).clamp(3000, double.infinity).toInt();
    }

    // Round to nearest 100
    newGoal = ((newGoal + 50) ~/ 100) * 100;

    return newGoal;
  }

  // Save updated goal to Firebase
  Future<void> saveDynamicGoal(String uid, int goal) async {
    try {
      await _database.ref('users/$uid/dynamicGoal/goal').set(goal);
      await _database
          .ref('users/$uid/dynamicGoal/lastUpdated')
          .set(DateTime.now().toIso8601String());
    } catch (e) {
      throw 'Failed to save dynamic goal: $e';
    }
  }

  // Get last dynamic goal from Firebase
  Future<int?> getDynamicGoal(String uid) async {
    try {
      final snapshot = await _database.ref('users/$uid/dynamicGoal/goal').get();
      if (snapshot.exists) {
        return snapshot.value as int?;
      }
      return null;
    } catch (e) {
      throw 'Failed to get dynamic goal: $e';
    }
  }
}
