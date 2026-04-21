import 'package:flutter/material.dart';
import '../services/realtime_db_service.dart';
import '../models/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final RealtimeDBService _dbService = RealtimeDBService();

  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEditing = false;

  // Edit form fields
  late TextEditingController _usernameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _stepGoalController;

  // Getters
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _isEditing;
  double get bmi => _calculateBMI();
  TextEditingController get usernameController => _usernameController;
  TextEditingController get ageController => _ageController;
  TextEditingController get heightController => _heightController;
  TextEditingController get weightController => _weightController;
  TextEditingController get stepGoalController => _stepGoalController;

  ProfileViewModel() {
    _usernameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _stepGoalController = TextEditingController();
  }

  // Load user profile from database
  Future<void> loadUserProfile(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userModel = await _dbService.getUserData(uid);
      if (_userModel != null) {
        _initializeControllers();
      } else {
        _errorMessage = 'User profile not found';
      }
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize text controllers with user data
  void _initializeControllers() {
    if (_userModel != null) {
      _usernameController.text = _userModel!.username;
      _ageController.text = _userModel!.age.toString();
      _heightController.text = _userModel!.height.toString();
      _weightController.text = _userModel!.weight.toString();
      _stepGoalController.text = _userModel!.stepGoal.toString();
    }
  }

  // Enable edit mode
  void enableEdit() {
    _isEditing = true;
    notifyListeners();
  }

  // Cancel edit mode
  void cancelEdit() {
    _isEditing = false;
    _initializeControllers();
    _errorMessage = null;
    notifyListeners();
  }

  // Validate edit form
  String? _validateForm() {
    if (_usernameController.text.isEmpty) return 'Username cannot be empty';
    if (_ageController.text.isEmpty) return 'Age cannot be empty';
    if (_heightController.text.isEmpty) return 'Height cannot be empty';
    if (_weightController.text.isEmpty) return 'Weight cannot be empty';
    if (_stepGoalController.text.isEmpty) return 'Step goal cannot be empty';

    try {
      int.parse(_ageController.text);
      int.parse(_heightController.text);
      double.parse(_weightController.text);
      int.parse(_stepGoalController.text);
    } catch (e) {
      return 'Please enter valid numeric values';
    }

    return null;
  }

  // Calculate BMI from updated height and weight
  double _calculateBMI() {
    if (_userModel == null || _userModel!.height == 0 || _userModel!.weight == 0) {
      return 0.0;
    }
    final heightInMeters = _userModel!.height / 100.0;
    return _userModel!.weight / (heightInMeters * heightInMeters);
  }

  // Save updated user profile to database
  Future<void> saveUserProfile(String uid) async {
    final validationError = _validateForm();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create updated user model
      _userModel = UserModel(
        username: _usernameController.text,
        age: int.parse(_ageController.text),
        height: int.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        bmi: _calculateBMI(),
        stepGoal: int.parse(_stepGoalController.text),
      );

      // Save to database
      await _dbService.saveUserData(uid, _userModel!);

      _isEditing = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to save profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _stepGoalController.dispose();
    super.dispose();
  }
}
