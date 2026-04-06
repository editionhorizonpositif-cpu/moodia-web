class ChallengeParticipation {
  final int id;
  final int challengeId;
  final String challengeTitle;
  final int userId;
  final String username;
  final String status;
  final DateTime joinedAt;
  final DateTime? completedAt;
  final int progressPercentage;
  final int streakDays;
  final DateTime lastActivityAt;
  final String? notes;
  final int? pointsEarned;
  final int? xpEarned;
  final int? daysRemaining;
  final double? dailyAverageProgress;
  final bool? isChallengeActive;
  final DateTime? challengeEndDate;

  ChallengeParticipation({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.userId,
    required this.username,
    required this.status,
    required this.joinedAt,
    this.completedAt,
    required this.progressPercentage,
    required this.streakDays,
    required this.lastActivityAt,
    this.notes,
    this.pointsEarned,
    this.xpEarned,
    this.daysRemaining,
    this.dailyAverageProgress,
    this.isChallengeActive,
    this.challengeEndDate,
  });

  factory ChallengeParticipation.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipation(
      id: json['id'] as int,
      challengeId: json['challengeId'] as int,
      challengeTitle: json['challengeTitle'] as String,
      userId: json['userId'] as int,
      username: json['username'] as String,
      status: json['status'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      progressPercentage: json['progressPercentage'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      notes: json['notes'] as String?,
      pointsEarned: json['pointsEarned'] as int?,
      xpEarned: json['xpEarned'] as int?,
      daysRemaining: json['daysRemaining'] as int?,
      dailyAverageProgress: (json['dailyAverageProgress'] as num?)?.toDouble(),
      isChallengeActive: json['isChallengeActive'] as bool?,
      challengeEndDate: json['challengeEndDate'] != null
          ? DateTime.parse(json['challengeEndDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'userId': userId,
      'username': username,
      'status': status,
      'joinedAt': joinedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'progressPercentage': progressPercentage,
      'streakDays': streakDays,
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'notes': notes,
      'pointsEarned': pointsEarned,
      'xpEarned': xpEarned,
      'daysRemaining': daysRemaining,
      'dailyAverageProgress': dailyAverageProgress,
      'isChallengeActive': isChallengeActive,
      'challengeEndDate': challengeEndDate?.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isAbandoned => status == 'ABANDONED';
  int get remainingPercentage => 100 - progressPercentage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeParticipation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
