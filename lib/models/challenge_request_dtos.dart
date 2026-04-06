class CreateChallengeRequest {
  final String title;
  final String description;
  final String? instructions;
  final int categoryId;
  final String difficultyLevel;
  final int? vibrationLevel;
  final int? pointsReward;
  final int? xpReward;
  final int? streakDays;
  final int? durationMinutes;
  final int? maxParticipants;
  final bool isFeatured;
  final bool isPremium;
  final List<String>? tags;
  final List<String>? requirements;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? imageUrl;
  final String? icon;
  final String? colorCode;
  final String? reminderFrequency;
  final bool? hasReminder;
  final bool? requiresApproval;
  final DurationRequest? duration;

  CreateChallengeRequest({
    required this.title,
    required this.description,
    this.instructions,
    required this.categoryId,
    required this.difficultyLevel,
    this.vibrationLevel,
    this.pointsReward,
    this.xpReward,
    this.streakDays,
    this.durationMinutes,
    this.maxParticipants,
    this.isFeatured = false,
    this.isPremium = false,
    this.tags,
    this.requirements,
    this.startsAt,
    this.endsAt,
    this.imageUrl,
    this.icon,
    this.colorCode,
    this.reminderFrequency,
    this.hasReminder = false,
    this.requiresApproval = false,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'instructions': instructions,
      'categoryId': categoryId,
      'difficultyLevel': difficultyLevel,
      'vibrationLevel': vibrationLevel,
      'pointsReward': pointsReward,
      'xpReward': xpReward,
      'streakDays': streakDays,
      'durationMinutes': durationMinutes,
      'maxParticipants': maxParticipants,
      'isFeatured': isFeatured,
      'isPremium': isPremium,
      'tags': tags,
      'requirements': requirements,
      'startsAt': startsAt?.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'icon': icon,
      'colorCode': colorCode,
      'reminderFrequency': reminderFrequency,
      'hasReminder': hasReminder,
      'requiresApproval': requiresApproval,
      'duration': duration?.toJson(),
    };
    return map;
  }
}

class DurationRequest {
  final int? value;
  final String? unit;

  DurationRequest({this.value, this.unit});

  Map<String, dynamic> toJson() {
    return {'value': value, 'unit': unit};
  }
}

class UpdateChallengeRequest {
  final String? title;
  final String? description;
  final String? instructions;
  final int? categoryId;
  final String? difficultyLevel;
  final String? status;
  final int? vibrationLevel;
  final int? pointsReward;
  final int? xpReward;
  final int? streakDays;
  final int? durationMinutes;
  final int? maxParticipants;
  final bool? isFeatured;
  final bool? isPremium;
  final List<String>? tags;
  final List<String>? requirements;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? imageUrl;
  final String? icon;
  final String? colorCode;
  final String? reminderFrequency;
  final bool? hasReminder;
  final bool? requiresApproval;
  final DurationRequest? duration;

  UpdateChallengeRequest({
    this.title,
    this.description,
    this.instructions,
    this.categoryId,
    this.difficultyLevel,
    this.status,
    this.vibrationLevel,
    this.pointsReward,
    this.xpReward,
    this.streakDays,
    this.durationMinutes,
    this.maxParticipants,
    this.isFeatured,
    this.isPremium,
    this.tags,
    this.requirements,
    this.startsAt,
    this.endsAt,
    this.imageUrl,
    this.icon,
    this.colorCode,
    this.reminderFrequency,
    this.hasReminder,
    this.requiresApproval,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (instructions != null) map['instructions'] = instructions;
    if (categoryId != null) map['categoryId'] = categoryId;
    if (difficultyLevel != null) map['difficultyLevel'] = difficultyLevel;
    if (status != null) map['status'] = status;
    if (vibrationLevel != null) map['vibrationLevel'] = vibrationLevel;
    if (pointsReward != null) map['pointsReward'] = pointsReward;
    if (xpReward != null) map['xpReward'] = xpReward;
    if (streakDays != null) map['streakDays'] = streakDays;
    if (durationMinutes != null) map['durationMinutes'] = durationMinutes;
    if (maxParticipants != null) map['maxParticipants'] = maxParticipants;
    if (isFeatured != null) map['isFeatured'] = isFeatured;
    if (isPremium != null) map['isPremium'] = isPremium;
    if (tags != null) map['tags'] = tags;
    if (requirements != null) map['requirements'] = requirements;
    if (startsAt != null) map['startsAt'] = startsAt!.toIso8601String();
    if (endsAt != null) map['endsAt'] = endsAt!.toIso8601String();
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (icon != null) map['icon'] = icon;
    if (colorCode != null) map['colorCode'] = colorCode;
    if (reminderFrequency != null) map['reminderFrequency'] = reminderFrequency;
    if (hasReminder != null) map['hasReminder'] = hasReminder;
    if (requiresApproval != null) map['requiresApproval'] = requiresApproval;
    if (duration != null) map['duration'] = duration!.toJson();
    return map;
  }
}

class ChallengeParticipationRequest {
  final int userId;
  final String? notes;

