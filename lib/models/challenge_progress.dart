class ChallengeProgress {
  final int id;
  final int challengeId;
  final int userId;
  final int progressValue;
  final int targetValue;
  final String? unit;
  final String? notes;
  final DateTime recordedAt;
  final bool isMilestone;
  final String? milestoneName;

  ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.progressValue,
    required this.targetValue,
    this.unit,
    this.notes,
    required this.recordedAt,
    required this.isMilestone,
    this.milestoneName,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      id: json['id'] as int,
      challengeId: json['challengeId'] as int,
      userId: json['userId'] as int,
      progressValue: json['progressValue'] as int,
      targetValue: json['targetValue'] as int,
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      isMilestone: json['isMilestone'] as bool? ?? false,
      milestoneName: json['milestoneName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'progressValue': progressValue,
      'targetValue': targetValue,
      'unit': unit,
      'notes': notes,
      'recordedAt': recordedAt.toIso8601String(),
      'isMilestone': isMilestone,
      'milestoneName': milestoneName,
    };
  }

  double get percentage =>
      targetValue > 0 ? (progressValue * 100.0 / targetValue) : 0.0;
  int get remaining => (targetValue - progressValue).clamp(0, targetValue);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeProgress &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
