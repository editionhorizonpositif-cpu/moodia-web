class ChallengeCompletionStatistics {
  final int? userId;
  final int? challengeId;
  final int totalCompletions;
  final int recentCompletions;
  final double averageRating;
  final double averageDifficultyRating;
  final double averageWellBeingScore;
  final double recommendationPercentage;
  final double averageConsistencyRate;
  final double totalTimeInvestedHours;
  final Map<String, int> completionsByCategory;
  final Map<String, int> completionTimeDistribution;
  final List<MonthlyCompletion> monthlyCompletions;
  final List<PopularCompletionChallenge> popularChallenges;

  ChallengeCompletionStatistics({
    this.userId,
    this.challengeId,
    required this.totalCompletions,
    required this.recentCompletions,
    required this.averageRating,
    required this.averageDifficultyRating,
    required this.averageWellBeingScore,
    required this.recommendationPercentage,
    required this.averageConsistencyRate,
    required this.totalTimeInvestedHours,
    required this.completionsByCategory,
    required this.completionTimeDistribution,
    required this.monthlyCompletions,
    required this.popularChallenges,
  });

  factory ChallengeCompletionStatistics.fromJson(Map<String, dynamic> json) {
    return ChallengeCompletionStatistics(
      userId: json['userId'] as int?,
      challengeId: json['challengeId'] as int?,
      totalCompletions: (json['totalCompletions'] as num?)?.toInt() ?? 0,
      recentCompletions: (json['recentCompletions'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      averageDifficultyRating:
          (json['averageDifficultyRating'] as num?)?.toDouble() ?? 0.0,
      averageWellBeingScore:
          (json['averageWellBeingScore'] as num?)?.toDouble() ?? 0.0,
      recommendationPercentage:
          (json['recommendationPercentage'] as num?)?.toDouble() ?? 0.0,
      averageConsistencyRate:
          (json['averageConsistencyRate'] as num?)?.toDouble() ?? 0.0,
      totalTimeInvestedHours:
          (json['totalTimeInvestedHours'] as num?)?.toDouble() ?? 0.0,
      completionsByCategory: Map.from(
        json['completionsByCategory'] as Map? ?? {},
      ).map((key, value) => MapEntry(key.toString(), (value as num).toInt())),
      completionTimeDistribution: Map.from(
        json['completionTimeDistribution'] as Map? ?? {},
      ).map((key, value) => MapEntry(key.toString(), (value as num).toInt())),
      monthlyCompletions: (json['monthlyCompletions'] as List? ?? [])
          .map((e) => MonthlyCompletion.fromJson(e as Map<String, dynamic>))
          .toList(),
      popularChallenges: (json['popularChallenges'] as List? ?? [])
          .map(
            (e) =>
                PopularCompletionChallenge.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'totalCompletions': totalCompletions,
      'recentCompletions': recentCompletions,
      'averageRating': averageRating,
      'averageDifficultyRating': averageDifficultyRating,
      'averageWellBeingScore': averageWellBeingScore,
      'recommendationPercentage': recommendationPercentage,
      'averageConsistencyRate': averageConsistencyRate,
      'totalTimeInvestedHours': totalTimeInvestedHours,
      'completionsByCategory': completionsByCategory,
      'completionTimeDistribution': completionTimeDistribution,
      'monthlyCompletions': monthlyCompletions.map((e) => e.toJson()).toList(),
      'popularChallenges': popularChallenges.map((e) => e.toJson()).toList(),
    };
  }
}

class MonthlyCompletion {
  final int month;
  final int year;
  final int completionCount;

  MonthlyCompletion({
    required this.month,
    required this.year,
    required this.completionCount,
  });

  factory MonthlyCompletion.fromJson(Map<String, dynamic> json) {
    return MonthlyCompletion(
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      completionCount: (json['completionCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'month': month, 'year': year, 'completionCount': completionCount};
  }
}

class PopularCompletionChallenge {
  final int challengeId;
  final String title;
  final int completionCount;

  PopularCompletionChallenge({
    required this.challengeId,
    required this.title,
    required this.completionCount,
  });

  factory PopularCompletionChallenge.fromJson(Map<String, dynamic> json) {
    return PopularCompletionChallenge(
      challengeId: (json['challengeId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      completionCount: (json['completionCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'title': title,
      'completionCount': completionCount,
    };
  }
}
