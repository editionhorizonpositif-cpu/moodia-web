import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'activity_category.dart';

class Activity {
  final int id;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String type;
  final String? typeDisplayName;
  final String? typeEmoji;
  final ActivityCategory? category;
  final List<String> tags;
  final int? durationSeconds;
  final String? durationDisplay;
  final String? difficultyLevel;
  final String? difficultyDescription;
  final String? coverImageUrl;
  final String? iconName;
  final String? colorHex;
  final String? lottieAnimationUrl;
  final String? audioGuideUrl;
  final Map<String, dynamic>? configuration;
  final String? instructions;
  final String? prerequisites;
  final String? benefits;
  final int completionCount;
  final double averageRating;
  final double popularityScore;
  final double? successRate;
  final bool isActive;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;
  final bool? isFavorite;
  final bool? isCompleted;
  final int? userRating;
  final String? userFeedback;
  final int? progressPercentage;
  final bool? isInProgress;
  final int? coverImageAssetId;
  final int? lottieAnimationAssetId;
  final int? audioGuideAssetId;

  Activity({
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
    this.iconName,
    this.colorHex,
    this.lottieAnimationUrl,
    this.audioGuideUrl,
    this.configuration,
    this.instructions,
    this.prerequisites,
    this.benefits,
    this.completionCount = 0,
    this.averageRating = 0.0,
    this.popularityScore = 0.0,
    this.successRate,
    this.isActive = true,
    this.status = 'PUBLISHED',
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.isFavorite,
    this.isCompleted,
    this.userRating,
    this.userFeedback,
    this.progressPercentage,
    this.isInProgress,
    this.coverImageAssetId,
    this.lottieAnimationAssetId,
    this.audioGuideAssetId,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les dates
    DateTime safeParseDate(dynamic dateString) {
      if (dateString == null) return DateTime.now();
      try {
        return DateTime.parse(dateString.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    // Helper pour parser les dates nullable
    DateTime? safeParseNullableDate(dynamic dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString.toString());
      } catch (e) {
        return null;
      }
    }

    // Parsing sécurisé de tous les champs numériques
    int? safeParseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      try {
        return int.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    double? safeParseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      try {
        return double.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    // Vérification des champs obligatoires
    final id = safeParseInt(json['id']) ?? 0;
    final title = (json['title'] ?? 'Sans titre') as String;
    final slug = (json['slug'] ?? 'sans-titre-$id') as String;
    final type = (json['type'] ?? 'MEDITATION') as String;

    // Parsing sécurisé de la catégorie
    ActivityCategory? category;
    if (json['category'] != null && json['category'] is Map<String, dynamic>) {
      try {
        category = ActivityCategory.fromJson(
          json['category'] as Map<String, dynamic>,
        );
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing category: $e');
        }
        category = null;
      }
    }

    // Liste de tags sécurisée
    List<String> tags = [];
    if (json['tags'] != null && json['tags'] is List) {
      try {
        tags = List<String>.from(json['tags'].map((x) => x.toString()));
      } catch (e) {
        tags = [];
      }
    }

    return Activity(
      id: id,
      title: title,
      slug: slug,
      shortDescription: json['shortDescription']?.toString(),
      description: json['description']?.toString(),
      type: type,
      typeDisplayName: json['typeDisplayName']?.toString(),
      typeEmoji: json['typeEmoji']?.toString(),
      category: category,
      tags: tags,
      durationSeconds: safeParseInt(json['durationSeconds']),
      durationDisplay: json['durationDisplay']?.toString(),
      difficultyLevel: json['difficultyLevel']?.toString(),
      difficultyDescription: json['difficultyDescription']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      iconName: json['iconName']?.toString(),
      colorHex: json['colorHex']?.toString(),
      lottieAnimationUrl: json['lottieAnimationUrl']?.toString(),
      audioGuideUrl: json['audioGuideUrl']?.toString(),
      configuration: json['configuration'] is Map<String, dynamic>
          ? json['configuration'] as Map<String, dynamic>
          : null,
      instructions: json['instructions']?.toString(),
      prerequisites: json['prerequisites']?.toString(),
      benefits: json['benefits']?.toString(),
      completionCount: safeParseInt(json['completionCount']) ?? 0,
      averageRating: safeParseDouble(json['averageRating']) ?? 0.0,
      popularityScore: safeParseDouble(json['popularityScore']) ?? 0.0,
      successRate: safeParseDouble(json['successRate']),
      isActive:
          json['isActive']?.toString().toLowerCase() == 'true' ||
          (json['isActive'] is bool && json['isActive'] == true),
      status: (json['status']?.toString() ?? 'PUBLISHED'),
      createdAt: safeParseDate(json['createdAt']),
      updatedAt: safeParseNullableDate(json['updatedAt']),
      publishedAt: safeParseNullableDate(json['publishedAt']),
      isFavorite: json['isFavorite'] is bool
          ? json['isFavorite'] as bool
          : json['isFavorite']?.toString().toLowerCase() == 'true',
      isCompleted: json['isCompleted'] is bool
          ? json['isCompleted'] as bool
          : json['isCompleted']?.toString().toLowerCase() == 'true',
      userRating: safeParseInt(json['userRating']),
      userFeedback: json['userFeedback']?.toString(),
      progressPercentage: safeParseInt(json['progressPercentage']),
      isInProgress: json['isInProgress'] is bool
          ? json['isInProgress'] as bool
          : json['isInProgress']?.toString().toLowerCase() == 'true',
      coverImageAssetId: json['coverImageAssetId'] as int,
      lottieAnimationAssetId: json['lottieAnimationAssetId'] as int,
      audioGuideAssetId: json['audioGuideAssetId'] as int,
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
      'category': category?.toJson(),
      'tags': tags,
      'durationSeconds': durationSeconds,
      'durationDisplay': durationDisplay,
      'difficultyLevel': difficultyLevel,
      'difficultyDescription': difficultyDescription,
      'coverImageUrl': coverImageUrl,
      'iconName': iconName,
      'colorHex': colorHex,
      'lottieAnimationUrl': lottieAnimationUrl,
      'audioGuideUrl': audioGuideUrl,
      'configuration': configuration,
      'instructions': instructions,
      'prerequisites': prerequisites,
      'benefits': benefits,
      'completionCount': completionCount,
      'averageRating': averageRating,
      'popularityScore': popularityScore,
      'successRate': successRate,
      'isActive': isActive,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'isFavorite': isFavorite,
      'isCompleted': isCompleted,
      'userRating': userRating,
      'userFeedback': userFeedback,
      'progressPercentage': progressPercentage,
      'isInProgress': isInProgress,
      'coverImageAssetId': coverImageAssetId,
      'lottieAnimationAssetId': lottieAnimationAssetId,
      'audioGuideAssetId': audioGuideAssetId,
    };
  }

  Color getColor() {
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        return Color(int.parse(colorHex!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return const Color(0xFF7DBBC3);
      }
    }
    return const Color(0xFF7DBBC3);
  }

  IconData getIcon() {
    switch (type.toLowerCase()) {
      case 'meditation':
        return Icons.self_improvement;
      case 'breathing':
        return Icons.air;
      case 'yoga':
        return Icons.self_improvement;
      case 'journaling':
      case 'gratitude':
        return Icons.edit;
      case 'visualization':
        return Icons.palette;
      case 'mindful_walk':
        return Icons.directions_walk;
      case 'daily_challenge':
        return Icons.emoji_events;
      case 'quote_reflection':
        return Icons.format_quote;
      case 'numerology':
        return Icons.numbers;
      case 'body_scan':
        return Icons.visibility;
      case 'sound_therapy':
        return Icons.music_note;
      case 'affirmation':
        return Icons.psychology;
      case 'mindful_eating':
        return Icons.restaurant;
      case 'stretching':
        return Icons.fitness_center;
      case 'nature_immersion':
        return Icons.nature;
      case 'art_therapy':
        return Icons.brush;
      case 'dream_journal':
        return Icons.nightlight_round;
      case 'energy_work':
        return Icons.bolt;
      case 'forgiveness_practice':
        return Icons.favorite;
      default:
        return Icons.self_improvement;
    }
  }

  Activity copyWith({
    int? id,
    String? title,
    String? slug,
    String? shortDescription,
    String? description,
    String? type,
    String? typeDisplayName,
    String? typeEmoji,
    ActivityCategory? category,
    List<String>? tags,
    int? durationSeconds,
    String? durationDisplay,
    String? difficultyLevel,
    String? difficultyDescription,
    String? coverImageUrl,
    String? iconName,
    String? colorHex,
    String? lottieAnimationUrl,
    Map<String, dynamic>? configuration,
    String? instructions,
    String? prerequisites,
    String? benefits,
    int? completionCount,
    double? averageRating,
    double? popularityScore,
    double? successRate,
    bool? isActive,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool? isFavorite,
    bool? isCompleted,
    int? userRating,
    String? userFeedback,
    int? progressPercentage,
    bool? isInProgress,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      type: type ?? this.type,
      typeDisplayName: typeDisplayName ?? this.typeDisplayName,
      typeEmoji: typeEmoji ?? this.typeEmoji,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationDisplay: durationDisplay ?? this.durationDisplay,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      difficultyDescription:
          difficultyDescription ?? this.difficultyDescription,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      lottieAnimationUrl: lottieAnimationUrl ?? this.lottieAnimationUrl,
      configuration: configuration ?? this.configuration,
      instructions: instructions ?? this.instructions,
      prerequisites: prerequisites ?? this.prerequisites,
      benefits: benefits ?? this.benefits,
      completionCount: completionCount ?? this.completionCount,
      averageRating: averageRating ?? this.averageRating,
      popularityScore: popularityScore ?? this.popularityScore,
      successRate: successRate ?? this.successRate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isCompleted: isCompleted ?? this.isCompleted,
      userRating: userRating ?? this.userRating,
      userFeedback: userFeedback ?? this.userFeedback,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isInProgress: isInProgress ?? this.isInProgress,
    );
  }

  // Ajoutez ces méthodes à la classe Activity
  String getDifficultyLabel() {
    switch (difficultyLevel?.toLowerCase()) {
      case 'beginner':
        return 'Débutant';
      case 'intermediate':
        return 'Intermédiaire';
      case 'advanced':
        return 'Avancé';
      default:
        return 'Tous niveaux';
    }
  }

  String getStatusLabel() {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Brouillon';
      case 'REVIEW':
        return 'En revue';
      case 'PUBLISHED':
        return 'Publié';
      case 'ARCHIVED':
        return 'Archivé';
      case 'DELETED':
        return 'Supprimé';
      default:
        return 'Inconnu';
    }
  }

  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.orange;
      case 'REVIEW':
        return Colors.blue;
      case 'PUBLISHED':
        return Colors.green;
      case 'ARCHIVED':
        return Colors.grey;
      case 'DELETED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getPopularityLabel() {
    if (popularityScore >= 80) return 'Très populaire';
    if (popularityScore >= 60) return 'Populaire';
    if (popularityScore >= 40) return 'Moyen';
    if (popularityScore >= 20) return 'Peu populaire';
    return 'Nouveau';
  }

  LinearGradient getGradient() {
    final baseColor = getColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.9),
        baseColor.withOpacity(0.7),
        baseColor.withOpacity(0.5),
      ],
    );
  }

  // Méthode pour afficher la durée formatée
  String getFormattedDuration() {
    if (durationSeconds == null) return 'Durée variable';

    final seconds = durationSeconds!;
    if (seconds < 60) {
      return '$seconds secondes';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds > 0) {
        return '$minutes min $remainingSeconds s';
      }
      return '$minutes minutes';
    } else {
      final hours = seconds ~/ 3600;
      final remainingMinutes = (seconds % 3600) ~/ 60;
      if (remainingMinutes > 0) {
        return '$hours h $remainingMinutes min';
      }
      return '$hours heures';
    }
  }
}
