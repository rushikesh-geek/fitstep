import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/daily_data_model.dart';

class RealtimeDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Save user data
  Future<void> saveUserData(String uid, UserModel userModel) async {
    try {
      await _database.ref('users/$uid').set(userModel.toMap());
    } catch (e) {
      throw 'Failed to save user data: $e';
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final snapshot = await _database.ref('users/$uid').get();
      if (snapshot.exists) {
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        return UserModel.fromMap(map);
      }
      return null;
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  // Save daily data for specific date
  Future<void> saveDailyData(
    String uid,
    String date, // Format: yyyy-mm-dd
    DailyDataModel dailyDataModel,
  ) async {
    try {
      await _database
          .ref('users/$uid/daily/$date')
          .set(dailyDataModel.toMap());
    } catch (e) {
      throw 'Failed to save daily data: $e';
    }
  }

  // Get daily data for specific date
  Future<DailyDataModel?> getDailyData(String uid, String date) async {
    try {
      final snapshot = await _database.ref('users/$uid/daily/$date').get();
      if (snapshot.exists) {
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        return DailyDataModel.fromMap(map);
      }
      return null;
    } catch (e) {
      throw 'Failed to get daily data: $e';
    }
  }

  // Get last 7 days of data (returns exactly 7 days, with empty values for missing dates)
  Future<Map<String, DailyDataModel>> getLast7DaysData(String uid) async {
    try {
      final result = <String, DailyDataModel>{};

      // Generate last 7 days (today - 6 days back)
      final today = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dateString =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        try {
          final snapshot =
              await _database.ref('users/$uid/daily/$dateString').get();
          if (snapshot.exists) {
            final map = Map<String, dynamic>.from(snapshot.value as Map);
            result[dateString] = DailyDataModel.fromMap(map);
          } else {
            // Missing date: return empty DailyDataModel with 0 values
            result[dateString] = DailyDataModel.empty();
          }
        } catch (e) {
          // On error, still add empty data for that date
          result[dateString] = DailyDataModel.empty();
        }
      }

      return result;
    } catch (e) {
      throw 'Failed to get last 7 days data: $e';
    }
  }
}
