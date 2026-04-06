// lib/models/user_stats.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modèle principal des statistiques utilisateur pour Moodia
@immutable
class UserStats {
  final String userId;
  final DateTime lastUpdated;

  // Statistiques principales
  final int totalActiveDays;
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final int completedSessions;
  final double averageSessionDuration; // en minutes
  final double averageMoodScore;
  final int goalsAchieved;
  final int totalGoals;
  final double consistencyScore; // 0-100%

  // Statistiques par catégorie
  final Map<String, CategoryStats> categoryStats;

  // Tendances
  final MoodTrend moodTrend;
  final ActivityTrend activityTrend;

  // Récompenses et succès
  final List<Achievement> recentAchievements;
  final int totalPoints;
  final int currentLevel;

  // Données temporelles
  final Map<String, TimeStats> timeStats; // Par jour de la semaine, heure, etc.

  const UserStats({
    required this.userId,
    required this.lastUpdated,
    this.totalActiveDays = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.averageSessionDuration = 0.0,
    this.averageMoodScore = 0.0,
    this.goalsAchieved = 0,
    this.totalGoals = 0,
    this.consistencyScore = 0.0,
    this.categoryStats = const {},
    required this.moodTrend,
    required this.activityTrend,
    this.recentAchievements = const [],
    this.totalPoints = 0,
    this.currentLevel = 1,
    this.timeStats = const {},
  });

