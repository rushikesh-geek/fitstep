import 'package:firebase_database/firebase_database.dart';
import '../models/gamification_model.dart';
import '../models/daily_data_model.dart';
import 'dart:developer' as developer;

class GamificationService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Get or create gamification data
  Future<GamificationModel> getGamificationData(String uid) async {
    try {
      final snapshot = await _database.ref('users/$uid/gamification').get();
      if (snapshot.exists) {
        return GamificationModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
      return GamificationModel();
    } catch (e) {
      developer.log('Error getting gamification data: $e');
      return GamificationModel();
    }
  }

  // Update gamification based on today's achievement
  Future<GamificationModel> updateGamification(
    String uid,
    int todaySteps,
    int dailyGoal,
    Map<String, DailyDataModel> last7DaysData,
  ) async {
    try {
      final current = await getGamificationData(uid);

      // Calculate weekly steps
      int weeklySteps = 0;
      for (final data in last7DaysData.values) {
        weeklySteps += data.steps;
      }

      // Calculate daily streak
      int dailyStreak = current.dailyStreak;
      final goalAchieved = todaySteps >= dailyGoal;

      if (goalAchieved) {
        dailyStreak = current.dailyStreak + 1;
      } else if (todaySteps == 0) {
        dailyStreak = 0;
      }

      // Update longest streak
      final longestStreak =
          dailyStreak > current.longestStreak ? dailyStreak : current.longestStreak;

      // Update lifetime steps
      final lifetimeSteps = current.lifetimeSteps + todaySteps;

      // Check badges
      List<GameBadge> updatedBadges = [...current.badges];
      updatedBadges = _checkAndUnlockBadges(
        updatedBadges,
        dailyStreak,
        lifetimeSteps,
        weeklySteps,
      );

      // Calculate weekly rank
      final weeklyRank = _calculateWeeklyRank(weeklySteps);

      final updated = GamificationModel(
        dailyStreak: dailyStreak,
        longestStreak: longestStreak,
        lifetimeSteps: lifetimeSteps,
        badges: updatedBadges,
        weeklyRank: weeklyRank,
        weeklySteps: weeklySteps,
      );

      // Save to Firebase
      await _database.ref('users/$uid/gamification').set(updated.toMap());

      return updated;
    } catch (e) {
      developer.log('Error updating gamification: $e');
      return GamificationModel();
    }
  }

  // Check and unlock badges
  List<GameBadge> _checkAndUnlockBadges(
    List<GameBadge> currentBadges,
    int dailyStreak,
    int lifetimeSteps,
    int weeklySteps,
  ) {
    final allBadges = _getAllAvailableBadges();

    for (final badge in allBadges) {
      final existing = currentBadges.firstWhere(
        (b) => b.id == badge.id,
        orElse: () => badge,
      );

      bool shouldUnlock = false;

      if (badge.category == 'streak') {
        if (dailyStreak >= badge.threshold) {
          shouldUnlock = true;
        }
      } else if (badge.category == 'lifetime') {
        if (lifetimeSteps >= badge.threshold) {
          shouldUnlock = true;
        }
      } else if (badge.category == 'weekly') {
        if (weeklySteps >= badge.threshold) {
          shouldUnlock = true;
        }
      }

      if (shouldUnlock && !existing.unlocked) {
        currentBadges[currentBadges.indexOf(existing)] = badge.copyWith(
          unlocked: true,
          unlockedDate: DateTime.now(),
        );
      }
    }

    return currentBadges;
  }

  // Get all available badges
  List<GameBadge> _getAllAvailableBadges() {
    return [
      GameBadge(
        id: '1day_active',
        name: '1 Day Active',
        description: 'Complete 1 day of activity',
        icon: 'ACTIVE',
        threshold: 1,
        category: 'streak',
      ),
      GameBadge(
        id: '3day_streak',
        name: '3 Day Streak',
        description: 'Maintain 3 consecutive days',
        icon: 'STREAK',
        threshold: 3,
        category: 'streak',
      ),
      GameBadge(
        id: '7day_streak',
        name: '7 Day Streak',
        description: 'Maintain 7 consecutive days',
        icon: 'ELITE',
        threshold: 7,
        category: 'streak',
      ),
      GameBadge(
        id: '10k_day',
        name: '10k Steps Day',
        description: 'Complete 10,000 steps',
        icon: 'SILVER',
        threshold: 10000,
        category: 'weekly',
      ),
      GameBadge(
        id: '50k_lifetime',
        name: '50k Lifetime Steps',
        description: 'Reach 50,000 total steps',
        icon: 'GOLD',
        threshold: 50000,
        category: 'lifetime',
      ),
      GameBadge(
        id: '100k_lifetime',
        name: '100k Lifetime Steps',
        description: 'Reach 100,000 total steps',
        icon: 'PLATINUM',
        threshold: 100000,
        category: 'lifetime',
      ),
    ];
  }

  // Calculate weekly rank based on weekly steps
  String _calculateWeeklyRank(int weeklySteps) {
    if (weeklySteps < 20000) {
      return 'Bronze';
    } else if (weeklySteps < 40000) {
      return 'Silver';
    } else if (weeklySteps < 70000) {
      return 'Gold';
    } else {
      return 'Platinum';
    }
  }
}
