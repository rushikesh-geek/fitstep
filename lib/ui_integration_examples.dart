import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/gamification_viewmodel.dart';
import 'widgets/motivation_card.dart';
import 'widgets/dynamic_goal_card.dart';
import 'widgets/weekly_analytics_card.dart';
import 'widgets/gamification_card.dart';

/// Example integration of new dynamic features into home screen.
/// 
/// This widget demonstrates how to integrate all 6 new features
/// (motivation, dynamic goals, analytics, and gamification) into your
/// existing home screen using the Provider pattern.
class HomeScreenExample extends StatefulWidget {
  const HomeScreenExample({super.key});

  @override
  State<HomeScreenExample> createState() => _HomeScreenExampleState();
}

class _HomeScreenExampleState extends State<HomeScreenExample> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Load initial data from ViewModels
  Future<void> _loadInitialData() async {
    if (!mounted) return;

    // Note: In your actual implementation, get the current UID from your auth service
    // and pass it to loadGamificationData. Example:
    // final gamificationVM = context.read<GamificationViewModel>();
    // final authVM = context.read<AuthViewModel>();
    // if (authVM.currentUser != null) {
    //   await gamificationVM.loadGamificationData(authVM.currentUser!.uid);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitStep'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer2<HomeViewModel, GamificationViewModel>(
        builder: (context, homeVM, gamificationVM, _) {
          // Show loading indicator while data is loading
          if (homeVM.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show error message if something went wrong
          if (homeVM.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${homeVM.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. MOTIVATION CARD - Displays motivational message with streak indicator
                MotivationCard(
                  message: homeVM.motivationalMessage,
                  currentSteps: homeVM.steps,
                  dailyGoal: homeVM.dynamicGoal,
                  dailyStreak: gamificationVM.dailyStreak,
                ),

                // 2. DYNAMIC GOAL CARD - Shows today's smart personalized goal
                DynamicGoalCard(
                  currentSteps: homeVM.steps,
                  dailyGoal: homeVM.dynamicGoal,
                  isGoalAchieved: homeVM.steps >= homeVM.dynamicGoal,
                ),

                // 3. EXISTING METRICS SECTION - Keep your existing code here
                // (Distance, Calories, Water, Sleep cards)
                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Metrics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MetricDisplay(
                              label: 'Distance',
                              value: '${homeVM.distance.toStringAsFixed(2)} km',
                            ),
                            _MetricDisplay(
                              label: 'Calories',
                              value: '${homeVM.calories} kcal',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MetricDisplay(
                              label: 'Water',
                              value: '${homeVM.water} ml',
                            ),
                            _MetricDisplay(
                              label: 'Sleep',
                              value: '${homeVM.sleep} hrs',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. WEEKLY GRAPH - Insert your existing fl_chart code here
                // Example structure (replace with your actual BarChart):
                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly Steps',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Replace with your existing fl_chart BarChart widget
                        Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Text(
                            'Insert your fl_chart BarChart here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. WEEKLY ANALYTICS CARD - New insights card
                WeeklyAnalyticsCard(
                  analytics: homeVM.weeklyAnalytics,
                ),

                // 6. GAMIFICATION CARD - Streaks, ranks, and badges
                GamificationCard(
                  gamificationData: gamificationVM.gamificationData,
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Helper widget for displaying individual metrics with value and label.
class _MetricDisplay extends StatelessWidget {
  final String label;
  final String value;

  const _MetricDisplay({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ============================================
// PROFILE SCREEN EXAMPLE
// ============================================
// To display gamification stats on profile screen:
//
// Consumer<GamificationViewModel>(
//   builder: (context, gamVM, _) {
//     return Column(
//       children: [
//         Text('Streak: ${gamVM.dailyStreak} days'),
//         Text('Best Streak: ${gamVM.longestStreak} days'),
//         Text('Rank: ${gamVM.weeklyRank}'),
//         Text('Lifetime Steps: ${gamVM.lifetimeSteps}'),
//         // Display badges...
//       ],
//     );
//   },
// );

// ============================================
// HEALTH HUB SCREEN EXAMPLE
// ============================================
// To display prioritized health content:
//
// Consumer<HealthHubViewModel>(
//   builder: (context, healthVM, _) {
//     if (healthVM.prioritizedItems.isEmpty) {
//       return const Center(child: Text('No content available'));
//     }
//     return ListView.builder(
//       itemCount: healthVM.prioritizedItems.length,
//       itemBuilder: (context, index) {
//         final item = healthVM.prioritizedItems[index];
//         return Card(
//           child: ListTile(
//             title: Text(item.title),
//             subtitle: Text(item.description),
//             onTap: () {
//               // Launch video URL with url_launcher
//               if (item.videoUrl != null) {
//                 launchUrl(Uri.parse(item.videoUrl!));
//               }
//             },
//           ),
//         );
//       },
//     );
//   },
// );
