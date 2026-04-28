import '../models/daily_data_model.dart';

class MotivationService {
  String getMotivationalMessage(
    int currentSteps,
    int dailyGoal,
    Map<String, DailyDataModel> last7DaysData,
  ) {
    final now = DateTime.now();
    final hour = now.hour;

    if (currentSteps >= dailyGoal) {
      return 'Excellent! You\'ve achieved today\'s goal.';
    }

    if (currentSteps == 0) {
      return 'Start your day: Get moving with a 10-minute walk.';
    }

    final stepsRemaining = dailyGoal - currentSteps;
    final percentComplete = (currentSteps / dailyGoal * 100).toInt();

    if (hour >= 5 && hour < 11) {
      return 'Great start to your day. Continue with a morning walk.';
    } else if (hour >= 11 && hour < 17) {
      return 'You are $percentComplete% toward today\'s goal. Keep going!';
    } else if (hour >= 17 && hour < 22) {
      return 'Final push: Only $stepsRemaining steps left to reach your target.';
    } else {
      return 'Great effort today. Time to rest and recover.';
    }
  }

  String getDailyStreakMessage(int streak) {
    if (streak == 1) {
      return 'Great start! 1 day of consistency.';
    } else if (streak == 3) {
      return '$streak-day streak! Momentum is building.';
    } else if (streak == 7) {
      return '$streak-day streak! Amazing consistency.';
    } else if (streak == 14) {
      return '$streak-day streak! Outstanding dedication.';
    } else if (streak == 30) {
      return '$streak-day streak! Exceptional commitment.';
    } else if (streak > 0) {
      return '$streak-day streak. Maintain your momentum!';
    }
    return 'Start your streak today!';
  }
}
