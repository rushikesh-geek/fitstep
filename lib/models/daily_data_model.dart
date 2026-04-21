class DailyDataModel {
  final int steps;
  final int water; // in ml
  final int sleep; // in hours
  final int calories;
  final double distance; // in km

  DailyDataModel({
    required this.steps,
    required this.water,
    required this.sleep,
    required this.calories,
    required this.distance,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'steps': steps,
      'water': water,
      'sleep': sleep,
      'calories': calories,
      'distance': distance,
    };
  }

  // Create from Firebase Map
  factory DailyDataModel.fromMap(Map<String, dynamic> map) {
    return DailyDataModel(
      steps: map['steps'] ?? 0,
      water: map['water'] ?? 0,
      sleep: map['sleep'] ?? 0,
      calories: map['calories'] ?? 0,
      distance: (map['distance'] ?? 0.0).toDouble(),
    );
  }

  // Create empty DailyDataModel (default values)
  factory DailyDataModel.empty() {
    return DailyDataModel(
      steps: 0,
      water: 0,
      sleep: 0,
      calories: 0,
      distance: 0.0,
    );
  }

  // Copy with modifications
  DailyDataModel copyWith({
    int? steps,
    int? water,
    int? sleep,
    int? calories,
    double? distance,
  }) {
    return DailyDataModel(
      steps: steps ?? this.steps,
      water: water ?? this.water,
      sleep: sleep ?? this.sleep,
      calories: calories ?? this.calories,
      distance: distance ?? this.distance,
    );
  }
}
