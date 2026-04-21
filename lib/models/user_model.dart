class UserModel {
  final String username;
  final int age;
  final int height; // in cm
  final double weight; // in kg
  final double bmi;
  final int stepGoal;

  UserModel({
    required this.username,
    required this.age,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.stepGoal,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'age': age,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'stepGoal': stepGoal,
    };
  }

  // Create from Firebase Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'] ?? '',
      age: map['age'] ?? 0,
      height: map['height'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      bmi: (map['bmi'] ?? 0.0).toDouble(),
      stepGoal: map['stepGoal'] ?? 8000,
    );
  }

  // Copy with modifications
  UserModel copyWith({
    String? username,
    int? age,
    int? height,
    double? weight,
    double? bmi,
    int? stepGoal,
  }) {
    return UserModel(
      username: username ?? this.username,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      stepGoal: stepGoal ?? this.stepGoal,
    );
  }
}
