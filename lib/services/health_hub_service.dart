import 'package:firebase_database/firebase_database.dart';
import '../models/health_hub_item.dart';
import '../models/daily_data_model.dart';

class HealthHubService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Fetch all health hub content from Firebase
  Future<List<HealthHubItem>> fetchHealthHubContent() async {
    try {
      final List<HealthHubItem> allItems = [];
      final categories = ['fitness', 'hydration', 'sleep', 'nutrition', 'weight'];

      for (final category in categories) {
        try {
          final snapshot =
              await _database.ref('healthHub/$category').get();
          if (snapshot.exists) {
            final data = Map<String, dynamic>.from(snapshot.value as Map);
            data.forEach((key, value) {
              if (value is Map) {
                final item = HealthHubItem.fromMap(
                  key,
                  Map<String, dynamic>.from(value),
                );
                allItems.add(item);
              }
            });
          }
        } catch (e) {
          // Continue if a category fails
        }
      }

      return allItems;
    } catch (e) {
      throw 'Failed to fetch health hub content: $e';
    }
  }

  // Prioritize health hub content based on user data
  List<HealthHubItem> prioritizeContent(
    List<HealthHubItem> items,
    Map<String, DailyDataModel> last7DaysData,
    double userBmi,
  ) {
    final priorityMap = <String, int>{};
    int baseScore = 0;

    // Calculate sleep average
    int sleepTotal = 0;
    for (final data in last7DaysData.values) {
      sleepTotal += data.sleep;
    }
    final avgSleep = last7DaysData.isNotEmpty ? sleepTotal ~/ last7DaysData.length : 0;

    // Calculate water average
    int waterTotal = 0;
    for (final data in last7DaysData.values) {
      waterTotal += data.water;
    }
    final avgWater =
        last7DaysData.isNotEmpty ? waterTotal ~/ last7DaysData.length : 0;

    // Calculate steps average
    int stepsTotal = 0;
    for (final data in last7DaysData.values) {
      stepsTotal += data.steps;
    }
    final avgSteps =
        last7DaysData.isNotEmpty ? stepsTotal ~/ last7DaysData.length : 0;

    // Score items based on user needs
    for (final item in items) {
      baseScore = item.priority;

      if (avgSleep < 6 && item.category == 'sleep') {
        baseScore += 500;
      }

      if (userBmi > 25 && item.category == 'weight') {
        baseScore += 400;
      }

      if (avgWater < 2000 && item.category == 'hydration') {
        baseScore += 300;
      }

      if (avgSteps < 8000 && item.category == 'fitness') {
        baseScore += 200;
      }

      priorityMap[item.id] = baseScore;
    }

    // Sort by priority
    items.sort((a, b) => (priorityMap[b.id] ?? 0).compareTo(priorityMap[a.id] ?? 0));
    return items;
  }
}
