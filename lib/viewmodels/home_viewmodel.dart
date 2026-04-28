import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../services/realtime_db_service.dart';
import '../services/step_tracking_service.dart';
import '../services/goal_service.dart';
import '../services/motivation_service.dart';
import '../services/gamification_service.dart';
import '../services/health_hub_service.dart';
import '../models/user_model.dart';
import '../models/daily_data_model.dart';
import '../models/health_hub_item.dart';
import '../models/gamification_model.dart';

class HomeViewModel extends ChangeNotifier {
  final RealtimeDBService _dbService = RealtimeDBService();
  late StepTrackingService _stepTrackingService;
  final GoalService _goalService = GoalService();
  final MotivationService _motivationService = MotivationService();
  final GamificationService _gamificationService = GamificationService();
  final HealthHubService _healthHubService = HealthHubService();

  // Step tracking subscriptions
  StreamSubscription<int>? _stepsSubscription;

  // Current user ID (needed to save steps to DB)
  String? _currentUid;
  
  // 🔒 CRITICAL: Flag to prevent DB writes during logout
  bool _isLoggingOut = false;

  // Daily metrics
  int _steps = 0;
  int _water = 0;
  int _sleep = 0;
  int _calories = 0;
  double _distance = 0.0;

  // User data (for calculations)
  UserModel? _userModel;

  // 7-day data for weekly graph
  Map<String, DailyDataModel> _last7DaysData = {};

  // Dynamic goals and motivation
  int _dynamicGoal = 8000;
  String _motivationalMessage = '';
  GamificationModel _gamificationData = GamificationModel();
  WeeklyAnalytics? _weeklyAnalytics;
  List<HealthHubItem> _prioritizedHealthContent = [];

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  // Constructor
  HomeViewModel() {
    _stepTrackingService = StepTrackingService();
  }

  // Getters
  int get steps => _steps;
  int get water => _water;
  int get sleep => _sleep;
  int get calories => _calories;
  double get distance => _distance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, DailyDataModel> get last7DaysData => _last7DaysData;
  int get dynamicGoal => _dynamicGoal;
  String get motivationalMessage => _motivationalMessage;
  GamificationModel get gamificationData => _gamificationData;
  WeeklyAnalytics? get weeklyAnalytics => _weeklyAnalytics;
  List<HealthHubItem> get prioritizedHealthContent => _prioritizedHealthContent;

  // Get sorted date keys (oldest to newest)
  List<String> get sortedLast7DaysDates {
    return _last7DaysData.keys.toList()..sort();
  }

  // Get day labels for each date (Mon, Tue, etc.)
  List<String> get last7DayLabels {
    return sortedLast7DaysDates.map((dateString) {
      try {
        final date = DateTime.parse(dateString);
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return dayNames[date.weekday - 1];
      } catch (e) {
        return '?';
      }
    }).toList();
  }

  // Get maximum steps for Y-axis scaling
  double get last7DaysMaxSteps {
    if (_last7DaysData.isEmpty) return 1000.0;
    final maxSteps =
        _last7DaysData.values.map((data) => data.steps).reduce((a, b) => a > b ? a : b);
    // If all steps are 0, set maxY to 1000 to avoid flat graph
    if (maxSteps == 0) return 1000.0;
    return (maxSteps * 1.2).toDouble(); // Add 20% padding
  }

  // Get bar steps for chart (sorted by date)
  List<int> get last7DaysSteps {
    return sortedLast7DaysDates
        .map((dateString) => _last7DaysData[dateString]?.steps ?? 0)
        .toList();
  }

  // Start step tracking from pedometer (sensor is primary data source)
  // CRITICAL: Save steps to DB every time they update from sensor
  Future<void> _startStepTracking(String uid) async {
    try {
      developer.log('[HomeViewModel] Starting step tracking for UID: $uid');
      _currentUid = uid;
      _isLoggingOut = false;  // ✅ RESET logout flag when starting tracking
      
      await _stepTrackingService.startTracking();

      // Listen to real-time step updates from pedometer (sensor stream)
      _stepsSubscription = _stepTrackingService.stepsStream.listen(
        (steps) {
          // 🔒 CRITICAL: Don't process sensor events if logging out
          if (_isLoggingOut) {
            developer.log('[HomeViewModel] [LOGOUT] Ignoring sensor event during logout');
            return;
          }
          
          // Update steps from sensor (primary source - overrides DB value)
          _steps = steps;
          developer.log('[STREAM] Sensor steps: $_steps');
          
          // Calculate new metrics
          _calculateMetrics();
          developer.log('[UI] Display steps: $_steps');
          
          // CRITICAL STEP: Save updated steps to database immediately
          _saveDailyData();
          
          notifyListeners();
        },
        onError: (error) {
          developer.log('[HomeViewModel] Step stream error: $error', error: error);
          // Gracefully continue without crashing
        },
      );
      
      developer.log('[HomeViewModel] Step tracking started. Listening to sensor stream.');
    } catch (e) {
      developer.log('[HomeViewModel] Error starting step tracking: $e', error: e);
      // Don't set error message for step tracking failures (pedometer might not be available)
    }
  }

