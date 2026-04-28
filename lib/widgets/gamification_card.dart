import 'package:flutter/material.dart';
import '../models/gamification_model.dart';

class GamificationCard extends StatelessWidget {
  final GamificationModel gamificationData;

  const GamificationCard({
    super.key,
    required this.gamificationData,
  });

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Platinum':
        return Colors.cyan;
      case 'Gold':
        return Colors.amber;
      case 'Silver':
        return Colors.grey;
      default:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Current Streak',
                    value: '${gamificationData.dailyStreak}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Longest Streak',
                    value: '${gamificationData.longestStreak}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Weekly Rank',
                    value: gamificationData.weeklyRank,
                    rankColor: _getRankColor(gamificationData.weeklyRank),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Lifetime Steps',
                    value: '${(gamificationData.lifetimeSteps / 1000).toStringAsFixed(1)}k',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (gamificationData.badges.isNotEmpty) ...[
              const Text(
                'Badges',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: gamificationData.badges
                    .where((b) => b.unlocked)
                    .take(6)
                    .map(
                      (badge) => Tooltip(
                        message: badge.name,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              badge.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? rankColor;

  const _StatBox({
    required this.label,
    required this.value,
    this.rankColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rankColor?.withValues(alpha: 0.1) ?? Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rankColor?.withValues(alpha: 0.3) ?? Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: rankColor ?? Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
