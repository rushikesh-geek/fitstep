import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../services/health_hub_service.dart';
import '../models/health_hub_item.dart';
import '../models/daily_data_model.dart';
import '../models/user_model.dart';

class HealthHubViewModel extends ChangeNotifier {
  final HealthHubService _healthHubService = HealthHubService();

  List<HealthHubItem> _allItems = [];
  List<HealthHubItem> _prioritizedItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HealthHubItem> get allItems => _allItems;
  List<HealthHubItem> get prioritizedItems => _prioritizedItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadHealthHubContent(
    Map<String, DailyDataModel> last7DaysData,
    UserModel? userModel,
  ) async {
    developer.log('[HealthHubViewModel] Loading health hub content');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allItems = await _healthHubService.fetchHealthHubContent();

      if (_allItems.isEmpty) {
        _allItems = _getLocalFallbackContent();
        developer.log('[HealthHubViewModel] Using local fallback content');
      }

      final userBmi = userModel?.bmi ?? 22.0;
      _prioritizedItems = _healthHubService.prioritizeContent(
        _allItems,
        last7DaysData,
        userBmi,
      );

      developer.log('[HealthHubViewModel] Loaded ${_allItems.length} items');
    } catch (e) {
      developer.log('[HealthHubViewModel] Error loading content: $e');
      _errorMessage = 'Failed to load health content';
      _allItems = _getLocalFallbackContent();
      _prioritizedItems = _allItems;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<HealthHubItem> _getLocalFallbackContent() {
    return [
      HealthHubItem(
        id: 'fitness_1',
        title: 'How To Build A Daily Walking Habit',
        category: 'fitness',
        description:
            'Walking is one of the simplest forms of exercise. Aim for 10,000 steps daily.',
        videoUrl: 'https://www.youtube.com/watch?v=-3N2sUkdf-Y',
        level: 'Beginner',
        tags: ['walking', 'cardio', 'beginner'],
        priority: 10,
      ),
      HealthHubItem(
        id: 'fitness_2',
        title: 'HIIT Workouts - Benefits and How to Do It',
        category: 'fitness',
        description:
            'HIIT workouts boost metabolism and improve endurance. Short bursts of intense activity.',
        videoUrl: 'https://www.youtube.com/watch?v=dNJ2gG-Jud4',
        level: 'Intermediate',
        tags: ['hiit', 'workout', 'cardio'],
        priority: 8,
      ),
      HealthHubItem(
        id: 'hydration_1',
        title: 'Importance of Hydration',
        category: 'hydration',
        description:
            'Drink at least 8 glasses of water daily. Proper hydration improves performance.',
        videoUrl: 'https://www.youtube.com/watch?v=-slnr4TGA4Y',
        level: 'Beginner',
        tags: ['water', 'hydration', 'health'],
        priority: 7,
      ),
      HealthHubItem(
        id: 'sleep_1',
        title: 'Sleep Hygiene Tips',
        category: 'sleep',
        description:
            'Maintain a consistent sleep schedule. Create a dark, cool, quiet bedroom.',
        videoUrl: 'https://www.youtube.com/watch?v=ACmUi-6xkTM',
        level: 'Beginner',
        tags: ['sleep', 'rest', 'health'],
        priority: 6,
      ),
      HealthHubItem(
        id: 'nutrition_1',
        title: 'A Balanced Diet Guide',
        category: 'nutrition',
        description:
            'A balanced diet includes proteins, carbs, fats, vitamins, and minerals.',
        videoUrl: 'https://www.youtube.com/watch?v=81G22t2UHxA',
        level: 'Beginner',
        tags: ['nutrition', 'diet', 'health'],
        priority: 5,
      ),
      HealthHubItem(
        id: 'weight_1',
        title: 'Healthy Weight Management',
        category: 'weight',
        description:
            'Maintain a healthy weight through balanced diet and regular exercise.',
        videoUrl: 'https://www.youtube.com/watch?v=EwlYYJXCmTE',
        level: 'Intermediate',
        tags: ['weight', 'fitness', 'nutrition'],
        priority: 4,
      ),
    ];
  }
}
