import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ActivityCategory {
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
  final double popularityScore;
  final double completionRate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ActivityCategory({
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
    this.popularityScore = 0.0,
    this.completionRate = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    // Debug minimal
    if (kDebugMode) {
      print('🔍 Parsing ActivityCategory: ${json['name']}');
    }

    // Helper pour parser les dates - RETOURNE DateTime, pas DateTime?
    DateTime parseDate(dynamic dateString) {
      if (dateString == null) {
        if (kDebugMode)
          print('⚠️ Date string est null, utilisation de DateTime.now()');
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateString.toString());
      } catch (e) {
        if (kDebugMode)
          print('⚠️ Erreur parsing date: $e, utilisation de DateTime.now()');
        return DateTime.now();
      }
    }

    // Helper pour parser les dates nullable
    DateTime? parseNullableDate(dynamic dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString.toString());
      } catch (e) {
        return null;
      }
    }

    // Helper pour parser les nombres
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      try {
        return int.parse(value.toString());
      } catch (e) {
        return defaultValue;
      }
    }

    double safeParseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      try {
        return double.parse(value.toString());
      } catch (e) {
        return defaultValue;
      }
    }

    try {
      return ActivityCategory(
        id: safeParseInt(json['id']),
        name: (json['name'] ?? 'Sans nom') as String,
        slug: (json['slug'] ?? 'sans-nom') as String,
        description: json['description']?.toString(),
        iconName: json['iconName']?.toString(),
        colorHex: json['colorHex']?.toString(),
        displayOrder: safeParseInt(json['displayOrder']),
        isActive:
            json['isActive']?.toString().toLowerCase() == 'true' ||
            (json['isActive'] is bool && json['isActive'] == true),
        activityCount: safeParseInt(json['activityCount']),
        totalCompletions: safeParseInt(json['totalCompletions']),
        popularityScore: safeParseDouble(json['popularityScore']),
        completionRate: safeParseDouble(json['completionRate']),
        // CORRECTION : createdAt est REQUIRED, donc on utilise parseDate qui retourne DateTime
        createdAt: parseDate(json['createdAt']),
        // updatedAt est optionnel, donc on utilise parseNullableDate qui retourne DateTime?
        updatedAt: parseNullableDate(json['updatedAt']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERREUR ActivityCategory.fromJson: $e');
        print('❌ Stack: ${e.toString()}');
      }
      // Retourner une catégorie par défaut
      return ActivityCategory(
        id: safeParseInt(json['id']),
        name: json['name']?.toString() ?? 'Erreur',
        slug: json['slug']?.toString() ?? 'erreur',
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'activityCount': activityCount,
      'totalCompletions': totalCompletions,
      'popularityScore': popularityScore,
      'completionRate': completionRate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Color getColor() {
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        return Color(int.parse(colorHex!.replaceFirst('#', '0xFF')));
      } catch (e) {
        return const Color(0xFF7DBBC3); // Couleur par défaut Moodia
      }
    }
    return const Color(0xFF7DBBC3);
  }

  IconData getIcon() {
    // Utilisation d'icônes basées sur le nom de l'icône depuis la base
    switch (iconName?.toLowerCase() ?? '') {
      case 'lotus':
      case 'meditation':
      case 'self_improvement':
        return Icons.self_improvement;
      case 'air':
      case 'breathing':
      case 'wind':
        return Icons.air;
      case 'yoga':
      case 'fitness_center':
        return Icons.fitness_center;
      case 'edit':
      case 'writing':
      case 'book':
        return Icons.edit;
      case 'nature':
      case 'park':
      case 'forest':
        return Icons.park;
      case 'palette':
      case 'brush':
      case 'creativity':
        return Icons.palette;
      case 'directions_walk':
      case 'walk':
      case 'hiking':
        return Icons.directions_walk;
      case 'psychology':
      case 'brain':
      case 'mind':
        return Icons.psychology;
      case 'music_note':
      case 'music':
      case 'sound':
        return Icons.music_note;
      case 'lightbulb':
      case 'idea':
      case 'insight':
        return Icons.lightbulb;
      case 'restaurant':
      case 'food':
      case 'eating':
        return Icons.restaurant;
      case 'bedtime':
      case 'sleep':
      case 'night':
        return Icons.bedtime;
      case 'bolt':
      case 'energy':
      case 'flash':
        return Icons.bolt;
      case 'favorite':
      case 'heart':
      case 'love':
        return Icons.favorite;
      case 'moon':
      case 'nightlight':
        return Icons.nightlight;
      case 'sunny':
      case 'sun':
      case 'day':
        return Icons.wb_sunny;
      case 'water':
      case 'waves':
      case 'beach':
        return Icons.waves;
      case 'spa':
      case 'wellness':
        return Icons.spa;
      default:
        return Icons.category;
    }
  }

  String getPopularityLabel() {
    if (popularityScore >= 80) return 'Très populaire';
    if (popularityScore >= 60) return 'Populaire';
    if (popularityScore >= 40) return 'Moyen';
    if (popularityScore >= 20) return 'Peu populaire';
    return 'Nouveau';
  }

  String getCompletionRateLabel() {
    if (completionRate >= 80) return 'Excellente complétion';
    if (completionRate >= 60) return 'Bonne complétion';
    if (completionRate >= 40) return 'Complétion moyenne';
    if (completionRate >= 20) return 'Faible complétion';
    return 'À découvrir';
  }

  // Méthode pour générer un dégradé de couleur
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
}
