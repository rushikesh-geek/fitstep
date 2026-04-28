class HealthHubItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String videoUrl;
  final String level;
  final List<String> tags;
  final int priority;

  HealthHubItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    this.level = 'Beginner',
    this.tags = const [],
    this.priority = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'videoUrl': videoUrl,
      'level': level,
      'tags': tags,
      'priority': priority,
    };
  }

  factory HealthHubItem.fromMap(String id, Map<String, dynamic> map) {
    return HealthHubItem(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      level: map['level'] ?? 'Beginner',
      tags: List<String>.from(map['tags'] ?? []),
      priority: map['priority'] ?? 0,
    );
  }

  HealthHubItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? videoUrl,
    String? level,
    List<String>? tags,
    int? priority,
  }) {
    return HealthHubItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      videoUrl: videoUrl ?? this.videoUrl,
      level: level ?? this.level,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
    );
  }
}

class WeeklyAnalytics {
  final int totalSteps;
  final int averageSteps;
  final String bestDay;
  final String lowestDay;
  final int goalSuccessDays;
  final int goalPercentage;
  final int improvementPercent;

  WeeklyAnalytics({
    required this.totalSteps,
    required this.averageSteps,
    required this.bestDay,
    required this.lowestDay,
    required this.goalSuccessDays,
    required this.goalPercentage,
    required this.improvementPercent,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalSteps': totalSteps,
      'averageSteps': averageSteps,
      'bestDay': bestDay,
      'lowestDay': lowestDay,
      'goalSuccessDays': goalSuccessDays,
      'goalPercentage': goalPercentage,
      'improvementPercent': improvementPercent,
    };
  }
}
