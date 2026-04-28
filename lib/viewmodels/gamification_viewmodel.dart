import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../services/gamification_service.dart';
import '../models/gamification_model.dart';
import '../models/daily_data_model.dart';

class GamificationViewModel extends ChangeNotifier {
  final GamificationService _gamificationService = GamificationService();

  GamificationModel _gamificationData = GamificationModel();
  bool _isLoading = false;

  GamificationModel get gamificationData => _gamificationData;
  bool get isLoading => _isLoading;

  int get dailyStreak => _gamificationData.dailyStreak;
  int get longestStreak => _gamificationData.longestStreak;
  int get lifetimeSteps => _gamificationData.lifetimeSteps;
  List<GameBadge> get badges => _gamificationData.badges;
  String get weeklyRank => _gamificationData.weeklyRank;
  int get weeklySteps => _gamificationData.weeklySteps;

  List<GameBadge> get unlockedBadges =>
      badges.where((b) => b.unlocked).toList();

  List<GameBadge> get lockedBadges =>
      badges.where((b) => !b.unlocked).toList();

  Future<void> loadGamificationData(String uid) async {
    developer.log('[GamificationViewModel] Loading gamification data');
    _isLoading = true;
    notifyListeners();

    try {
      _gamificationData =
          await _gamificationService.getGamificationData(uid);
      developer.log(
        '[GamificationViewModel] Loaded: ${_gamificationData.dailyStreak} streak, ${_gamificationData.badges.length} badges',
      );
    } catch (e) {
      developer.log('[GamificationViewModel] Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGamification(
    String uid,
    int todaySteps,
    int dailyGoal,
    Map<String, DailyDataModel> last7DaysData,
  ) async {
    developer.log('[GamificationViewModel] Updating gamification');
    try {
      _gamificationData = await _gamificationService.updateGamification(
        uid,
        todaySteps,
        dailyGoal,
        last7DaysData,
      );
      notifyListeners();
    } catch (e) {
      developer.log('[GamificationViewModel] Error updating: $e');
    }
  }
}