  // Load today's data
  Future<void> loadTodayData(String uid) async {
    developer.log('[HomeViewModel] Loading today data for UID: $uid');
    _isLoading = true;
    _errorMessage = null;
    // Single notification after first frame has rendered
    notifyListeners();

    try {
      // Start step tracking from pedometer (sensor is primary source)
      // PASS UID so steps can be saved to DB automatically
      await _startStepTracking(uid);

      // Get today's date in yyyy-mm-dd format
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      developer.log('[HomeViewModel] Today date: $dateString');

      // Load user data (for calculations)
      _userModel = await _dbService.getUserData(uid);
      developer.log('[HomeViewModel] User data loaded: height=${_userModel?.height}, weight=${_userModel?.weight}');

      // Load today's daily data (including steps to restore previous state immediately)
      final dailyData = await _dbService.getDailyData(uid, dateString);

      if (dailyData != null) {
        // Load ALL data from DB (including steps) to restore previous values immediately
        // Sensor will override steps when it emits, so this is safe
        _steps = dailyData.steps;
        _water = dailyData.water;
        _sleep = dailyData.sleep;
        developer.log('[INIT] Loaded steps from DB: $_steps');
        developer.log('[HomeViewModel] Loaded from DB - Steps: $_steps, Water: $_water ml, Sleep: $_sleep hours');
      } else {
        // No data for today, initialize metrics to 0
        _steps = 0;
        _water = 0;
        _sleep = 0;
        developer.log('[INIT] No data in DB for today. Initialized to 0.');
      }

      // Calculate metrics (will use sensor steps + user data)
      _calculateMetrics();

      // Load 7-day data for weekly graph and related computations
      // All state updates are batched - only ONE notification at the end
      await _loadLast7DaysDataBatched(uid);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      developer.log('[HomeViewModel] Error loading data: $e', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load last 7 days data and batch all state updates
  /// Only calls notifyListeners() once at the very end to minimize rebuilds
  Future<void> _loadLast7DaysDataBatched(String uid) async {
    try {
      final data = await _dbService.getLast7DaysData(uid);
      _last7DaysData = data;

      // Update all computed values without notifying (batch updates)
      await _computeDynamicGoal(uid);
      _computeWeeklyAnalytics();
      _updateMotivationMessage();
      await _updateGamification(uid);

      // Single notification after all state changes
      notifyListeners();
    } catch (e) {
      developer.log('[HomeViewModel] Error loading last 7 days data: $e', error: e);
      // Silently continue on failure (graph won't display, but app won't crash)
    }
  }

  /// Legacy method - kept for backward compatibility
  Future<void> loadLast7DaysData(String uid) async {
    await _loadLast7DaysDataBatched(uid);
  }

  // Compute and update dynamic goal
  Future<void> _computeDynamicGoal(String uid) async {
    try {
      // Get last saved goal
      final savedGoal = _userModel?.stepGoal ?? 8000;
      
      // Compute new smart goal
      final newGoal = _goalService.computeSmartGoal(_last7DaysData, savedGoal);
      
      // Save to Firebase
      await _goalService.saveDynamicGoal(uid, newGoal);
      
      _dynamicGoal = newGoal;
      developer.log('[HomeViewModel] Dynamic goal updated: $_dynamicGoal');
    } catch (e) {
      developer.log('[HomeViewModel] Error computing dynamic goal: $e');
      _dynamicGoal = _userModel?.stepGoal ?? 8000;
    }
  }

  // Update motivational message based on current progress
  void _updateMotivationMessage() {
    _motivationalMessage = _motivationService.getMotivationalMessage(
      _steps,
      _dynamicGoal,
      _last7DaysData,
    );
  }

  // Compute weekly analytics
  void _computeWeeklyAnalytics() {
    if (_last7DaysData.isEmpty) {
      _weeklyAnalytics = null;
      return;
    }

    int totalSteps = 0;
    int goalSuccessDays = 0;
    String bestDay = '';
    String lowestDay = '';
    int maxSteps = 0;
    int minSteps = 100000;

    for (final entry in _last7DaysData.entries) {
      final steps = entry.value.steps;
      totalSteps += steps;

      if (steps >= _dynamicGoal) {
        goalSuccessDays++;
      }

      if (steps > maxSteps) {
        maxSteps = steps;
        bestDay = _getDayName(entry.key);
      }

      if (steps < minSteps && steps > 0) {
        minSteps = steps;
        lowestDay = _getDayName(entry.key);
      }
    }

    final averageSteps = totalSteps ~/ _last7DaysData.length;
    final goalPercentage = ((goalSuccessDays / 7) * 100).toInt();

    // Calculate improvement (compare to previous week)
    // For now, we'll use a simple 0 if this is first week
    int improvementPercent = 0;
    if (totalSteps > 0 && averageSteps > 0) {
      // Simple estimation based on goal success
      improvementPercent = (goalPercentage / 10).toInt().clamp(0, 100);
    }

    _weeklyAnalytics = WeeklyAnalytics(
      totalSteps: totalSteps,
      averageSteps: averageSteps,
      bestDay: bestDay.isNotEmpty ? bestDay : 'N/A',
      lowestDay: lowestDay.isNotEmpty ? lowestDay : 'N/A',
      goalSuccessDays: goalSuccessDays,
      goalPercentage: goalPercentage,
      improvementPercent: improvementPercent,
    );
  }

  // Get day name from date string
  String _getDayName(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return dayNames[date.weekday - 1];
    } catch (e) {
      return 'Unknown';
    }
  }

  // Update gamification data
  Future<void> _updateGamification(String uid) async {
    try {
      await _gamificationService.updateGamification(
        uid,
        _steps,
        _dynamicGoal,
        _last7DaysData,
      );

      _gamificationData = await _gamificationService.getGamificationData(uid);
      developer.log('[HomeViewModel] Gamification updated: ${_gamificationData.dailyStreak} streak');
    } catch (e) {
      developer.log('[HomeViewModel] Error updating gamification: $e');
    }
  }

  // Load prioritized health content
  Future<void> loadPrioritizedHealthContent() async {
    try {
      final allContent = await _healthHubService.fetchHealthHubContent();
      
      if (allContent.isEmpty) {
        _prioritizedHealthContent = _getLocalFallbackContent();
        developer.log('[HomeViewModel] Using local fallback health content');
      } else {
        final userBmi = _userModel?.bmi ?? 22.0;
        _prioritizedHealthContent = _healthHubService.prioritizeContent(
          allContent,
          _last7DaysData,
          userBmi,
        );
      }
      
      developer.log('[HomeViewModel] Loaded ${_prioritizedHealthContent.length} health items');
      notifyListeners();
    } catch (e) {
      developer.log('[HomeViewModel] Error loading health content: $e');
      _prioritizedHealthContent = _getLocalFallbackContent();
    }
  }

  // Local fallback health content
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
    ];
  }

