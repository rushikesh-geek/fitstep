import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:developer' as developer;

class StepTrackingService {
  StreamSubscription<StepCount>? _stepCountStream;
  late SharedPreferences _prefs;

  int _currentSteps = 0;
  int _baselineSteps = 0;
  bool _baselineInitialized = false; // Track if baseline loaded from prefs
  bool _tracking = false; // Prevent multiple subscriptions
  int _lastEmittedSteps = -1; // Track last emitted value to avoid duplicates
  
  bool _permissionGranted = false;
  String? _permissionStatus;

  final StreamController<int> _stepsController =
      StreamController<int>.broadcast();
  Stream<int> get stepsStream => _stepsController.stream;

  // Initialize service
  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    developer.log('[StepTracking] Initialized SharedPreferences');
  }

  // Request ACTIVITY_RECOGNITION permission at runtime
  Future<bool> requestActivityRecognitionPermission() async {
    try {
      developer.log('[StepTracking] Requesting ACTIVITY_RECOGNITION permission');
      final status = await Permission.activityRecognition.request();
      
      _permissionStatus = status.toString();
      _permissionGranted = status.isGranted;
      
      developer.log('[StepTracking] Permission status: $_permissionStatus (granted: $_permissionGranted)');
      
      if (!_permissionGranted) {
        developer.log('[StepTracking] WARNING: ACTIVITY_RECOGNITION permission NOT granted');
        _stepsController.addError('ACTIVITY_RECOGNITION permission not granted. Step tracking unavailable.');
      }
      
      return _permissionGranted;
    } catch (e) {
      developer.log('[StepTracking] Error requesting permission: $e', error: e);
      _permissionStatus = 'error: $e';
      return false;
    }
  }

  // Check device capability by attempting to access stream
  Future<bool> checkDeviceCapability() async {
    try {
      developer.log('[StepTracking] Checking device pedometer capability');
      // Try to get first event from stream with timeout
      final firstEvent = await Pedometer.stepCountStream.first
          .timeout(const Duration(seconds: 5));
      developer.log('[StepTracking] Device pedometer available - first reading: ${firstEvent.steps} steps');
      return true;
    } catch (e) {
      developer.log('[StepTracking] Device pedometer check FAILED: $e', error: e);
      return false;
    }
  }

  // Get today's date string (yyyy-mm-dd format)
  String _getTodayDateString() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  // Load baseline from SharedPreferences (BEFORE any sensor reading)
  Future<void> loadBaseline() async {
    final today = _getTodayDateString();
    final baselineStr = _prefs.getString('baseline_steps_$today');
    
    if (baselineStr != null) {
      _baselineSteps = int.parse(baselineStr);
      _baselineInitialized = true;
      developer.log('[StepTracking] ✓ BASELINE LOADED: $_baselineSteps (from SharedPreferences for $today)');
    } else {
      developer.log('[StepTracking] ⚠ No baseline in SharedPreferences for $today. Will initialize on first sensor read.');
      _baselineInitialized = false;
    }
  }

  // Reset baseline if new day detected
  Future<void> resetIfNewDay() async {
    final today = _getTodayDateString();
    final lastDate = _prefs.getString('last_step_date') ?? '';

    developer.log('[StepTracking] Date check - today: $today, lastDate: $lastDate');

    if (lastDate != today) {
      // New day detected - clear baseline (will be set on first sensor event)
      _baselineInitialized = false;
      _baselineSteps = 0;
      await _prefs.setString('last_step_date', today);
      developer.log('[StepTracking] ✓ New day detected. Baseline reset for $today.');
    } else {
      // Same day - load existing baseline from SharedPreferences
      developer.log('[StepTracking] Same day. Loading baseline...');
      await loadBaseline();
    }
  }

  // Initialize baseline on first sensor event (only if not already initialized)
  Future<void> _initializeBaseline() async {
    if (!_baselineInitialized) {
      // Set baseline to first sensor reading ONLY if not already loaded
      _baselineSteps = _currentSteps;
      final today = _getTodayDateString();
      await _prefs.setString('baseline_steps_$today', _baselineSteps.toString());
      _baselineInitialized = true;
      developer.log('[StepTracking] ✓ FIRST SENSOR - BASELINE INITIALIZED: $_baselineSteps');
    } else {
      // Baseline already loaded/set - do NOT overwrite
      developer.log('[StepTracking] Baseline already initialized ($_baselineSteps). Current sensor: $_currentSteps');
    }
  }

  // Handle sensor reset (currentSteps < baselineSteps)
  Future<void> _handleSensorReset() async {
    developer.log('[StepTracking] SENSOR RESET DETECTED: currentSteps ($_currentSteps) < baseline ($_baselineSteps)');
    _baselineSteps = _currentSteps;
    final today = _getTodayDateString();
    await _prefs.setString('baseline_steps_$today', _baselineSteps.toString());
    developer.log('[StepTracking] Baseline updated due to sensor reset: $_baselineSteps');
  }

  // Get today's steps (cumulative - baseline)
  int getTodaySteps() {
    final dailySteps = _currentSteps - _baselineSteps;
    // Ensure no negative steps
    return dailySteps < 0 ? 0 : dailySteps;
  }

  // Start tracking steps from pedometer (safe - prevents multiple subscriptions)
  Future<void> startTracking() async {
    // Prevent multiple subscriptions
    if (_tracking) {
      developer.log('[StepTracking] WARNING: Already tracking. Ignoring duplicate startTracking() call.');
      return;
    }
    _tracking = true;
    developer.log('[StepTracking] Starting step tracking...');

    try {
      await _initialize();
      
      // Check permission
      developer.log('[StepTracking] Checking permission status...');
      final permissionOk = await requestActivityRecognitionPermission();
      if (!permissionOk) {
        developer.log('[StepTracking] ERROR: Permission not granted. Cannot start tracking.');
        _stepsController.addError('ACTIVITY_RECOGNITION permission required');
        _tracking = false;
        return;
      }
      
      await resetIfNewDay();

      // Listen to step count stream from pedometer
      developer.log('[StepTracking] Creating Pedometer stream subscription...');
      _stepCountStream = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          _currentSteps = event.steps;
          
          developer.log('[StepTracking] [SENSOR READ] sensor=$_currentSteps, baseline=$_baselineSteps, initialized=$_baselineInitialized');

          // Initialize baseline on first sensor event if not already initialized
          await _initializeBaseline();

          // Handle sensor reset (steps went backwards due to sensor restart)
          if (_currentSteps < _baselineSteps) {
            await _handleSensorReset();
          }

          // Get calculated daily steps
          final todaySteps = getTodaySteps();
          
          developer.log('[StepTracking] [CALC] dailySteps=$todaySteps (sensor=$_currentSteps - baseline=$_baselineSteps)');

          // Only emit if value actually changed (avoid unnecessary rebuilds)
          if (todaySteps != _lastEmittedSteps) {
            _lastEmittedSteps = todaySteps;
            developer.log('[StepTracking] [EMIT] Daily steps: $todaySteps');
            _stepsController.add(todaySteps);
          }
        },
        onError: (error) {
          developer.log('[StepTracking] [ERROR] Pedometer stream error: $error', error: error);
          _stepsController.addError(error);
        },
      );
      
      developer.log('[StepTracking] ✓ Step tracking STARTED');
    } catch (e) {
      // DEBUG: Log initialization errors
      developer.log('[StepTracking] Initialization ERROR: $e', error: e);
      _stepsController.addError(e);
      _tracking = false;
    }
  }

  // Dispose resources
  void dispose() {
    _tracking = false;
    _stepCountStream?.cancel();
    _stepsController.close();
    developer.log('[StepTracking] Resources disposed');
  }
}
