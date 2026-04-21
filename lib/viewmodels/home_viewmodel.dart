import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../services/realtime_db_service.dart';
import '../services/step_tracking_service.dart';
import '../models/user_model.dart';
import '../models/daily_data_model.dart';

class HomeViewModel extends ChangeNotifier {
  final RealtimeDBService _dbService = RealtimeDBService();
  late StepTrackingService _stepTrackingService;

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
        _steps = dailyData.steps;  // ✅ RESTORE LAST VALUE from DB
        _water = dailyData.water;
        _sleep = dailyData.sleep;
        developer.log('[INIT] Loaded steps from DB: $_steps');
        developer.log('[HomeViewModel] Loaded from DB - Steps: $_steps, Water: $_water ml, Sleep: $_sleep hours');
        // Distance and calories will be calculated from sensor steps + user data
      } else {
        // No data for today, initialize metrics to 0
        _steps = 0;
        _water = 0;
        _sleep = 0;
        developer.log('[INIT] No data in DB for today. Initialized to 0.');
      }

      // Calculate metrics (will use sensor steps + user data)
      _calculateMetrics();

      // Load 7-day data for weekly graph
      await loadLast7DaysData(uid);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      developer.log('[HomeViewModel] Error loading data: $e', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load last 7 days data for weekly graph
  Future<void> loadLast7DaysData(String uid) async {
    try {
      final data = await _dbService.getLast7DaysData(uid);
      _last7DaysData = data;
      notifyListeners();
    } catch (e) {
      // Silently continue on failure (graph won't display, but app won't crash)
    }
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