  ChallengeParticipationRequest({required this.userId, this.notes});

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'notes': notes};
  }
}

class ChallengeProgressRequest {
  final int progressValue;
  final String? notes;
  final bool isMilestone;
  final String? milestoneName;

  ChallengeProgressRequest({
    required this.progressValue,
    this.notes,
    this.isMilestone = false,
    this.milestoneName,
  });

  Map<String, dynamic> toJson() {
    return {
      'progressValue': progressValue,
      'notes': notes,
      'isMilestone': isMilestone,
      'milestoneName': milestoneName,
    };
  }
}

class ChallengeCompletionRequest {
  final int rating;
  final String? feedback;
  final int? difficultyRating;
  final int? enjoymentRating;
  final String? learningOutcome;
  final String? keyAchievements;
  final String? challengesFaced;
  final bool? wouldRecommend;
  final bool? wouldRepeat;
  final int? moodImprovement;
  final int? confidenceGain;
  final int? stressReduction;
  final int? timeInvestedMinutes;
  final int? daysConsistent;
  final int? daysMissed;
  final bool shareOnFeed;
  final bool isPublic;
  final String? notes;
  final bool isMilestone;
  final String? milestoneName;

  ChallengeCompletionRequest({
    required this.rating,
    this.feedback,
    this.difficultyRating,
    this.enjoymentRating,
    this.learningOutcome,
    this.keyAchievements,
    this.challengesFaced,
    this.wouldRecommend,
    this.wouldRepeat,
    this.moodImprovement,
    this.confidenceGain,
    this.stressReduction,
    this.timeInvestedMinutes,
    this.daysConsistent,
    this.daysMissed,
    this.shareOnFeed = false,
    this.isPublic = false,
    this.notes,
    this.isMilestone = false,
    this.milestoneName,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'feedback': feedback,
      'difficultyRating': difficultyRating,
      'enjoymentRating': enjoymentRating,
      'learningOutcome': learningOutcome,
      'keyAchievements': keyAchievements,
      'challengesFaced': challengesFaced,
      'wouldRecommend': wouldRecommend,
      'wouldRepeat': wouldRepeat,
      'moodImprovement': moodImprovement,
      'confidenceGain': confidenceGain,
      'stressReduction': stressReduction,
      'timeInvestedMinutes': timeInvestedMinutes,
      'daysConsistent': daysConsistent,
      'daysMissed': daysMissed,
      'shareOnFeed': shareOnFeed,
      'isPublic': isPublic,
      'notes': notes,
      'isMilestone': isMilestone,
      'milestoneName': milestoneName,
    };
  }
}

class ChallengeCategoryRequest {
  final String name;
  final String? description;
  final String? icon;
  final String? colorCode;
  final int? sortOrder;
  final bool? isActive;

  ChallengeCategoryRequest({
    required this.name,
    this.description,
    this.icon,
    this.colorCode,
    this.sortOrder,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'colorCode': colorCode,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}
