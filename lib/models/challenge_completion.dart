class ChallengeCompletion {
  final int id;
  final int challengeId;
  final String challengeTitle;
  final int userId;
  final String username;
  final String? challengeImageUrl;
  final DateTime completedAt;
  final int? completionTimeDays;
  final int? finalProgressPercentage;
  final int? finalStreakDays;
  final int? pointsEarned;
  final int? xpEarned;
  final int? rating;
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
  final String? completionLevel;
  final double? overallRating;
  final String? timeCategory;
  final int? wellBeingScore;
  final bool? isPerfectCompletion;
  final double? consistencyRate;
  final int? timeInvestedMinutes;
  final int? daysConsistent;
  final int? daysMissed;
  final bool? certificateIssued;
  final String? certificateUrl;
  final String? badgesEarned;
  final bool? shareOnFeed;
  final bool? isPublic;
  final bool? isMilestone;
  final String? milestoneName;
  final String? notes;
  final double? recommendationPercentage;
  final double? challengeAverageRating;

  ChallengeCompletion({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.userId,
    required this.username,
    this.challengeImageUrl,
    required this.completedAt,
    this.completionTimeDays,
    this.finalProgressPercentage,
    this.finalStreakDays,
    this.pointsEarned,
    this.xpEarned,
    this.rating,
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
    this.completionLevel,
    this.overallRating,
    this.timeCategory,
    this.wellBeingScore,
    this.isPerfectCompletion,
    this.consistencyRate,
    this.timeInvestedMinutes,
    this.daysConsistent,
    this.daysMissed,
    this.certificateIssued,
    this.certificateUrl,
    this.badgesEarned,
    this.shareOnFeed,
    this.isPublic,
    this.isMilestone,
    this.milestoneName,
    this.notes,
    this.recommendationPercentage,
    this.challengeAverageRating,
  });

  factory ChallengeCompletion.fromJson(Map<String, dynamic> json) {
    return ChallengeCompletion(
      id: json['id'] as int,
      challengeId: json['challengeId'] as int,
      challengeTitle: json['challengeTitle'] as String,
      userId: json['userId'] as int,
      username: json['username'] as String,
      challengeImageUrl: json['challengeImageUrl'] as String?,
      completedAt: DateTime.parse(json['completedAt'] as String),
      completionTimeDays: json['completionTimeDays'] as int?,
      finalProgressPercentage: json['finalProgressPercentage'] as int?,
      finalStreakDays: json['finalStreakDays'] as int?,
      pointsEarned: json['pointsEarned'] as int?,
      xpEarned: json['xpEarned'] as int?,
      rating: json['rating'] as int?,
      feedback: json['feedback'] as String?,
      difficultyRating: json['difficultyRating'] as int?,
      enjoymentRating: json['enjoymentRating'] as int?,
      learningOutcome: json['learningOutcome'] as String?,
      keyAchievements: json['keyAchievements'] as String?,
      challengesFaced: json['challengesFaced'] as String?,
      wouldRecommend: json['wouldRecommend'] as bool?,
      wouldRepeat: json['wouldRepeat'] as bool?,
      moodImprovement: json['moodImprovement'] as int?,
      confidenceGain: json['confidenceGain'] as int?,
      stressReduction: json['stressReduction'] as int?,
      completionLevel: json['completionLevel'] as String?,
      overallRating: (json['overallRating'] as num?)?.toDouble(),
      timeCategory: json['timeCategory'] as String?,
      wellBeingScore: json['wellBeingScore'] as int?,
      isPerfectCompletion: json['isPerfectCompletion'] as bool?,
      consistencyRate: (json['consistencyRate'] as num?)?.toDouble(),
      timeInvestedMinutes: json['timeInvestedMinutes'] as int?,
      daysConsistent: json['daysConsistent'] as int?,
      daysMissed: json['daysMissed'] as int?,
      certificateIssued: json['certificateIssued'] as bool?,
      certificateUrl: json['certificateUrl'] as String?,
      badgesEarned: json['badgesEarned'] as String?,
      shareOnFeed: json['shareOnFeed'] as bool?,
      isPublic: json['isPublic'] as bool?,
      isMilestone: json['isMilestone'] as bool?,
      milestoneName: json['milestoneName'] as String?,
      notes: json['notes'] as String?,
      recommendationPercentage: (json['recommendationPercentage'] as num?)
          ?.toDouble(),
      challengeAverageRating: (json['challengeAverageRating'] as num?)
          ?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'userId': userId,
      'username': username,
      'challengeImageUrl': challengeImageUrl,
      'completedAt': completedAt.toIso8601String(),
      'completionTimeDays': completionTimeDays,
      'finalProgressPercentage': finalProgressPercentage,
      'finalStreakDays': finalStreakDays,
      'pointsEarned': pointsEarned,
      'xpEarned': xpEarned,
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
      'completionLevel': completionLevel,
      'overallRating': overallRating,
      'timeCategory': timeCategory,
      'wellBeingScore': wellBeingScore,
      'isPerfectCompletion': isPerfectCompletion,
      'consistencyRate': consistencyRate,
      'timeInvestedMinutes': timeInvestedMinutes,
      'daysConsistent': daysConsistent,
      'daysMissed': daysMissed,
      'certificateIssued': certificateIssued,
      'certificateUrl': certificateUrl,
      'badgesEarned': badgesEarned,
      'shareOnFeed': shareOnFeed,
      'isPublic': isPublic,
      'isMilestone': isMilestone,
      'milestoneName': milestoneName,
      'notes': notes,
      'recommendationPercentage': recommendationPercentage,
      'challengeAverageRating': challengeAverageRating,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeCompletion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
