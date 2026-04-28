import 'package:flutter/material.dart';

class MotivationCard extends StatelessWidget {
  final String message;
  final int currentSteps;
  final int dailyGoal;
  final int dailyStreak;

  const MotivationCard({
    super.key,
    required this.message,
    required this.currentSteps,
    required this.dailyGoal,
    required this.dailyStreak,
  });

  Color _getStreakColor() {
    if (dailyStreak >= 7) return Colors.red;
    if (dailyStreak >= 3) return Colors.orange;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (currentSteps / dailyGoal * 100).clamp(0, 100);
    final isGoalMet = currentSteps >= dailyGoal;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isGoalMet
                ? [Colors.greenAccent, Colors.green]
                : [Colors.blueAccent, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (dailyStreak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStreakColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$dailyStreak-day streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 8,
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalMet ? Colors.white : Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progressPercent.toStringAsFixed(0)}% - $currentSteps / $dailyGoal steps',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