  factory UserStats.empty() {
    return UserStats(
      userId: '',
      lastUpdated: DateTime.now(),
      moodTrend: MoodTrend.neutral,
      activityTrend: ActivityTrend.stable,
    );
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['userId'] ?? '',
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
      totalActiveDays: json['totalActiveDays'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      completedSessions: json['completedSessions'] ?? 0,
      averageSessionDuration: (json['averageSessionDuration'] ?? 0).toDouble(),
      averageMoodScore: (json['averageMoodScore'] ?? 0).toDouble(),
      goalsAchieved: json['goalsAchieved'] ?? 0,
      totalGoals: json['totalGoals'] ?? 0,
      consistencyScore: (json['consistencyScore'] ?? 0).toDouble(),
      categoryStats:
          (json['categoryStats'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, CategoryStats.fromJson(value)),
          ) ??
          const {},
      moodTrend: MoodTrend.values[json['moodTrend'] ?? 0],
      activityTrend: ActivityTrend.values[json['activityTrend'] ?? 0],
      recentAchievements:
          (json['recentAchievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          const [],
      totalPoints: json['totalPoints'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
      timeStats:
          (json['timeStats'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, TimeStats.fromJson(value)),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalActiveDays': totalActiveDays,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'averageSessionDuration': averageSessionDuration,
      'averageMoodScore': averageMoodScore,
      'goalsAchieved': goalsAchieved,
      'totalGoals': totalGoals,
      'consistencyScore': consistencyScore,
      'categoryStats': categoryStats.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'moodTrend': moodTrend.index,
      'activityTrend': activityTrend.index,
      'recentAchievements': recentAchievements.map((a) => a.toJson()).toList(),
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'timeStats': timeStats.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  // Méthodes de calcul
  double get completionRate =>
      totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0.0;

  double get goalAchievementRate =>
      totalGoals > 0 ? (goalsAchieved / totalGoals) * 100 : 0.0;

  int get remainingGoals => totalGoals - goalsAchieved;

  int get sessionsThisWeek {
    // Implémentation pour calculer les sessions de cette semaine
    return 0; // À implémenter avec la logique métier
  }

  double get weeklyAverageMood {
    // Implémentation pour calculer la moyenne hebdomadaire
    return 0.0; // À implémenter avec la logique métier
  }

  // Méthodes d'aide pour l'affichage
  String formatAverageMood() {
    return averageMoodScore.toStringAsFixed(1);
  }

  String formatConsistency() {
    return '${consistencyScore.toStringAsFixed(1)}%';
  }

  String formatStreak() {
    return '$currentStreak jours';
  }

  String formatLastUpdated() {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(lastUpdated);
  }

  // Méthodes de mise à jour
  UserStats copyWith({
    String? userId,
    DateTime? lastUpdated,
    int? totalActiveDays,
    int? currentStreak,
    int? longestStreak,
    int? totalSessions,
    int? completedSessions,
    double? averageSessionDuration,
    double? averageMoodScore,
    int? goalsAchieved,
    int? totalGoals,
    double? consistencyScore,
    Map<String, CategoryStats>? categoryStats,
    MoodTrend? moodTrend,
    ActivityTrend? activityTrend,
    List<Achievement>? recentAchievements,
    int? totalPoints,
    int? currentLevel,
    Map<String, TimeStats>? timeStats,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      averageSessionDuration:
          averageSessionDuration ?? this.averageSessionDuration,
      averageMoodScore: averageMoodScore ?? this.averageMoodScore,
      goalsAchieved: goalsAchieved ?? this.goalsAchieved,
      totalGoals: totalGoals ?? this.totalGoals,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      categoryStats: categoryStats ?? this.categoryStats,
      moodTrend: moodTrend ?? this.moodTrend,
      activityTrend: activityTrend ?? this.activityTrend,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      timeStats: timeStats ?? this.timeStats,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserStats &&
        other.userId == userId &&
        other.lastUpdated == lastUpdated &&
        other.totalActiveDays == totalActiveDays &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.totalSessions == totalSessions &&
        other.completedSessions == completedSessions &&
        other.averageSessionDuration == averageSessionDuration &&
        other.averageMoodScore == averageMoodScore &&
        other.goalsAchieved == goalsAchieved &&
        other.totalGoals == totalGoals &&
        other.consistencyScore == consistencyScore &&
        mapEquals(other.categoryStats, categoryStats) &&
        other.moodTrend == moodTrend &&
        other.activityTrend == activityTrend &&
        listEquals(other.recentAchievements, recentAchievements) &&
        other.totalPoints == totalPoints &&
        other.currentLevel == currentLevel &&
        mapEquals(other.timeStats, timeStats);
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      lastUpdated,
      totalActiveDays,
      currentStreak,
      longestStreak,
      totalSessions,
      completedSessions,
      averageSessionDuration,
      averageMoodScore,
      goalsAchieved,
      totalGoals,
      consistencyScore,
      Object.hashAll(categoryStats.entries),
      moodTrend,
      activityTrend,
      Object.hashAll(recentAchievements),
      totalPoints,
      currentLevel,
      Object.hashAll(timeStats.entries),
    );
  }

  @override
  String toString() {
    return 'UserStats('
        'userId: $userId, '
        'activeDays: $totalActiveDays, '
        'streak: $currentStreak, '
        'sessions: $completedSessions/$totalSessions, '
        'mood: $averageMoodScore/10, '
        'goals: $goalsAchieved/$totalGoals'
        ')';
  }
}

/// Statistiques par catégorie d'activité
@immutable
class CategoryStats {
  final String categoryId;
  final String categoryName;
  final int sessionCount;
  final double totalDuration; // en minutes
  final double averageMood;
  final double averageFocusScore;
  final DateTime lastSession;

  const CategoryStats({
    required this.categoryId,
    required this.categoryName,
    this.sessionCount = 0,
    this.totalDuration = 0.0,
    this.averageMood = 0.0,
    this.averageFocusScore = 0.0,
    required this.lastSession,
  });

  factory CategoryStats.empty(String categoryId, String categoryName) {
    return CategoryStats(
      categoryId: categoryId,
      categoryName: categoryName,
      lastSession: DateTime.now(),
    );
  }

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      sessionCount: json['sessionCount'] ?? 0,
      totalDuration: (json['totalDuration'] ?? 0).toDouble(),
      averageMood: (json['averageMood'] ?? 0).toDouble(),
      averageFocusScore: (json['averageFocusScore'] ?? 0).toDouble(),
      lastSession: DateTime.parse(
        json['lastSession'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sessionCount': sessionCount,
      'totalDuration': totalDuration,
      'averageMood': averageMood,
      'averageFocusScore': averageFocusScore,
      'lastSession': lastSession.toIso8601String(),
    };
  }

  double get averageSessionDuration =>
      sessionCount > 0 ? totalDuration / sessionCount : 0.0;

  String formatTotalDuration() {
    final hours = (totalDuration / 60).floor();
    final minutes = (totalDuration % 60).round();

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  String formatLastSession() {
    final now = DateTime.now();
    final difference = now.difference(lastSession);

    if (difference.inDays > 30) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minutes';
    } else {
      return 'À l\'instant';
    }
  }

  CategoryStats copyWith({
    String? categoryId,
    String? categoryName,
    int? sessionCount,
    double? totalDuration,
    double? averageMood,
    double? averageFocusScore,
    DateTime? lastSession,
  }) {
    return CategoryStats(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sessionCount: sessionCount ?? this.sessionCount,
      totalDuration: totalDuration ?? this.totalDuration,
      averageMood: averageMood ?? this.averageMood,
      averageFocusScore: averageFocusScore ?? this.averageFocusScore,
      lastSession: lastSession ?? this.lastSession,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryStats &&
        other.categoryId == categoryId &&
        other.categoryName == categoryName &&
        other.sessionCount == sessionCount &&
        other.totalDuration == totalDuration &&
        other.averageMood == averageMood &&
        other.averageFocusScore == averageFocusScore &&
        other.lastSession == lastSession;
  }

  @override
  int get hashCode {
    return Object.hash(
      categoryId,
      categoryName,
      sessionCount,
      totalDuration,
      averageMood,
      averageFocusScore,
      lastSession,
    );
  }
}

/// Tendance d'humeur
enum MoodTrend {
  improving,
  stable,
  declining,
  neutral;

  String get displayText {
    switch (this) {
      case MoodTrend.improving:
        return 'En amélioration 📈';
      case MoodTrend.stable:
        return 'Stable ↔️';
      case MoodTrend.declining:
        return 'En baisse 📉';
      case MoodTrend.neutral:
        return 'Neutre';
    }
  }

  Color get color {
    switch (this) {
      case MoodTrend.improving:
        return const Color(0xFF81C784); // Vert
      case MoodTrend.stable:
        return const Color(0xFF7DBBC3); // Bleu Moodia
      case MoodTrend.declining:
        return const Color(0xFFE57373); // Rouge clair
      case MoodTrend.neutral:
        return const Color(0xFFBDBDBD); // Gris
    }
  }

  IconData get icon {
    switch (this) {
      case MoodTrend.improving:
        return Icons.trending_up;
      case MoodTrend.stable:
        return Icons.trending_flat;
      case MoodTrend.declining:
        return Icons.trending_down;
      case MoodTrend.neutral:
        return Icons.remove;
    }
  }
}

/// Tendance d'activité
enum ActivityTrend {
  increasing,
  stable,
  decreasing,
  newUser;

  String get displayText {
    switch (this) {
      case ActivityTrend.increasing:
        return 'Activité en hausse 🚀';
      case ActivityTrend.stable:
        return 'Activité régulière ⏱️';
      case ActivityTrend.decreasing:
        return 'Activité en baisse ⚠️';
      case ActivityTrend.newUser:
        return 'Nouvel utilisateur 🎉';
    }
  }

  Color get color {
    switch (this) {
      case ActivityTrend.increasing:
        return const Color(0xFF4FC3F7); // Bleu clair
      case ActivityTrend.stable:
        return const Color(0xFF7DBBC3); // Bleu Moodia
      case ActivityTrend.decreasing:
        return const Color(0xFFFFB74D); // Orange
      case ActivityTrend.newUser:
        return const Color(0xFFBA68C8); // Violet
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityTrend.increasing:
        return Icons.arrow_upward;
      case ActivityTrend.stable:
        return Icons.compare_arrows;
      case ActivityTrend.decreasing:
        return Icons.arrow_downward;
      case ActivityTrend.newUser:
        return Icons.person_add;
    }
  }
}

/// Récompense/Succès
@immutable
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final AchievementLevel level;
  final DateTime earnedAt;
  final String iconUrl;
  final int pointsAwarded;
  final bool isNew;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.level,
    required this.earnedAt,
    this.iconUrl = '',
    this.pointsAwarded = 0,
    this.isNew = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: AchievementType.values[json['type'] ?? 0],
      level: AchievementLevel.values[json['level'] ?? 0],
      earnedAt: DateTime.parse(
        json['earnedAt'] ?? DateTime.now().toIso8601String(),
      ),
      iconUrl: json['iconUrl'] ?? '',
      pointsAwarded: json['pointsAwarded'] ?? 0,
      isNew: json['isNew'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'level': level.index,
      'earnedAt': earnedAt.toIso8601String(),
      'iconUrl': iconUrl,
      'pointsAwarded': pointsAwarded,
      'isNew': isNew,
    };
  }

  String formatEarnedDate() {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(earnedAt);
  }

  Color get color {
    switch (level) {
      case AchievementLevel.bronze:
        return const Color(0xFFCD7F32);
      case AchievementLevel.silver:
        return const Color(0xFFC0C0C0);
      case AchievementLevel.gold:
        return const Color(0xFFFFD700);
      case AchievementLevel.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Achievement &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.level == level &&
        other.earnedAt == earnedAt &&
        other.iconUrl == iconUrl &&
        other.pointsAwarded == pointsAwarded &&
        other.isNew == isNew;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      type,
      level,
      earnedAt,
      iconUrl,
      pointsAwarded,
      isNew,
    );
  }
}

/// Type de succès
enum AchievementType {
  streak,
  consistency,
  sessions,
  mood,
  goals,
  community,
  special;

  String get displayName {
    switch (this) {
      case AchievementType.streak:
        return 'Série';
      case AchievementType.consistency:
        return 'Régularité';
      case AchievementType.sessions:
        return 'Séances';
      case AchievementType.mood:
        return 'Humeur';
      case AchievementType.goals:
        return 'Objectifs';
      case AchievementType.community:
        return 'Communauté';
      case AchievementType.special:
        return 'Spécial';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementType.streak:
        return Icons.local_fire_department;
      case AchievementType.consistency:
        return Icons.timeline;
      case AchievementType.sessions:
        return Icons.self_improvement;
      case AchievementType.mood:
        return Icons.emoji_emotions;
      case AchievementType.goals:
        return Icons.flag;
      case AchievementType.community:
        return Icons.people;
      case AchievementType.special:
        return Icons.stars;
    }
  }
}

/// Niveau de succès
enum AchievementLevel {
  bronze,
  silver,
  gold,
  platinum;

  String get displayName {
    switch (this) {
      case AchievementLevel.bronze:
        return 'Bronze';
      case AchievementLevel.silver:
        return 'Argent';
      case AchievementLevel.gold:
        return 'Or';
      case AchievementLevel.platinum:
        return 'Platine';
    }
  }
}

/// Statistiques temporelles
@immutable
class TimeStats {
  final String timePeriod; // 'morning', 'afternoon', 'evening', 'weekday', etc.
  final int sessionCount;
  final double averageMood;
  final double averageDuration;
  final double successRate;

  const TimeStats({
    required this.timePeriod,
    this.sessionCount = 0,
    this.averageMood = 0.0,
    this.averageDuration = 0.0,
    this.successRate = 0.0,
  });

  factory TimeStats.fromJson(Map<String, dynamic> json) {
    return TimeStats(
      timePeriod: json['timePeriod'] ?? '',
      sessionCount: json['sessionCount'] ?? 0,
      averageMood: (json['averageMood'] ?? 0).toDouble(),
      averageDuration: (json['averageDuration'] ?? 0).toDouble(),
      successRate: (json['successRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timePeriod': timePeriod,
      'sessionCount': sessionCount,
      'averageMood': averageMood,
      'averageDuration': averageDuration,
      'successRate': successRate,
    };
  }

  String get displayName {
    switch (timePeriod) {
      case 'morning':
        return 'Matin (6h-12h)';
      case 'afternoon':
        return 'Après-midi (12h-18h)';
      case 'evening':
        return 'Soir (18h-00h)';
      case 'night':
        return 'Nuit (00h-6h)';
      case 'weekday':
        return 'Semaine';
      case 'weekend':
        return 'Week-end';
      default:
        return timePeriod;
    }
  }

  TimeStats copyWith({
    String? timePeriod,
    int? sessionCount,
    double? averageMood,
    double? averageDuration,
    double? successRate,
  }) {
    return TimeStats(
      timePeriod: timePeriod ?? this.timePeriod,
      sessionCount: sessionCount ?? this.sessionCount,
      averageMood: averageMood ?? this.averageMood,
      averageDuration: averageDuration ?? this.averageDuration,
      successRate: successRate ?? this.successRate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimeStats &&
        other.timePeriod == timePeriod &&
        other.sessionCount == sessionCount &&
        other.averageMood == averageMood &&
        other.averageDuration == averageDuration &&
        other.successRate == successRate;
  }

  @override
  int get hashCode {
    return Object.hash(
      timePeriod,
      sessionCount,
      averageMood,
      averageDuration,
      successRate,
    );
  }
}

/// Données pour graphiques
@immutable
class MoodChartData {
  final DateTime date;
  final double moodScore;
  final String? note;

  const MoodChartData({required this.date, required this.moodScore, this.note});
}

/// Données de sessions pour graphiques
@immutable
class SessionChartData {
  final DateTime date;
  final int sessionCount;
  final double totalDuration;
  final String? category;

  const SessionChartData({
    required this.date,
    required this.sessionCount,
    required this.totalDuration,
    this.category,
  });
}

/// Données de progression pour graphiques
@immutable
class ProgressChartData {
  final String period; // 'Semaine 1', 'Semaine 2', etc.
  final double moodScore;
  final int sessionCount;
  final double consistency;

  const ProgressChartData({
    required this.period,
    required this.moodScore,
    required this.sessionCount,
    required this.consistency,
  });
}

/// Extension pour les calculs statistiques
extension UserStatsCalculations on UserStats {
  /// Calcule le score de bien-être global
  double calculateWellnessScore() {
    final moodWeight = 0.4;
    final consistencyWeight = 0.3;
    final activityWeight = 0.2;
    final goalWeight = 0.1;

    final moodScore = (averageMoodScore / 10) * 100;
    final consistencyScore = this.consistencyScore;
    final activityScore =
        (completedSessions / (totalSessions > 0 ? totalSessions : 1)) * 100;
    final goalScore = goalAchievementRate;

    return (moodScore * moodWeight) +
        (consistencyScore * consistencyWeight) +
        (activityScore * activityWeight) +
        (goalScore * goalWeight);
  }

  /// Obtient la catégorie préférée de l'utilisateur
  String? get favoriteCategory {
    if (categoryStats.isEmpty) return null;

    var favorite = categoryStats.entries.first;

    for (final entry in categoryStats.entries) {
      if (entry.value.sessionCount > favorite.value.sessionCount) {
        favorite = entry;
      }
    }

    return favorite.key;
  }

  /// Obtient les recommandations basées sur les statistiques
  List<String> getRecommendations() {
    final recommendations = <String>[];

    // Recommandation basée sur la régularité
    if (consistencyScore < 50) {
      recommendations.add(
        'Essayez de pratiquer à la même heure chaque jour pour améliorer votre régularité.',
      );
    }

    // Recommandation basée sur l'humeur
    if (averageMoodScore < 5) {
      recommendations.add(
        'Les séances de gratitude pourraient améliorer votre humeur moyenne.',
      );
    }

    // Recommandation basée sur les objectifs
    if (goalAchievementRate < 30) {
      recommendations.add(
        'Définissez des objectifs plus petits et réalisables pour augmenter votre taux de réussite.',
      );
    }

    // Recommandation basée sur la catégorie préférée
    final favorite = favoriteCategory;
    if (favorite != null) {
      recommendations.add(
        'Continuez avec $favorite, c\'est votre pratique la plus régulière !',
      );
    }

    return recommendations;
  }

  /// Vérifie si l'utilisateur a progressé cette semaine
  bool get hasImprovedThisWeek {
    // Logique pour comparer avec les données de la semaine dernière
    // À implémenter avec les données historiques
    return consistencyScore > 60 && moodTrend == MoodTrend.improving;
  }
}

/// Builder pour créer des statistiques étape par étape
class UserStatsBuilder {
  String _userId = '';
  DateTime _lastUpdated = DateTime.now();
  int _totalActiveDays = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalSessions = 0;
  int _completedSessions = 0;
  double _averageSessionDuration = 0.0;
  double _averageMoodScore = 0.0;
  int _goalsAchieved = 0;
  int _totalGoals = 0;
  double _consistencyScore = 0.0;
  Map<String, CategoryStats> _categoryStats = {};
  MoodTrend _moodTrend = MoodTrend.neutral;
  ActivityTrend _activityTrend = ActivityTrend.stable;
  List<Achievement> _recentAchievements = [];
  int _totalPoints = 0;
  int _currentLevel = 1;
  Map<String, TimeStats> _timeStats = {};

  UserStatsBuilder();

  UserStatsBuilder setUserId(String userId) {
    _userId = userId;
    return this;
  }

  UserStatsBuilder setLastUpdated(DateTime lastUpdated) {
    _lastUpdated = lastUpdated;
    return this;
  }

  UserStatsBuilder setTotalActiveDays(int days) {
    _totalActiveDays = days;
    return this;
  }

  UserStatsBuilder setStreaks({required int current, required int longest}) {
    _currentStreak = current;
    _longestStreak = longest;
    return this;
  }

  UserStatsBuilder setSessionStats({
    required int total,
    required int completed,
  }) {
    _totalSessions = total;
    _completedSessions = completed;
    return this;
  }

  UserStatsBuilder setAverages({
    required double sessionDuration,
    required double moodScore,
  }) {
    _averageSessionDuration = sessionDuration;
    _averageMoodScore = moodScore;
    return this;
  }

  UserStatsBuilder setGoalStats({required int achieved, required int total}) {
    _goalsAchieved = achieved;
    _totalGoals = total;
    return this;
  }

  UserStatsBuilder setConsistencyScore(double score) {
    _consistencyScore = score;
    return this;
  }

  UserStatsBuilder addCategoryStat(String categoryId, CategoryStats stats) {
    _categoryStats[categoryId] = stats;
    return this;
  }

  UserStatsBuilder setTrends({
    required MoodTrend mood,
    required ActivityTrend activity,
  }) {
    _moodTrend = mood;
    _activityTrend = activity;
    return this;
  }

  UserStatsBuilder addAchievement(Achievement achievement) {
    _recentAchievements.add(achievement);
    return this;
  }

  UserStatsBuilder setLevelAndPoints({
    required int level,
    required int points,
  }) {
    _currentLevel = level;
    _totalPoints = points;
    return this;
  }

  UserStatsBuilder addTimeStat(String period, TimeStats stats) {
    _timeStats[period] = stats;
    return this;
  }

  UserStats build() {
    return UserStats(
      userId: _userId,
      lastUpdated: _lastUpdated,
      totalActiveDays: _totalActiveDays,
      currentStreak: _currentStreak,
      longestStreak: _longestStreak,
      totalSessions: _totalSessions,
      completedSessions: _completedSessions,
      averageSessionDuration: _averageSessionDuration,
      averageMoodScore: _averageMoodScore,
      goalsAchieved: _goalsAchieved,
      totalGoals: _totalGoals,
      consistencyScore: _consistencyScore,
      categoryStats: _categoryStats,
      moodTrend: _moodTrend,
      activityTrend: _activityTrend,
      recentAchievements: _recentAchievements,
      totalPoints: _totalPoints,
      currentLevel: _currentLevel,
      timeStats: _timeStats,
    );
  }
}
