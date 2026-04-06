class ChallengeStatistics {
  final int totalChallenges;
  final int activeChallenges;
  final int totalParticipants;
  final double averageCompletionRate;
  final Map<String, int> distributionByDifficulty;
  final List<PopularChallenge> popularChallenges;
  final List<DailyActivity> dailyActivity;
  final Map<String, int> distributionByCategory;
  final UserChallengeStats? userStats;

  ChallengeStatistics({
    required this.totalChallenges,
    required this.activeChallenges,
    required this.totalParticipants,
    required this.averageCompletionRate,
    required this.distributionByDifficulty,
    required this.popularChallenges,
    required this.dailyActivity,
    required this.distributionByCategory,
    this.userStats,
  });

  factory ChallengeStatistics.fromJson(Map<String, dynamic> json) {
    return ChallengeStatistics(
      totalChallenges: (json['totalChallenges'] as num?)?.toInt() ?? 0,
      activeChallenges: (json['activeChallenges'] as num?)?.toInt() ?? 0,
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? 0,
      averageCompletionRate:
          (json['averageCompletionRate'] as num?)?.toDouble() ?? 0.0,
      distributionByDifficulty: Map.from(
        json['distributionByDifficulty'] as Map? ?? {},
      ).map((key, value) => MapEntry(key.toString(), (value as num).toInt())),
      popularChallenges: (json['popularChallenges'] as List? ?? [])
          .map((e) => PopularChallenge.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyActivity: (json['dailyActivity'] as List? ?? [])
          .map((e) => DailyActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      distributionByCategory: Map.from(
        json['distributionByCategory'] as Map? ?? {},
      ).map((key, value) => MapEntry(key.toString(), (value as num).toInt())),
      userStats: json['userStats'] != null
          ? UserChallengeStats.fromJson(
              json['userStats'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalChallenges': totalChallenges,
      'activeChallenges': activeChallenges,
      'totalParticipants': totalParticipants,
      'averageCompletionRate': averageCompletionRate,
      'distributionByDifficulty': distributionByDifficulty,
      'popularChallenges': popularChallenges.map((e) => e.toJson()).toList(),
      'dailyActivity': dailyActivity.map((e) => e.toJson()).toList(),
      'distributionByCategory': distributionByCategory,
      'userStats': userStats?.toJson(),
    };
  }
}

class PopularChallenge {
  final int challengeId;
  final String title;
  final int participants;
  final double completionRate;

  PopularChallenge({
    required this.challengeId,
    required this.title,
    required this.participants,
    required this.completionRate,
  });

  factory PopularChallenge.fromJson(Map<String, dynamic> json) {
    return PopularChallenge(
      challengeId: (json['challengeId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      participants: (json['participants'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'title': title,
      'participants': participants,
      'completionRate': completionRate,
    };
  }
}

class DailyActivity {
  final DateTime date;
  final int newParticipants;
  final int completedChallenges;

  DailyActivity({
    required this.date,
    required this.newParticipants,
    required this.completedChallenges,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      date: DateTime.parse(json['date'] as String),
      newParticipants: (json['newParticipants'] as num?)?.toInt() ?? 0,
      completedChallenges: (json['completedChallenges'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'newParticipants': newParticipants,
      'completedChallenges': completedChallenges,
    };
  }
}

class UserChallengeStats {
  final int joinedChallenges;
  final int completedChallenges;
  final int inProgressChallenges;
  final int totalPointsEarned;
  final int totalXpEarned;
  final int maxStreak;
  final int currentStreak;
  final double successRate;

  UserChallengeStats({
    required this.joinedChallenges,
    required this.completedChallenges,
    required this.inProgressChallenges,
    required this.totalPointsEarned,
    required this.totalXpEarned,
    required this.maxStreak,
    required this.currentStreak,
    required this.successRate,
  });

  factory UserChallengeStats.fromJson(Map<String, dynamic> json) {
    return UserChallengeStats(
      joinedChallenges: (json['joinedChallenges'] as num?)?.toInt() ?? 0,
      completedChallenges: (json['completedChallenges'] as num?)?.toInt() ?? 0,
      inProgressChallenges:
          (json['inProgressChallenges'] as num?)?.toInt() ?? 0,
      totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
      totalXpEarned: (json['totalXpEarned'] as num?)?.toInt() ?? 0,
      maxStreak: (json['maxStreak'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'joinedChallenges': joinedChallenges,
      'completedChallenges': completedChallenges,
      'inProgressChallenges': inProgressChallenges,
      'totalPointsEarned': totalPointsEarned,
      'totalXpEarned': totalXpEarned,
      'maxStreak': maxStreak,
      'currentStreak': currentStreak,
      'successRate': successRate,
    };
  }
}
