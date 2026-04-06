// lib/models/activity_dtos.dart - VERSION FINALE COMPLÈTE ET CORRIGÉE

// ============ DTO POUR LA CONFIGURATION ============

/// DTO pour la configuration de l'activité
class ActivityConfigurationDTO {
  final bool? requiresPreparation;
  final int? preparationTimeSeconds;
  final bool? isGuided;
  final bool? hasBackgroundMusic;
  final bool? isOfflineAvailable;
  final int? maxParticipants;
  final int? energyLevel;
  final int? focusLevel;
  final String? moodImpact;
  final String? recommendedTimeOfDay;
  final String? idealEnvironment;
  final String? equipmentRequired;
  final bool? hasGuidedAudio;
  final bool? hasVideoGuide;
  final bool? hasAnimation;
  final bool? isInteractive;
  final bool? hasReminders;
  final bool? hasProgressTracking;
  final int? minimumAge;
  final bool? isAccessible;

  ActivityConfigurationDTO({
    this.requiresPreparation,
    this.preparationTimeSeconds,
    this.isGuided,
    this.hasBackgroundMusic,
    this.isOfflineAvailable,
    this.maxParticipants,
    this.energyLevel,
    this.focusLevel,
    this.moodImpact,
    this.recommendedTimeOfDay,
    this.idealEnvironment,
    this.equipmentRequired,
    this.hasGuidedAudio,
    this.hasVideoGuide,
    this.hasAnimation,
    this.isInteractive,
    this.hasReminders,
    this.hasProgressTracking,
    this.minimumAge,
    this.isAccessible,
  });

