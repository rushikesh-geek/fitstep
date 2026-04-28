class GameBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int threshold;
  final String category;
  final bool unlocked;
  final DateTime? unlockedDate;

  GameBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.threshold,
    required this.category,
    this.unlocked = false,
    this.unlockedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'threshold': threshold,
      'category': category,
      'unlocked': unlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
    };
  }

  factory GameBadge.fromMap(Map<String, dynamic> map) {
    return GameBadge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏅',
      threshold: map['threshold'] ?? 0,
      category: map['category'] ?? '',
      unlocked: map['unlocked'] ?? false,
      unlockedDate: map['unlockedDate'] != null
          ? DateTime.tryParse(map['unlockedDate'])
          : null,
    );
  }

  GameBadge copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    int? threshold,
    String? category,
    bool? unlocked,
    DateTime? unlockedDate,
  }) {
    return GameBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      threshold: threshold ?? this.threshold,
      category: category ?? this.category,
      unlocked: unlocked ?? this.unlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
}

class GamificationModel {
  final int dailyStreak;
  final int longestStreak;
  final int lifetimeSteps;
  final List<GameBadge> badges;
  final String weeklyRank;
  final int weeklySteps;

  GamificationModel({
    this.dailyStreak = 0,
    this.longestStreak = 0,
    this.lifetimeSteps = 0,
    this.badges = const [],
    this.weeklyRank = 'Bronze',
    this.weeklySteps = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailyStreak': dailyStreak,
      'longestStreak': longestStreak,
      'lifetimeSteps': lifetimeSteps,
      'badges': badges.map((b) => b.toMap()).toList(),
      'weeklyRank': weeklyRank,
      'weeklySteps': weeklySteps,
    };
  }

  factory GamificationModel.fromMap(Map<String, dynamic> map) {
    final badgesList = (map['badges'] as List<dynamic>?)
            ?.map((b) => GameBadge.fromMap(Map<String, dynamic>.from(b as Map)))
            .toList() ??
        [];

    return GamificationModel(
      dailyStreak: map['dailyStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lifetimeSteps: map['lifetimeSteps'] ?? 0,
      badges: badgesList,
      weeklyRank: map['weeklyRank'] ?? 'Bronze',
      weeklySteps: map['weeklySteps'] ?? 0,
    );
  }

  GamificationModel copyWith({
    int? dailyStreak,
    int? longestStreak,
    int? lifetimeSteps,
    List<GameBadge>? badges,
    String? weeklyRank,
    int? weeklySteps,
  }) {
    return GamificationModel(
      dailyStreak: dailyStreak ?? this.dailyStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lifetimeSteps: lifetimeSteps ?? this.lifetimeSteps,
      badges: badges ?? this.badges,
      weeklyRank: weeklyRank ?? this.weeklyRank,
      weeklySteps: weeklySteps ?? this.weeklySteps,
    );
  }
}