  // Generate today's date string (yyyy-mm-dd format)
  String _getTodayDateString() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  // Update water intake
  Future<void> updateWater(String uid, int amount) async {
    // 🔒 CRITICAL: Prevent updates during logout
    if (_isLoggingOut) {
      developer.log('[HomeViewModel] [WATER] Blocked: logout in progress');
      return;
    }
    
    // ✅ Validate UID
    if (uid.isEmpty) {
      developer.log('[HomeViewModel] [WATER] ERROR: UID is empty');
      return;
    }
    
    try {
      _water += amount;
      developer.log('[HomeViewModel] [WATER] Updated: $_water ml');
      notifyListeners();

      // Save updated data to database
      _currentUid = uid;
      await _saveDailyData();
    } catch (e) {
      _errorMessage = 'Failed to update water: $e';
      developer.log('[HomeViewModel] [WATER] Error updating water: $e', error: e);
      notifyListeners();
    }
  }

  // Update sleep with validation (0 < hours <= 24)
  Future<void> updateSleep(String uid, int hours) async {
    // 🔒 CRITICAL: Prevent updates during logout
    if (_isLoggingOut) {
      developer.log('[HomeViewModel] [SLEEP] Blocked: logout in progress');
      return;
    }
    
    // ✅ Validate UID
    if (uid.isEmpty) {
      developer.log('[HomeViewModel] [SLEEP] ERROR: UID is empty');
      return;
    }
    
    // Validate sleep hours
    if (hours <= 0 || hours > 24) {
      _errorMessage = 'Sleep hours must be between 1 and 24';
      developer.log('[HomeViewModel] [SLEEP] Invalid sleep hours: $hours');
      notifyListeners();
      return;
    }

    try {
      _sleep = hours;
      _errorMessage = null;
      developer.log('[HomeViewModel] [SLEEP] Updated: $_sleep hours');
      notifyListeners();

      // Save updated data to database
      _currentUid = uid;
      await _saveDailyData();
    } catch (e) {
      _errorMessage = 'Failed to update sleep: $e';
      developer.log('[HomeViewModel] [SLEEP] Error updating sleep: $e', error: e);
      notifyListeners();
    }
  }

