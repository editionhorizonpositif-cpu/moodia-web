// lib/models/meditation.dart
import 'package:flutter/material.dart';

class Meditation {
  final int? id;
  final String title;
  final String? description;
  final int? audioVideoAssetId;
  final int? posterImageAssetId;
  final int durationMin;
  final String category;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPremium;
  final String? difficultyLevel;
  final List<String>? tags;
  final String? status;
  final int displayOrder;
  final int viewCount;
  final int completionCount;
  final double? averageRating;
  final int ratingCount;
  final String? instructorName;
  final String? languageCode;

  Meditation({
    this.id,
    required this.title,
    this.description,
    this.audioVideoAssetId,
    this.posterImageAssetId,
    required this.durationMin,
    required this.category,
    this.createdAt,
    this.updatedAt,
    this.isPremium = false,
    this.difficultyLevel,
    this.tags,
    this.status = 'DRAFT',
    this.displayOrder = 0,
    this.viewCount = 0,
    this.completionCount = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.instructorName,
    this.languageCode = 'fr',
  });

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
      id: json['id'] as int?,
      title: json['title']?.toString() ?? 'Titre non disponible',
      description: json['description']?.toString(),
      audioVideoAssetId: _parseInt(json['audioVideoAssetId']),
      posterImageAssetId: _parseInt(json['posterImageAssetId']),
      durationMin: _parseInt(json['durationMin']) ?? 10,
      category: json['category']?.toString() ?? 'Général',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isPremium: json['isPremium'] as bool? ?? false,
      difficultyLevel: json['difficultyLevel']?.toString(),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      status: json['status']?.toString(),
      displayOrder: _parseInt(json['displayOrder']) ?? 0,
      viewCount: _parseInt(json['viewCount']) ?? 0,
      completionCount: _parseInt(json['completionCount']) ?? 0,
      averageRating: _parseDouble(json['averageRating']),
      ratingCount: _parseInt(json['ratingCount']) ?? 0,
      instructorName: json['instructorName']?.toString(),
      languageCode: json['languageCode']?.toString() ?? 'fr',
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      print('Erreur parsing date: $e');
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final map = {
      'title': title,
      'description': description,
      'audioVideoAssetId': audioVideoAssetId,
      'posterImageAssetId': posterImageAssetId,
      'durationMin': durationMin,
      'category': category,
      'isPremium': isPremium,
      'difficultyLevel': difficultyLevel,
      'tags': tags,
      'status': status,
      'displayOrder': displayOrder,
      'instructorName': instructorName,
      'languageCode': languageCode,
    };

    if (id != null) {
      map['id'] = id;
    }
    if (createdAt != null) {
      map['createdAt'] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
    }