  factory ActivityConfigurationDTO.fromJson(Map<String, dynamic> json) {
    return ActivityConfigurationDTO(
      requiresPreparation: json['requiresPreparation'],
      preparationTimeSeconds: json['preparationTimeSeconds'],
      isGuided: json['isGuided'],
      hasBackgroundMusic: json['hasBackgroundMusic'],
      isOfflineAvailable: json['isOfflineAvailable'],
      maxParticipants: json['maxParticipants'],
      energyLevel: json['energyLevel'],
      focusLevel: json['focusLevel'],
      moodImpact: json['moodImpact'],
      recommendedTimeOfDay: json['recommendedTimeOfDay'],
      idealEnvironment: json['idealEnvironment'],
      equipmentRequired: json['equipmentRequired'],
      hasGuidedAudio: json['hasGuidedAudio'],
      hasVideoGuide: json['hasVideoGuide'],
      hasAnimation: json['hasAnimation'],
      isInteractive: json['isInteractive'],
      hasReminders: json['hasReminders'],
      hasProgressTracking: json['hasProgressTracking'],
      minimumAge: json['minimumAge'],
      isAccessible: json['isAccessible'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (requiresPreparation != null)
        'requiresPreparation': requiresPreparation,
      if (preparationTimeSeconds != null)
        'preparationTimeSeconds': preparationTimeSeconds,
      if (isGuided != null) 'isGuided': isGuided,
      if (hasBackgroundMusic != null) 'hasBackgroundMusic': hasBackgroundMusic,
      if (isOfflineAvailable != null) 'isOfflineAvailable': isOfflineAvailable,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      if (energyLevel != null) 'energyLevel': energyLevel,
      if (focusLevel != null) 'focusLevel': focusLevel,
      if (moodImpact != null) 'moodImpact': moodImpact,
      if (recommendedTimeOfDay != null)
        'recommendedTimeOfDay': recommendedTimeOfDay,
      if (idealEnvironment != null) 'idealEnvironment': idealEnvironment,
      if (equipmentRequired != null) 'equipmentRequired': equipmentRequired,
      if (hasGuidedAudio != null) 'hasGuidedAudio': hasGuidedAudio,
      if (hasVideoGuide != null) 'hasVideoGuide': hasVideoGuide,
      if (hasAnimation != null) 'hasAnimation': hasAnimation,
      if (isInteractive != null) 'isInteractive': isInteractive,
      if (hasReminders != null) 'hasReminders': hasReminders,
      if (hasProgressTracking != null)
        'hasProgressTracking': hasProgressTracking,
      if (minimumAge != null) 'minimumAge': minimumAge,
      if (isAccessible != null) 'isAccessible': isAccessible,
    };
  }

  ActivityConfigurationDTO copyWith({
    bool? requiresPreparation,
    int? preparationTimeSeconds,
    bool? isGuided,
    bool? hasBackgroundMusic,
    bool? isOfflineAvailable,
    int? maxParticipants,
    int? energyLevel,
    int? focusLevel,
    String? moodImpact,
    String? recommendedTimeOfDay,
    String? idealEnvironment,
    String? equipmentRequired,
    bool? hasGuidedAudio,
    bool? hasVideoGuide,
    bool? hasAnimation,
    bool? isInteractive,
    bool? hasReminders,
    bool? hasProgressTracking,
    int? minimumAge,
    bool? isAccessible,
  }) {
    return ActivityConfigurationDTO(
      requiresPreparation: requiresPreparation ?? this.requiresPreparation,
      preparationTimeSeconds:
          preparationTimeSeconds ?? this.preparationTimeSeconds,
      isGuided: isGuided ?? this.isGuided,
      hasBackgroundMusic: hasBackgroundMusic ?? this.hasBackgroundMusic,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      energyLevel: energyLevel ?? this.energyLevel,
      focusLevel: focusLevel ?? this.focusLevel,
      moodImpact: moodImpact ?? this.moodImpact,
      recommendedTimeOfDay: recommendedTimeOfDay ?? this.recommendedTimeOfDay,
      idealEnvironment: idealEnvironment ?? this.idealEnvironment,
      equipmentRequired: equipmentRequired ?? this.equipmentRequired,
      hasGuidedAudio: hasGuidedAudio ?? this.hasGuidedAudio,
      hasVideoGuide: hasVideoGuide ?? this.hasVideoGuide,
      hasAnimation: hasAnimation ?? this.hasAnimation,
      isInteractive: isInteractive ?? this.isInteractive,
      hasReminders: hasReminders ?? this.hasReminders,
      hasProgressTracking: hasProgressTracking ?? this.hasProgressTracking,
      minimumAge: minimumAge ?? this.minimumAge,
      isAccessible: isAccessible ?? this.isAccessible,
    );
  }
}

/// DTO pour la création d'activité - VERSION FINALE CORRIGÉE
class ActivityRequestDTO {
  final String title;
  final String? shortDescription;
  final String? description;
  final String type;
  final int? categoryId;
  final List<String>? tags;
  final int? durationSeconds;
  final String? difficultyLevel;
  final int? coverImageAssetId;
  final int? lottieAnimationAssetId;
  final int? audioGuideAssetId;
  final String? iconName;
  final String? colorHex;
  final ActivityConfigurationDTO? configuration;
  final String? instructions;
  final String? prerequisites;
  final String? benefits;

  ActivityRequestDTO({
    required this.title,
    this.shortDescription,
    this.description,
    required this.type,
    this.categoryId,
    this.tags,
    this.durationSeconds,
    this.difficultyLevel,
    this.coverImageAssetId,
    this.lottieAnimationAssetId,
    this.audioGuideAssetId,
    this.iconName,
    this.colorHex,
    this.configuration,
    this.instructions,
    this.prerequisites,
    this.benefits,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (shortDescription != null) 'shortDescription': shortDescription,
      if (description != null) 'description': description,
      'type': type,
      if (categoryId != null) 'categoryId': categoryId,
      if (tags != null) 'tags': tags,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (difficultyLevel != null) 'difficultyLevel': difficultyLevel,
      if (coverImageAssetId != null) 'coverImageAssetId': coverImageAssetId,
      if (lottieAnimationAssetId != null)
        'lottieAnimationAssetId': lottieAnimationAssetId,
      if (audioGuideAssetId != null) 'audioGuideAssetId': audioGuideAssetId,
      if (iconName != null) 'iconName': iconName,
      if (colorHex != null) 'colorHex': colorHex,
      if (configuration != null) 'configuration': configuration?.toJson(),
      if (instructions != null) 'instructions': instructions,
      if (prerequisites != null) 'prerequisites': prerequisites,
      if (benefits != null) 'benefits': benefits,
    };
  }

