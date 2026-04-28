import 'package:flutter/material.dart';

class DynamicGoalCard extends StatelessWidget {
  final int currentSteps;
  final int dailyGoal;
  final bool isGoalAchieved;

  const DynamicGoalCard({
    super.key,
    required this.currentSteps,
    required this.dailyGoal,
    required this.isGoalAchieved,
  });

  @override
  Widget build(BuildContext context) {
    final stepsRemaining = (dailyGoal - currentSteps).clamp(0, dailyGoal);
    final progressPercent = (currentSteps / dailyGoal * 100).clamp(0, 100);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isGoalAchieved
                ? [Colors.greenAccent.shade100, Colors.green.shade100]
                : [Colors.blueAccent.shade100, Colors.blue.shade100],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Goal",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isGoalAchieved
                        ? Colors.green.shade600
                        : Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isGoalAchieved ? '✓ Goal Met' : 'In Progress',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$dailyGoal',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isGoalAchieved
                    ? Colors.green.shade700
                    : Colors.blue.shade700,
              ),
            ),
            const Text(
              'steps',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 6,
                backgroundColor: Colors.white54,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalAchieved ? Colors.green.shade600 : Colors.blue.shade600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentSteps steps',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isGoalAchieved
                      ? '+$stepsRemaining bonus!'
                      : '$stepsRemaining to go',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isGoalAchieved ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Personalized goal, updated based on your weekly progress',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