    return map;
  }

  // Méthode pour créer une requête de création
  Map<String, dynamic> toCreateRequest() {
    return {
      'title': title,
      'description': description,
      'audioVideoAssetId': audioVideoAssetId,
      'posterImageAssetId': posterImageAssetId,
      'durationMin': durationMin,
      'category': category,
      'isPremium': isPremium,
      'difficultyLevel': difficultyLevel,
      'tags': tags,
      'instructorName': instructorName,
      'languageCode': languageCode,
    };
  }

  // Méthode pour créer une requête de mise à jour
  Map<String, dynamic> toUpdateRequest() {
    return {
      'title': title,
      'description': description,
      'durationMin': durationMin,
      'category': category,
      'isPremium': isPremium,
      'difficultyLevel': difficultyLevel,
      'tags': tags,
      'instructorName': instructorName,
      'languageCode': languageCode,
    };
  }

  // Méthode pour formater la durée
  String get formattedDuration {
    if (durationMin >= 60) {
      final hours = durationMin ~/ 60;
      final minutes = durationMin % 60;
      if (minutes > 0) {
        return '$hours h $minutes min';
      }
      return '$hours h';
    }
    return '$durationMin min';
  }

  // Méthode pour obtenir la couleur selon la catégorie
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sommeil':
        return const Color(0xFF6A89CC);
      case 'stress':
        return const Color(0xFFE55039);
      case 'concentration':
        return const Color(0xFF4A69BD);
      case 'matin':
        return const Color(0xFFF6B93B);
      case 'soir':
        return const Color(0xFF3C6382);
      case 'relaxation':
        return const Color(0xFF78E08F);
      case 'anxiété':
        return const Color(0xFFFDA7DF);
      case 'yoga':
        return const Color(0xFFD980FA);
      case 'méditation':
        return const Color(0xFF7DBBC3);
      default:
        return const Color(0xFF7DBBC3);
    }
  }

  // Méthode pour obtenir l'icône selon la catégorie
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sommeil':
        return Icons.nightlight_round;
      case 'stress':
        return Icons.self_improvement;
      case 'concentration':
        return Icons.psychology;
      case 'matin':
        return Icons.wb_sunny;
      case 'soir':
        return Icons.nights_stay;
      case 'relaxation':
        return Icons.spa;
      case 'anxiété':
        return Icons.favorite;
      case 'yoga':
        return Icons.directions_run;
      case 'méditation':
        return Icons.self_improvement;
      default:
        return Icons.music_note;
    }
  }

  // Méthode pour obtenir le niveau en français
  String? get formattedDifficultyLevel {
    if (difficultyLevel == null) return null;
    switch (difficultyLevel!.toLowerCase()) {
      case 'beginner':
        return 'Débutant';
      case 'intermediate':
        return 'Intermédiaire';
      case 'advanced':
        return 'Avancé';
      default:
        return difficultyLevel;
    }
  }

  // Méthode pour obtenir la couleur du niveau
  Color get difficultyColor {
    switch (difficultyLevel?.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Méthode pour formater la note
  String? get formattedRating {
    if (averageRating == null) return null;
    return averageRating!.toStringAsFixed(1);
  }

  // Méthode pour obtenir le statut en français
  String? get formattedStatus {
    if (status == null) return null;
    switch (status!.toUpperCase()) {
      case 'DRAFT':
        return 'Brouillon';
      case 'PUBLISHED':
        return 'Publié';
      case 'ARCHIVED':
        return 'Archivé';
      case 'SCHEDULED':
        return 'Programmé';
      default:
        return status;
    }
  }

  // Méthode pour obtenir la couleur du statut
  Color get statusColor {
    switch (status?.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey;
      case 'PUBLISHED':
        return Colors.green;
      case 'ARCHIVED':
        return Colors.red;
      case 'SCHEDULED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Vérifie si la méditation est publiée
  bool get isPublished => status?.toUpperCase() == 'PUBLISHED';
}

// DTO pour la création de méditation
class MeditationCreateRequest {
  final String title;
  final String? description;
  final int? audioVideoAssetId;
  final int? posterImageAssetId;
  final int durationMin;
  final String category;
  final bool isPremium;
  final String? difficultyLevel;
  final List<String>? tags;
  final String? instructorName;
  final String? languageCode;

  MeditationCreateRequest({
    required this.title,
    this.description,
    this.audioVideoAssetId,
    this.posterImageAssetId,
    required this.durationMin,
    required this.category,
    this.isPremium = false,
    this.difficultyLevel = 'BEGINNER',
    this.tags,
    this.instructorName,
    this.languageCode = 'fr',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'audioVideoAssetId': audioVideoAssetId,
      'posterImageAssetId': posterImageAssetId,
      'durationMin': durationMin,
      'category': category,
      'isPremium': isPremium,
      'difficultyLevel': difficultyLevel,
      'tags': tags,
      'instructorName': instructorName,
      'languageCode': languageCode,
    };
  }
}

// DTO pour la mise à jour de méditation
class MeditationUpdateRequest {
  final String title;
  final String? description;
  final int durationMin;
  final String category;
  final bool isPremium;
  final String? difficultyLevel;
  final List<String>? tags;
  final String? instructorName;
  final String? languageCode;

  MeditationUpdateRequest({
    required this.title,
    this.description,
    required this.durationMin,
    required this.category,
    this.isPremium = false,
    this.difficultyLevel,
    this.tags,
    this.instructorName,
    this.languageCode = 'fr',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'durationMin': durationMin,
      'category': category,
      'isPremium': isPremium,
      'difficultyLevel': difficultyLevel,
      'tags': tags,
      'instructorName': instructorName,
      'languageCode': languageCode,
    };
  }
}