  factory ActivityRequestDTO.fromJson(Map<String, dynamic> json) {
    return ActivityRequestDTO(
      title: json['title'] as String,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String,
      categoryId: json['categoryId'] as int?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      durationSeconds: json['durationSeconds'] as int?,
      difficultyLevel: json['difficultyLevel'] as String?,
      coverImageAssetId: json['coverImageAssetId'] as int?,
      lottieAnimationAssetId: json['lottieAnimationAssetId'] as int?,
      audioGuideAssetId: json['audioGuideAssetId'] as int?,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      configuration: json['configuration'] != null
          ? ActivityConfigurationDTO.fromJson(json['configuration'])
          : null,
      instructions: json['instructions'] as String?,
      prerequisites: json['prerequisites'] as String?,
      benefits: json['benefits'] as String?,
    );
  }

  ActivityRequestDTO copyWith({
    String? title,
    String? shortDescription,
    String? description,
    String? type,
    int? categoryId,
    List<String>? tags,
    int? durationSeconds,
    String? difficultyLevel,
    int? coverImageAssetId,
    int? lottieAnimationAssetId,
    int? audioGuideAssetId,
    String? iconName,
    String? colorHex,
    ActivityConfigurationDTO? configuration,
    String? instructions,
    String? prerequisites,
    String? benefits,
  }) {
    return ActivityRequestDTO(
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      coverImageAssetId: coverImageAssetId ?? this.coverImageAssetId,
      lottieAnimationAssetId:
          lottieAnimationAssetId ?? this.lottieAnimationAssetId,
      audioGuideAssetId: audioGuideAssetId ?? this.audioGuideAssetId,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      configuration: configuration ?? this.configuration,
      instructions: instructions ?? this.instructions,
      prerequisites: prerequisites ?? this.prerequisites,
      benefits: benefits ?? this.benefits,
    );
  }
}

// ============ DTO POUR LA RÉPONSE ============

class ActivityResponseDTO {
  final int id;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String type;
  final String? typeDisplayName;
  final String? typeEmoji;
  final Map<String, dynamic>? category;
  final List<String> tags;
  final int? durationSeconds;
  final String? durationDisplay;
  final String? difficultyLevel;
  final String? difficultyDescription;
  final String? coverImageUrl;
  final String? lottieAnimationUrl;
  final String? audioGuideUrl;
  final String? iconName;
  final String? colorHex;
  final Map<String, dynamic>? configuration;
  final String? instructions;
  final String? prerequisites;
  final String? benefits;
  final int completionCount;
  final double averageRating;
  final double popularityScore;
  final double? successRate;
  final bool? isFavorite;
  final bool? isCompleted;
  final int? userRating;
  final String? userFeedback;
  final DateTime? lastCompleted;
  final int? progressPercentage;
  final bool? isInProgress;
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  ActivityResponseDTO({
    required this.id,
    required this.title,
    required this.slug,
    this.shortDescription,
    this.description,
    required this.type,
    this.typeDisplayName,
    this.typeEmoji,
    this.category,
    this.tags = const [],
    this.durationSeconds,
    this.durationDisplay,
    this.difficultyLevel,
    this.difficultyDescription,
    this.coverImageUrl,
    this.lottieAnimationUrl,
    this.audioGuideUrl,
    this.iconName,
    this.colorHex,
    this.configuration,
    this.instructions,
    this.prerequisites,
    this.benefits,
    this.completionCount = 0,
    this.averageRating = 0.0,
    this.popularityScore = 0.0,
    this.successRate,
    this.isFavorite,
    this.isCompleted,
    this.userRating,
    this.userFeedback,
    this.lastCompleted,
    this.progressPercentage,
    this.isInProgress,
    required this.status,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  factory ActivityResponseDTO.fromJson(Map<String, dynamic> json) {
    return ActivityResponseDTO(
      id: json['id'] as int,
      title: json['title'] as String,
      slug: json['slug'] as String,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String,
      typeDisplayName: json['typeDisplayName'] as String?,
      typeEmoji: json['typeEmoji'] as String?,
      category: json['category'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      durationSeconds: json['durationSeconds'] as int?,
      durationDisplay: json['durationDisplay'] as String?,
      difficultyLevel: json['difficultyLevel'] as String?,
      difficultyDescription: json['difficultyDescription'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      lottieAnimationUrl: json['lottieAnimationUrl'] as String?,
      audioGuideUrl: json['audioGuideUrl'] as String?,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      configuration: json['configuration'] as Map<String, dynamic>?,
      instructions: json['instructions'] as String?,
      prerequisites: json['prerequisites'] as String?,
      benefits: json['benefits'] as String?,
      completionCount: json['completionCount'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      popularityScore: (json['popularityScore'] as num?)?.toDouble() ?? 0.0,
      successRate: (json['successRate'] as num?)?.toDouble(),
      isFavorite: json['isFavorite'] as bool?,
      isCompleted: json['isCompleted'] as bool?,
      userRating: json['userRating'] as int?,
      userFeedback: json['userFeedback'] as String?,
      lastCompleted: json['lastCompleted'] != null
          ? DateTime.parse(json['lastCompleted'] as String)
          : null,
      progressPercentage: json['progressPercentage'] as int?,
      isInProgress: json['isInProgress'] as bool?,
      status: json['status'] as String? ?? 'PUBLISHED',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'shortDescription': shortDescription,
      'description': description,
      'type': type,
      'typeDisplayName': typeDisplayName,
      'typeEmoji': typeEmoji,
      'category': category,
      'tags': tags,
      'durationSeconds': durationSeconds,
      'durationDisplay': durationDisplay,
      'difficultyLevel': difficultyLevel,
      'difficultyDescription': difficultyDescription,
      'coverImageUrl': coverImageUrl,
      'lottieAnimationUrl': lottieAnimationUrl,
      'audioGuideUrl': audioGuideUrl,
      'iconName': iconName,
      'colorHex': colorHex,
      'configuration': configuration,
      'instructions': instructions,
      'prerequisites': prerequisites,
      'benefits': benefits,
      'completionCount': completionCount,
      'averageRating': averageRating,
      'popularityScore': popularityScore,
      'successRate': successRate,
      'isFavorite': isFavorite,
      'isCompleted': isCompleted,
      'userRating': userRating,
      'userFeedback': userFeedback,
      'lastCompleted': lastCompleted?.toIso8601String(),
      'progressPercentage': progressPercentage,
      'isInProgress': isInProgress,
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}

// ============ DTO POUR LA RECHERCHE ============

class ActivitySearchRequestDTO {
  final String? query;
  final List<int>? categoryIds;
  final List<String>? types;
  final List<String>? difficultyLevels;
  final int? minDurationSeconds;
  final int? maxDurationSeconds;
  final bool? completedOnly;
  final bool? favoriteOnly;
  final bool? bookmarkedOnly;
  final bool? recommendedOnly;
  final bool? newOnly;
  final bool? popularOnly;
  final String sortBy;
  final String sortDirection;
  final int page;
  final int size;

  ActivitySearchRequestDTO({
    this.query,
    this.categoryIds,
    this.types,
    this.difficultyLevels,
    this.minDurationSeconds,
    this.maxDurationSeconds,
    this.completedOnly,
    this.favoriteOnly,
    this.bookmarkedOnly,
    this.recommendedOnly,
    this.newOnly,
    this.popularOnly,
    this.sortBy = 'popularity',
    this.sortDirection = 'DESC',
    this.page = 0,
    this.size = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      if (query != null) 'query': query,
      if (categoryIds != null) 'categoryIds': categoryIds,
      if (types != null) 'types': types,
      if (difficultyLevels != null) 'difficultyLevels': difficultyLevels,
      if (minDurationSeconds != null) 'minDurationSeconds': minDurationSeconds,
      if (maxDurationSeconds != null) 'maxDurationSeconds': maxDurationSeconds,
      if (completedOnly != null) 'completedOnly': completedOnly,
      if (favoriteOnly != null) 'favoriteOnly': favoriteOnly,
      if (bookmarkedOnly != null) 'bookmarkedOnly': bookmarkedOnly,
      if (recommendedOnly != null) 'recommendedOnly': recommendedOnly,
      if (newOnly != null) 'newOnly': newOnly,
      if (popularOnly != null) 'popularOnly': popularOnly,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
      'page': page,
      'size': size,
    };
  }

  bool get hasFilters {
    return query != null ||
        categoryIds != null ||
        types != null ||
        difficultyLevels != null ||
        minDurationSeconds != null ||
        maxDurationSeconds != null ||
        completedOnly != null ||
        favoriteOnly != null ||
        bookmarkedOnly != null ||
        recommendedOnly != null ||
        newOnly != null ||
        popularOnly != null;
  }
}

// ============ DTO POUR LA PROGRESSION ============

class ActivityProgressRequestDTO {
  final int sessionId;
  final int progressPercentage;
  final int positionSeconds;
  final String? deviceId;
  final SessionMetadataDTO? sessionMetadata;

  ActivityProgressRequestDTO({
    required this.sessionId,
    required this.progressPercentage,
    required this.positionSeconds,
    this.deviceId,
    this.sessionMetadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'progressPercentage': progressPercentage,
      'positionSeconds': positionSeconds,
      if (deviceId != null) 'deviceId': deviceId,
      if (sessionMetadata != null) 'sessionMetadata': sessionMetadata?.toJson(),
    };
  }
}

class SessionMetadataDTO {
  final String? deviceInfo;
  final String? appVersion;
  final String? osVersion;
  final String? networkType;
  final double? batteryLevel;
  final String? location;

  SessionMetadataDTO({
    this.deviceInfo,
    this.appVersion,
    this.osVersion,
    this.networkType,
    this.batteryLevel,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (appVersion != null) 'appVersion': appVersion,
      if (osVersion != null) 'osVersion': osVersion,
      if (networkType != null) 'networkType': networkType,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (location != null) 'location': location,
    };
  }
}

// ============ DTO POUR L'ÉVALUATION ============

class ActivityRatingRequestDTO {
  final int rating;
  final String? feedback;
  final int? difficultyPerception;
  final int? enjoymentScore;

  ActivityRatingRequestDTO({
    required this.rating,
    this.feedback,
    this.difficultyPerception,
    this.enjoymentScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (feedback != null) 'feedback': feedback,
      if (difficultyPerception != null)
        'difficultyPerception': difficultyPerception,
      if (enjoymentScore != null) 'enjoymentScore': enjoymentScore,
    };
  }
}

// ============ DTO POUR LES CATÉGORIES ============

class CategoryDTO {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final int displayOrder;
  final bool isActive;
  final int activityCount;
  final int totalCompletions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CategoryDTO({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconName,
    this.colorHex,
    this.displayOrder = 0,
    this.isActive = true,
    this.activityCount = 0,
    this.totalCompletions = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory CategoryDTO.fromJson(Map<String, dynamic> json) {
    return CategoryDTO(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      activityCount: json['activityCount'] as int? ?? 0,
      totalCompletions: json['totalCompletions'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (description != null) 'description': description,
      if (iconName != null) 'iconName': iconName,
      if (colorHex != null) 'colorHex': colorHex,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'activityCount': activityCount,
      'totalCompletions': totalCompletions,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

// ============ DTO POUR LES STATISTIQUES ============

class ActivityStatsResponseDTO {
  final UserStatsDTO? userStats;
  final List<CategoryStatsDTO>? categoryStats;
  final List<DailyCompletionDTO>? dailyCompletions;
  final List<PopularActivityDTO>? popularActivities;
  final StreakInfoDTO? streakInfo;
  final Map<String, dynamic>? insights;

  ActivityStatsResponseDTO({
    this.userStats,
    this.categoryStats,
    this.dailyCompletions,
    this.popularActivities,
    this.streakInfo,
    this.insights,
  });

  factory ActivityStatsResponseDTO.fromJson(Map<String, dynamic> json) {
    return ActivityStatsResponseDTO(
      userStats: json['userStats'] != null
          ? UserStatsDTO.fromJson(json['userStats'] as Map<String, dynamic>)
          : null,
      categoryStats: json['categoryStats'] != null
          ? (json['categoryStats'] as List<dynamic>)
                .map(
                  (e) => CategoryStatsDTO.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      dailyCompletions: json['dailyCompletions'] != null
          ? (json['dailyCompletions'] as List<dynamic>)
                .map(
                  (e) => DailyCompletionDTO.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      popularActivities: json['popularActivities'] != null
          ? (json['popularActivities'] as List<dynamic>)
                .map(
                  (e) => PopularActivityDTO.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
      streakInfo: json['streakInfo'] != null
          ? StreakInfoDTO.fromJson(json['streakInfo'] as Map<String, dynamic>)
          : null,
      insights: json['insights'] as Map<String, dynamic>?,
    );
  }
}

class UserStatsDTO {
  final int totalActivities;
  final int completedActivities;
  final int totalTimeSpent;
  final int currentStreak;
  final int bestStreak;
  final double averageRating;
  final Map<String, int>? categoryDistribution;

  UserStatsDTO({
    required this.totalActivities,
    required this.completedActivities,
    required this.totalTimeSpent,
    required this.currentStreak,
    required this.bestStreak,
    required this.averageRating,
    this.categoryDistribution,
  });

  factory UserStatsDTO.fromJson(Map<String, dynamic> json) {
    return UserStatsDTO(
      totalActivities: json['totalActivities'] as int,
      completedActivities: json['completedActivities'] as int,
      totalTimeSpent: json['totalTimeSpent'] as int,
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      categoryDistribution: json['categoryDistribution'] as Map<String, int>?,
    );
  }
}

class CategoryStatsDTO {
  final int categoryId;
  final String categoryName;
  final int activityCount;
  final int completionCount;
  final double averageRating;

  CategoryStatsDTO({
    required this.categoryId,
    required this.categoryName,
    required this.activityCount,
    required this.completionCount,
    required this.averageRating,
  });

  factory CategoryStatsDTO.fromJson(Map<String, dynamic> json) {
    return CategoryStatsDTO(
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      activityCount: json['activityCount'] as int,
      completionCount: json['completionCount'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }
}

class DailyCompletionDTO {
  final DateTime date;
  final int count;

  DailyCompletionDTO({required this.date, required this.count});

  factory DailyCompletionDTO.fromJson(Map<String, dynamic> json) {
    return DailyCompletionDTO(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int,
    );
  }
}

class PopularActivityDTO {
  final int activityId;
  final String activityTitle;
  final int completionCount;
  final double averageRating;

  PopularActivityDTO({
    required this.activityId,
    required this.activityTitle,
    required this.completionCount,
    required this.averageRating,
  });

  factory PopularActivityDTO.fromJson(Map<String, dynamic> json) {
    return PopularActivityDTO(
      activityId: json['activityId'] as int,
      activityTitle: json['activityTitle'] as String,
      completionCount: json['completionCount'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }
}

class StreakInfoDTO {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastActivityDate;
  final bool isStreakActive;

  StreakInfoDTO({
    required this.currentStreak,
    required this.bestStreak,
    this.lastActivityDate,
    required this.isStreakActive,
  });

  factory StreakInfoDTO.fromJson(Map<String, dynamic> json) {
    return StreakInfoDTO(
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate'] as String)
          : null,
      isStreakActive: json['isStreakActive'] as bool,
    );
  }
}

// ============ DTO POUR L'ACTIVITÉ UTILISATEUR ============

class UserActivityResponseDTO {
  final int id;
  final ActivityResponseDTO activity;
  final int progressPercentage;
  final String completionStatus;
  final bool isCompleted;
  final DateTime? completedAt;
  final int? completionDurationSeconds;
  final String? completionDurationDisplay;
  final int? userRating;
  final String? userFeedback;
  final int? difficultyPerception;
  final int? enjoymentScore;
  final int attemptCount;
  final int totalTimeSpentSeconds;
  final String? totalTimeSpentDisplay;
  final int streakCount;
  final int bestStreak;
  final int consecutiveDays;
  final bool isFavorite;
  final bool isBookmarked;
  final String? customNotes;
  final bool customReminderEnabled;
  final String? customReminderTime;
  final DateTime? lastAttemptedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserActivityResponseDTO({
    required this.id,
    required this.activity,
    required this.progressPercentage,
    required this.completionStatus,
    required this.isCompleted,
    this.completedAt,
    this.completionDurationSeconds,
    this.completionDurationDisplay,
    this.userRating,
    this.userFeedback,
    this.difficultyPerception,
    this.enjoymentScore,
    required this.attemptCount,
    required this.totalTimeSpentSeconds,
    this.totalTimeSpentDisplay,
    required this.streakCount,
    required this.bestStreak,
    required this.consecutiveDays,
    required this.isFavorite,
    required this.isBookmarked,
    this.customNotes,
    required this.customReminderEnabled,
    this.customReminderTime,
    this.lastAttemptedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserActivityResponseDTO.fromJson(Map<String, dynamic> json) {
    return UserActivityResponseDTO(
      id: json['id'] as int,
      activity: ActivityResponseDTO.fromJson(
        json['activity'] as Map<String, dynamic>,
      ),
      progressPercentage: json['progressPercentage'] as int,
      completionStatus: json['completionStatus'] as String,
      isCompleted: json['isCompleted'] as bool,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      completionDurationSeconds: json['completionDurationSeconds'] as int?,
      completionDurationDisplay: json['completionDurationDisplay'] as String?,
      userRating: json['userRating'] as int?,
      userFeedback: json['userFeedback'] as String?,
      difficultyPerception: json['difficultyPerception'] as int?,
      enjoymentScore: json['enjoymentScore'] as int?,
      attemptCount: json['attemptCount'] as int,
      totalTimeSpentSeconds: json['totalTimeSpentSeconds'] as int,
      totalTimeSpentDisplay: json['totalTimeSpentDisplay'] as String?,
      streakCount: json['streakCount'] as int,
      bestStreak: json['bestStreak'] as int,
      consecutiveDays: json['consecutiveDays'] as int,
      isFavorite: json['isFavorite'] as bool,
      isBookmarked: json['isBookmarked'] as bool,
      customNotes: json['customNotes'] as String?,
      customReminderEnabled: json['customReminderEnabled'] as bool,
      customReminderTime: json['customReminderTime'] as String?,
      lastAttemptedAt: json['lastAttemptedAt'] != null
          ? DateTime.parse(json['lastAttemptedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity': activity.toJson(),
      'progressPercentage': progressPercentage,
      'completionStatus': completionStatus,
      'isCompleted': isCompleted,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (completionDurationSeconds != null)
        'completionDurationSeconds': completionDurationSeconds,
      if (completionDurationDisplay != null)
        'completionDurationDisplay': completionDurationDisplay,
      if (userRating != null) 'userRating': userRating,
      if (userFeedback != null) 'userFeedback': userFeedback,
      if (difficultyPerception != null)
        'difficultyPerception': difficultyPerception,
      if (enjoymentScore != null) 'enjoymentScore': enjoymentScore,
      'attemptCount': attemptCount,
      'totalTimeSpentSeconds': totalTimeSpentSeconds,
      if (totalTimeSpentDisplay != null)
        'totalTimeSpentDisplay': totalTimeSpentDisplay,
      'streakCount': streakCount,
      'bestStreak': bestStreak,
      'consecutiveDays': consecutiveDays,
      'isFavorite': isFavorite,
      'isBookmarked': isBookmarked,
      if (customNotes != null) 'customNotes': customNotes,
      'customReminderEnabled': customReminderEnabled,
      if (customReminderTime != null) 'customReminderTime': customReminderTime,
      if (lastAttemptedAt != null)
        'lastAttemptedAt': lastAttemptedAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

// ============ ENUMS (POUR COMPATIBILITÉ) ============

enum ActivityStatus {
  DRAFT('Brouillon'),
  REVIEW('En revue'),
  PUBLISHED('Publié'),
  ARCHIVED('Archivé'),
  DELETED('Supprimé');

  final String displayName;
  const ActivityStatus(this.displayName);

  static ActivityStatus? fromString(String value) {
    for (var status in ActivityStatus.values) {
      if (status.name == value.toUpperCase()) {
        return status;
      }
    }
    return null;
  }
}

enum DifficultyLevel {
  BEGINNER('Débutant'),
  INTERMEDIATE('Intermédiaire'),
  ADVANCED('Avancé');

  final String displayName;
  const DifficultyLevel(this.displayName);

  static DifficultyLevel? fromString(String value) {
    for (var level in DifficultyLevel.values) {
      if (level.name == value.toUpperCase()) {
        return level;
      }
    }
    return null;
  }
}

enum CompletionStatus {
  NOT_STARTED('Non commencé'),
  IN_PROGRESS('En cours'),
  COMPLETED('Terminé'),
  ABANDONED('Abandonné');

  final String displayName;
  const CompletionStatus(this.displayName);

  static CompletionStatus? fromString(String value) {
    for (var status in CompletionStatus.values) {
      if (status.name == value.replaceAll(' ', '_').toUpperCase()) {
        return status;
      }
    }
    return null;
  }
}
