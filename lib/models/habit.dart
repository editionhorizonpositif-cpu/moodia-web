// lib/models/habit.dart
import 'dart:convert';
import 'package:flutter/material.dart';

enum HabitFrequency { daily, weekly, monthly, custom }

enum HabitCategory {
  santePhysique,
  mentalBienEtre,
  productivite,
  relations,
  alimentation,
  sommeil,
  loisirs,
  finance,
  autres,
}

class Habit {
  final int? id;
  final int? userId;
  final String name;
  final String? description;
  final HabitFrequency frequency;
  final HabitCategory category;
  final int? goalCount;
  final int currentStreak;
  final int bestStreak;
  final bool isActive;
  final bool isTemplate;
  final Color? color;
  final String? icon;
  final List<int>? customDays;
  final int? reminderHour;
  final int? reminderMinute;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastCompleted;

  const Habit({
    this.id,
    this.userId,
    required this.name,
    this.description,
    required this.frequency,
    this.category = HabitCategory.autres,
    this.goalCount,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isActive = true,
    this.isTemplate = false,
    this.color,
    this.icon,
    this.customDays,
    this.reminderHour,
    this.reminderMinute,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.lastCompleted,
  });

  // lib/models/habit.dart - Mettez à jour le factory constructor
  // lib/models/habit.dart - Dans factory Habit.fromJson()
  factory Habit.fromJson(Map<String, dynamic> json) {
    // Gérer reminderTime (LocalTime format: "HH:MM:SS")
    int? reminderHour;
    int? reminderMinute;

    if (json['reminderTime'] != null) {
      final timeString = json['reminderTime'].toString();
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        reminderHour = int.tryParse(parts[0]);
        reminderMinute = int.tryParse(parts[1]);
      }
    }

