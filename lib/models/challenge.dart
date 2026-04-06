import 'package:flutter/material.dart';

class Challenge {
  final int id;
  final String title;
  final String description;
  final String? instructions;
  final int categoryId;
  final String categoryName;
  final String difficultyLevel;
  final String status;
  final int? vibrationLevel;
  final int? pointsReward;
  final int? xpReward;
  final int? streakDays;
  final int? durationMinutes;
  final double? completionRate;
  final int? maxParticipants;
  final int currentParticipants;
  final int? remainingSlots;
  final bool isFeatured;
  final bool isPremium;
  final bool isActive;
  final List<String> tags;
  final List<String> requirements;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? imageUrl;
  final String? icon;
  final String? colorCode;
  final bool? hasJoined;
  final int? userProgress;
  final String? participationStatus;
  final DurationResponse? duration;
  final double? successRate;
  final bool? isOngoing;
  final bool? isUpcoming;
  final bool? isExpired;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    this.instructions,
    required this.categoryId,
    required this.categoryName,
    required this.difficultyLevel,
    required this.status,
    this.vibrationLevel,
    this.pointsReward,
    this.xpReward,
    this.streakDays,
    this.durationMinutes,
    this.completionRate,
    this.maxParticipants,
    required this.currentParticipants,
    this.remainingSlots,
    required this.isFeatured,
    required this.isPremium,
    required this.isActive,
    required this.tags,
    required this.requirements,
    required this.createdAt,
    required this.updatedAt,
    this.startsAt,
    this.endsAt,
    this.imageUrl,
    this.icon,
    this.colorCode,
    this.hasJoined,
    this.userProgress,
    this.participationStatus,
    this.duration,
    this.successRate,
    this.isOngoing,
    this.isUpcoming,
    this.isExpired,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      instructions: json['instructions'] as String?,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      difficultyLevel: json['difficultyLevel'] as String,
      status: json['status'] as String,
      vibrationLevel: json['vibrationLevel'] as int?,
      pointsReward: json['pointsReward'] as int?,
      xpReward: json['xpReward'] as int?,
      streakDays: json['streakDays'] as int?,
      durationMinutes: json['durationMinutes'] as int?,
      completionRate: (json['completionRate'] as num?)?.toDouble(),
      maxParticipants: json['maxParticipants'] as int?,
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      remainingSlots: json['remainingSlots'] as int?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      requirements:
          (json['requirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      startsAt: json['startsAt'] != null
          ? DateTime.parse(json['startsAt'] as String)
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.parse(json['endsAt'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      icon: json['icon'] as String?,
      colorCode: json['colorCode'] as String?,
      hasJoined: json['hasJoined'] as bool?,
      userProgress: json['userProgress'] as int?,
      participationStatus: json['participationStatus'] as String?,
      duration: json['duration'] != null
          ? DurationResponse.fromJson(json['duration'])
          : null,
      successRate: (json['successRate'] as num?)?.toDouble(),
      isOngoing: json['isOngoing'] as bool?,
      isUpcoming: json['isUpcoming'] as bool?,
      isExpired: json['isExpired'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructions': instructions,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'difficultyLevel': difficultyLevel,
      'status': status,
      'vibrationLevel': vibrationLevel,
      'pointsReward': pointsReward,
      'xpReward': xpReward,
      'streakDays': streakDays,
      'durationMinutes': durationMinutes,
      'completionRate': completionRate,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'remainingSlots': remainingSlots,
      'isFeatured': isFeatured,
      'isPremium': isPremium,
      'isActive': isActive,
      'tags': tags,
      'requirements': requirements,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'startsAt': startsAt?.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'icon': icon,
      'colorCode': colorCode,
      'hasJoined': hasJoined,
      'userProgress': userProgress,
      'participationStatus': participationStatus,
      'duration': duration?.toJson(),
      'successRate': successRate,
      'isOngoing': isOngoing,
      'isUpcoming': isUpcoming,
      'isExpired': isExpired,
    };
  }

  // ==================== MÉTHODES DE LOGIQUE MÉTIER ====================

  /// Vérifie si le défi est actif et disponible
  bool isActiveM() {
    final now = DateTime.now();
    final withinTimeFrame =
        (startsAt == null || now.isAfter(startsAt!)) &&
        (endsAt == null || now.isBefore(endsAt!));
    return status == 'ACTIVE' && withinTimeFrame && isActive;
  }

  /// Vérifie s'il reste des places disponibles
  bool hasAvailableSlots() {
    if (maxParticipants == null) return true;
    return currentParticipants < maxParticipants!;
  }

  /// Vérifie si l'utilisateur peut rejoindre le défi
  /// Vérifie si l'utilisateur peut rejoindre le défi
  /// Vérifie si l'utilisateur peut rejoindre le défi
  bool canJoin() {
    // Si l'utilisateur a explicitement rejoint, il ne peut pas rejoindre
    if (hasJoined == true) return false;

    // Si l'utilisateur a un statut de participation qui indique une participation active
    if (participationStatus == 'IN_PROGRESS' ||
        participationStatus == 'COMPLETED' ||
        participationStatus == 'ABANDONED') {
      return false;
    }

    // Vérifier si le défi est actif et disponible
    return isActiveM() && hasAvailableSlots();
  }

  /// Retourne le statut de participation de l'utilisateur
  String getParticipationStatus() {
    if (hasJoined == true) {
      return participationStatus ?? 'JOINED';
    }
    return 'NOT_JOINED';
  }

  /// Détermine si le bouton "Rejoindre" doit être affiché
  bool shouldShowJoinButton() {
    // Ne pas afficher si déjà rejoint
    if (hasJoined == true) return false;

    // Ne pas afficher si déjà en progression
    if (participationStatus == 'IN_PROGRESS' ||
        participationStatus == 'COMPLETED') {
      return false;
    }

    // Afficher seulement si le défi est joignable
    return canJoin();
  }

  /// Retourne le texte du bouton en fonction de l'état
  String getActionButtonText() {
    if (hasJoined == true) {
      if (participationStatus == 'COMPLETED') {
        return 'Donner mon avis';
      }
      return 'Mettre à jour';
    }

    if (!hasAvailableSlots()) {
      return 'Complet';
    }

    if (!isActiveM()) {
      return 'Non disponible';
    }

    return 'Rejoindre le défi';
  }

  /// Vérifie si le défi est en cours
  bool isOngoingNow() {
    final now = DateTime.now();
    return (startsAt == null || now.isAfter(startsAt!)) &&
        (endsAt == null || now.isBefore(endsAt!));
  }

  /// Vérifie si le défi est à venir
  bool isUpcomingNow() {
    return startsAt != null && DateTime.now().isBefore(startsAt!);
  }

  /// Vérifie si le défi est expiré
  bool isExpiredNow() {
    return endsAt != null && DateTime.now().isAfter(endsAt!);
  }

  /// Calcule le pourcentage de progression (si utilisateur connecté)
  double getProgressPercentage() {
    if (userProgress != null) {
      return userProgress!.toDouble();
    }
    return 0.0;
  }

  /// Obtient le libellé de difficulté en français
  String getDifficultyLabel() {
    switch (difficultyLevel) {
      case 'BEGINNER':
        return 'Débutant';
      case 'EASY':
        return 'Facile';
      case 'MEDIUM':
        return 'Intermédiaire';
      case 'HARD':
        return 'Difficile';
      case 'EXPERT':
        return 'Expert';
      case 'MASTER':
        return 'Maître';
      default:
        return difficultyLevel;
    }
  }

  /// Obtient la couleur associée à la difficulté
  Color getDifficultyColor() {
    switch (difficultyLevel) {
      case 'BEGINNER':
        return Colors.green;
      case 'EASY':
        return Colors.lightGreen;
      case 'MEDIUM':
        return Colors.orange;
      case 'HARD':
        return Colors.deepOrange;
      case 'EXPERT':
        return Colors.red;
      case 'MASTER':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Obtient le libellé du statut en français
  String getStatusLabel() {
    switch (status) {
      case 'DRAFT':
        return 'Brouillon';
      case 'ACTIVE':
        return 'Actif';
      case 'PAUSED':
        return 'En pause';
      case 'COMPLETED':
        return 'Terminé';
      case 'ARCHIVED':
        return 'Archivé';
      case 'CANCELLED':
        return 'Annulé';
      default:
        return status;
    }
  }

  /// Obtient la couleur associée au statut
  Color getStatusColor() {
    switch (status) {
      case 'DRAFT':
        return Colors.grey;
      case 'ACTIVE':
        return Colors.green;
      case 'PAUSED':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.blue;
      case 'ARCHIVED':
        return Colors.brown;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Formate la durée pour l'affichage
  String formatDuration() {
    if (durationMinutes != null) {
      return '$durationMinutes minutes';
    }
    if (duration != null && duration!.value != null) {
      final unit = duration!.unit?.toLowerCase() ?? '';
      return '${duration!.value} ${_translateUnit(unit)}';
    }
    return 'Flexible';
  }

  String _translateUnit(String unit) {
    switch (unit) {
      case 'minutes':
        return 'minutes';
      case 'hours':
        return 'heures';
      case 'days':
        return 'jours';
      case 'weeks':
        return 'semaines';
      case 'months':
        return 'mois';
      default:
        return unit;
    }
  }

  /// Calcule les jours restants avant la fin
  int? getRemainingDays() {
    if (endsAt == null) return null;
    return endsAt!.difference(DateTime.now()).inDays;
  }

  @override
  String toString() {
    return 'Challenge{id: $id, title: $title, difficultyLevel: $difficultyLevel}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Challenge && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DurationResponse {
  final int? value;
  final String? unit;

  DurationResponse({this.value, this.unit});

  factory DurationResponse.fromJson(Map<String, dynamic> json) {
    return DurationResponse(
      value: json['value'] as int?,
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'value': value, 'unit': unit};
  }
}
