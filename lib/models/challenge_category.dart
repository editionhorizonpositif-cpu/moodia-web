class ChallengeCategory {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final String? colorCode;
  final int? sortOrder;
  final int? activeChallengesCount;
  final int? totalParticipants;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChallengeCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.colorCode,
    this.sortOrder,
    this.activeChallengesCount,
    this.totalParticipants,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ChallengeCategory.fromJson(Map<String, dynamic> json) {
    return ChallengeCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      colorCode: json['colorCode'] as String?,
      sortOrder: json['sortOrder'] as int?,
      activeChallengesCount: (json['activeChallengesCount'] as num?)?.toInt(),
      totalParticipants: (json['totalParticipants'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
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
      'description': description,
      'icon': icon,
      'colorCode': colorCode,
      'sortOrder': sortOrder,
      'activeChallengesCount': activeChallengesCount,
      'totalParticipants': totalParticipants,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