  // Calculate metrics based on steps and user data
  void _calculateMetrics() {
    if (_userModel != null) {
      // CORRECT FORMULA: distance_km = steps * (height_cm * 0.415) / 100000
      // Step length in cm = height_cm * 0.415
      // Distance in km = total_cm / 100000
      final stepLengthCm = _userModel!.height * 0.415;
      _distance = (_steps * stepLengthCm) / 100000.0;
      
      // EXAMPLE: 100 steps with 175cm height = 100 * (175 * 0.415) / 100000 = 100 * 72.625 / 100000 = 0.0726 km

      // CORRECT FORMULA: calories = steps * 0.04 * (weight / 70)
      _calories = (_steps * 0.04 * (_userModel!.weight / 70)).toInt();
    }
  }

  // Save daily data to database (CRITICAL for persistence across app restarts)
  Future<void> _saveDailyData() async {
    // 🔒 CRITICAL: Prevent saves during logout
    if (_isLoggingOut) {
      developer.log('[HomeViewModel] [SAVE] Blocked: logout in progress');
      return;
    }
    
    // ✅ CRITICAL: Validate UID exists
    if (_currentUid == null || _currentUid!.isEmpty) {
      developer.log('[HomeViewModel] [SAVE] ERROR: Cannot save - _currentUid is null or empty');
      return;
    }

    try {
      final dateString = _getTodayDateString();
      
      // ✅ CRITICAL: Validate we have real data (not saving empty/default values)
      // Only save if we have at least some meaningful data
      final hasData = _steps > 0 || _water > 0 || _sleep > 0;
      if (!hasData) {
        developer.log('[HomeViewModel] [SAVE] Skipped: No meaningful data (steps=$_steps, water=$_water, sleep=$_sleep)');
        return;
      }
      
      final dailyData = DailyDataModel(
        steps: _steps,
        water: _water,
        sleep: _sleep,
        calories: _calories,
        distance: _distance,
      );
      
      await _dbService.saveDailyData(_currentUid!, dateString, dailyData);
      developer.log('[HomeViewModel] [SAVE] ✓ Saved to DB: Steps=$_steps, Water=$_water, Sleep=$_sleep, Date=$dateString, UID=$_currentUid');
    } catch (e) {
      developer.log('[HomeViewModel] [SAVE] ERROR saving daily data: $e', error: e);
    }
  }

  // 🔒 CRITICAL: Stop tracking before logout (prevents DB writes with null UID)
  Future<void> stopTracking() async {
    developer.log('[HomeViewModel] [STOP] Stopping step tracking...');
    _isLoggingOut = true;
    
    // Cancel stream subscription immediately
    await _stepsSubscription?.cancel();
    developer.log('[HomeViewModel] [STOP] Stream subscription cancelled');
    
    // Stop step tracking service
    _stepTrackingService.dispose();
    developer.log('[HomeViewModel] [STOP] Step tracking service disposed');
    
    // Clear UID to prevent any future saves
    _currentUid = null;
    developer.log('[HomeViewModel] [STOP] UID cleared - all DB writes blocked');
  }

  // Reset daily data (for next day)
  void resetDailyData() {
    _steps = 0;
    _water = 0;
    _sleep = 0;
    _calories = 0;
    _distance = 0.0;
    notifyListeners();
  }

  // Cleanup resources
  @override
  void dispose() {
    developer.log('[HomeViewModel] [DISPOSE] Cleaning up resources...');
    _isLoggingOut = true;
    _stepsSubscription?.cancel();
    _stepTrackingService.dispose();
    _currentUid = null;
    developer.log('[HomeViewModel] [DISPOSE] Resources disposed');
    super.dispose();
  }
}