    return Habit(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: json['userId'] != null
          ? int.tryParse(json['userId'].toString())
          : null,
      name: json['name'] ?? '',
      description: json['description'] as String?,
      frequency: _parseHabitFrequency(json['frequency']),
      category: _parseHabitCategory(json['category']),
      goalCount: json['goalCount'] != null
          ? int.tryParse(json['goalCount'].toString())
          : 1,
      currentStreak: json['currentStreak'] != null
          ? int.tryParse(json['currentStreak'].toString()) ?? 0
          : 0,
      bestStreak: json['bestStreak'] != null
          ? int.tryParse(json['bestStreak'].toString()) ?? 0
          : 0,
      isActive: json['isActive'] as bool? ?? true,
      isTemplate: json['isTemplate'] as bool? ?? false,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      icon: json['icon'] as String?,
      customDays: json['customDays'] != null
          ? (json['customDays'] is String
                ? (jsonDecode(json['customDays']) as List<dynamic>)
                      .map((e) => e as int)
                      .toList()
                : List<int>.from(json['customDays']))
          : null,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      lastCompleted: json['lastCompleted'] != null
          ? DateTime.parse(json['lastCompleted'].toString())
          : null,
    );
  }
  // Ajoutez ces méthodes d'aide
  static HabitFrequency _parseHabitFrequency(dynamic value) {
    if (value == null) return HabitFrequency.daily;

    final stringValue = value.toString().toLowerCase();

    // Essayer avec le nom de l'énumération
    for (final frequency in HabitFrequency.values) {
      if (frequency.name.toLowerCase() == stringValue) {
        return frequency;
      }
    }

    // Essayer avec les codes du backend
    final codeMap = {
      'daily': HabitFrequency.daily,
      'weekly': HabitFrequency.weekly,
      'monthly': HabitFrequency.monthly,
      'custom': HabitFrequency.custom,
    };

    return codeMap[stringValue] ?? HabitFrequency.daily;
  }

  static HabitCategory _parseHabitCategory(dynamic value) {
    if (value == null) return HabitCategory.autres;

    final stringValue = value.toString().toLowerCase();

    // Essayer avec le nom de l'énumération
    for (final category in HabitCategory.values) {
      if (category.name.toLowerCase() == stringValue) {
        return category;
      }
    }

    // Essayer avec les correspondances
    final categoryMap = {
      'santephysique': HabitCategory.santePhysique,
      'sante_physique': HabitCategory.santePhysique,
      'sante physique': HabitCategory.santePhysique,
      'mentalbienetre': HabitCategory.mentalBienEtre,
      'mental_bien_etre': HabitCategory.mentalBienEtre,
      'mental bien etre': HabitCategory.mentalBienEtre,
      'productivite': HabitCategory.productivite,
      'relations': HabitCategory.relations,
      'alimentation': HabitCategory.alimentation,
      'sommeil': HabitCategory.sommeil,
      'loisirs': HabitCategory.loisirs,
      'finance': HabitCategory.finance,
      'autres': HabitCategory.autres,
    };

    return categoryMap[stringValue] ?? HabitCategory.autres;
  }

  // lib/models/habit.dart - Mettez à jour la méthode toJson()
  // lib/models/habit.dart - Modifiez la méthode toJson()
  Map<String, dynamic> toJson() {
    // Format LocalTime pour reminderTime
    String? reminderTimeString;
    if (reminderHour != null && reminderMinute != null) {
      final hour = reminderHour!.toString().padLeft(2, '0');
      final minute = reminderMinute!.toString().padLeft(2, '0');
      reminderTimeString = '$hour:$minute:00';
    }

    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'name': name,
      'description': description,
      'frequency': _frequencyToString(frequency), // CHANGEMENT
      'category': _categoryToString(category), // CHANGEMENT
      'goalCount': goalCount,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'isActive': isActive,
      'isTemplate': isTemplate,
      'color': color?.value,
      'icon': icon,
      'customDays': customDays,
      'reminderTime': reminderTimeString, // LocalTime format
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastCompleted': lastCompleted?.toIso8601String(),
    };
  }

  // Ajoutez ces méthodes d'aide
  static String _frequencyToString(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'DAILY';
      case HabitFrequency.weekly:
        return 'WEEKLY';
      case HabitFrequency.monthly:
        return 'MONTHLY';
      case HabitFrequency.custom:
        return 'CUSTOM';
    }
  }

  static String _categoryToString(HabitCategory category) {
    switch (category) {
      case HabitCategory.santePhysique:
        return 'SANTE_PHYSIQUE';
      case HabitCategory.mentalBienEtre:
        return 'MENTAL_BIEN_ETRE';
      case HabitCategory.productivite:
        return 'PRODUCTIVITE';
      case HabitCategory.relations:
        return 'RELATIONS';
      case HabitCategory.alimentation:
        return 'ALIMENTATION';
      case HabitCategory.sommeil:
        return 'SOMMEIL';
      case HabitCategory.loisirs:
        return 'LOISIRS';
      case HabitCategory.finance:
        return 'FINANCE';
      case HabitCategory.autres:
        return 'AUTRES';
    }
  }

  Habit copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    HabitFrequency? frequency,
    HabitCategory? category,
    int? goalCount,
    int? currentStreak,
    int? bestStreak,
    bool? isActive,
    bool? isTemplate,
    Color? color,
    String? icon,
    List<int>? customDays,
    int? reminderHour,
    int? reminderMinute,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastCompleted,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      goalCount: goalCount ?? this.goalCount,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isActive: isActive ?? this.isActive,
      isTemplate: isTemplate ?? this.isTemplate,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      customDays: customDays ?? this.customDays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastCompleted: lastCompleted ?? this.lastCompleted,
    );
  }

  bool get isCompletedToday {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    return lastCompleted!.year == now.year &&
        lastCompleted!.month == now.month &&
        lastCompleted!.day == now.day;
  }

  bool shouldBeCompletedToday() {
    if (!isActive) return false;
    final today = DateTime.now();
    final todayIndex = today.weekday - 1; // 0=lundi, 6=dimanche

    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return customDays != null && customDays!.contains(todayIndex);
      case HabitFrequency.monthly:
        return today.day == 1;
      case HabitFrequency.custom:
        return customDays != null && customDays!.contains(todayIndex);
    }
  }

  // Méthode pour obtenir TimeOfDay (lecture seule)
  TimeOfDay? get reminderTime {
    if (reminderHour != null && reminderMinute != null) {
      return TimeOfDay(hour: reminderHour!, minute: reminderMinute!);
    }
    return null;
  }

  // Méthode statique pour créer un Habit avec TimeOfDay
  static Habit createWithReminder({
    int? id,
    int? userId,
    required String name,
    String? description,
    required HabitFrequency frequency,
    HabitCategory category = HabitCategory.autres,
    int? goalCount,
    int currentStreak = 0,
    int bestStreak = 0,
    bool isActive = true,
    bool isTemplate = false,
    Color? color,
    String? icon,
    List<int>? customDays,
    TimeOfDay? reminderTime,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastCompleted,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name,
      description: description,
      frequency: frequency,
      category: category,
      goalCount: goalCount,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      isActive: isActive,
      isTemplate: isTemplate,
      color: color,
      icon: icon,
      customDays: customDays,
      reminderHour: reminderTime?.hour,
      reminderMinute: reminderTime?.minute,
      startDate: startDate,
      endDate: endDate,
      lastCompleted: lastCompleted,
    );
  }

  // Helper pour calculer le taux de complétion
  double getCompletionRate(List<DateTime> logs) {
    if (logs.isEmpty || startDate == null) return 0.0;

    final now = DateTime.now();
    final totalDays = now.difference(startDate!).inDays + 1;
    final completedDays = logs.length;

    return totalDays > 0 ? (completedDays / totalDays * 100) : 0.0;
  }

  // Méthode pour formater l'heure du rappel
  String? get formattedReminderTime {
    if (reminderTime == null) return null;
    return '${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}';
  }
}
