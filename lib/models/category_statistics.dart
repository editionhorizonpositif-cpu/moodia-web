class ChallengeCategoryStatistics {
  final int totalCategories;
  final int activeCategories;
  final List<PopularCategory> popularCategories;
  final List<CategoryParticipation> participationByCategory;
  final List<CategoryCompletionRate> completionRateByCategory;

  ChallengeCategoryStatistics({
    required this.totalCategories,
    required this.activeCategories,
    required this.popularCategories,
    required this.participationByCategory,
    required this.completionRateByCategory,
  });

  factory ChallengeCategoryStatistics.fromJson(Map<String, dynamic> json) {
    return ChallengeCategoryStatistics(
      totalCategories: (json['totalCategories'] as num?)?.toInt() ?? 0,
      activeCategories: (json['activeCategories'] as num?)?.toInt() ?? 0,
      popularCategories: (json['popularCategories'] as List? ?? [])
          .map((e) => PopularCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      participationByCategory: (json['participationByCategory'] as List? ?? [])
          .map((e) => CategoryParticipation.fromJson(e as Map<String, dynamic>))
          .toList(),
      completionRateByCategory:
          (json['completionRateByCategory'] as List? ?? [])
              .map(
                (e) =>
                    CategoryCompletionRate.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCategories': totalCategories,
      'activeCategories': activeCategories,
      'popularCategories': popularCategories.map((e) => e.toJson()).toList(),
      'participationByCategory': participationByCategory
          .map((e) => e.toJson())
          .toList(),
      'completionRateByCategory': completionRateByCategory
          .map((e) => e.toJson())
          .toList(),
    };
  }
}

class PopularCategory {
  final int categoryId;
  final String name;
  final int activeChallenges;
  final int participants;

  PopularCategory({
    required this.categoryId,
    required this.name,
    required this.activeChallenges,
    required this.participants,
  });

  factory PopularCategory.fromJson(Map<String, dynamic> json) {
    return PopularCategory(
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      activeChallenges: (json['activeChallenges'] as num?)?.toInt() ?? 0,
      participants: (json['participants'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'activeChallenges': activeChallenges,
      'participants': participants,
    };
  }
}

class CategoryParticipation {
  final String categoryName;
  final int participants;
  final double percentage;

  CategoryParticipation({
    required this.categoryName,
    required this.participants,
    required this.percentage,
  });

  factory CategoryParticipation.fromJson(Map<String, dynamic> json) {
    return CategoryParticipation(
      categoryName: json['categoryName'] as String? ?? '',
      participants: (json['participants'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'participants': participants,
      'percentage': percentage,
    };
  }
}

class CategoryCompletionRate {
  final String categoryName;
  final double averageCompletionRate;
  final int challengesCount;

  CategoryCompletionRate({
    required this.categoryName,
    required this.averageCompletionRate,
    required this.challengesCount,
  });

  factory CategoryCompletionRate.fromJson(Map<String, dynamic> json) {
    return CategoryCompletionRate(
      categoryName: json['categoryName'] as String? ?? '',
      averageCompletionRate:
          (json['averageCompletionRate'] as num?)?.toDouble() ?? 0.0,
      challengesCount: (json['challengesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'averageCompletionRate': averageCompletionRate,
      'challengesCount': challengesCount,
    };
  }
}
