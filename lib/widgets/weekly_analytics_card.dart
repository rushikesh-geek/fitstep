import 'package:flutter/material.dart';
import '../models/health_hub_item.dart';

class WeeklyAnalyticsCard extends StatelessWidget {
  final WeeklyAnalytics? analytics;

  const WeeklyAnalyticsCard({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    if (analytics == null) {
      return const SizedBox.shrink();
    }

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
              'Weekly Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InsightRow(
              label: 'Total Steps',
              value: analytics!.totalSteps.toString(),
            ),
            const SizedBox(height: 12),
            _InsightRow(
              label: 'Average Daily',
              value: analytics!.averageSteps.toString(),
            ),
            const SizedBox(height: 12),
            _InsightRow(
              label: 'Best Day',
              value: analytics!.bestDay,
            ),
            const SizedBox(height: 12),
            _InsightRow(
              label: 'Lowest Day',
              value: analytics!.lowestDay,
            ),
            const SizedBox(height: 12),
            _InsightRow(
              label: 'Goal Success',
              value: '${analytics!.goalSuccessDays}/7',
            ),
            const SizedBox(height: 12),
            _InsightRow(
              label: 'Improvement',
              value: '+${analytics!.improvementPercent}%',
              isPositive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;

  const _InsightRow({
    required this.label,
    required this.value,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}
