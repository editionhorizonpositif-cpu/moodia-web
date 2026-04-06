// lib/models/mood_entry_enhanced.dart
import 'dart:convert';
import 'package:intl/intl.dart';

class MoodEntryEnhanced {
  int? id;
  int? userId;
  String primaryEmotion;
  List<String> secondaryEmotions;
  double intensity;
  Map<String, dynamic>? physicalSensations;
  List<String>? triggers;
  String? note;
  String? context;
  String? weather;
  int? energyLevel;
  int? sleepQuality;
  List<String>? copingStrategiesUsed;
  bool? needSupport;
  DateTime? createdAt;
  DateTime? updatedAt;

  MoodEntryEnhanced({
    this.id,
    this.userId,
    required this.primaryEmotion,
    this.secondaryEmotions = const [],
    required this.intensity,
    this.physicalSensations,
    this.triggers,
    this.note,
    this.context,
    this.weather,
    this.energyLevel,
    this.sleepQuality,
    this.copingStrategiesUsed,
    this.needSupport,
    this.createdAt,
    this.updatedAt,
  });

  factory MoodEntryEnhanced.fromJson(Map<String, dynamic> json) {
    return MoodEntryEnhanced(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      primaryEmotion: json['primaryEmotion'] as String,
      secondaryEmotions:
          (json['secondaryEmotions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      intensity: (json['intensity'] as num?)?.toDouble() ?? 5.0,
      physicalSensations: json['physicalSensations'] as Map<String, dynamic>?,
      triggers: (json['triggers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      note: json['note'] as String?,
      context: json['context'] as String?,
      weather: json['weather'] as String?,
      energyLevel: json['energyLevel'] as int?,
      sleepQuality: json['sleepQuality'] as int?,
      copingStrategiesUsed: (json['copingStrategiesUsed'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      needSupport: json['needSupport'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'primaryEmotion': primaryEmotion,
      'secondaryEmotions': secondaryEmotions,
      'intensity': intensity,
      if (physicalSensations != null) 'physicalSensations': physicalSensations,
      if (triggers != null) 'triggers': triggers,
      if (note != null) 'note': note,
      if (context != null) 'context': context,
      if (weather != null) 'weather': weather,
      if (energyLevel != null) 'energyLevel': energyLevel,
      if (sleepQuality != null) 'sleepQuality': sleepQuality,
      if (copingStrategiesUsed != null)
        'copingStrategiesUsed': copingStrategiesUsed,
      if (needSupport != null) 'needSupport': needSupport,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Méthodes utilitaires
  String get emotionalState {
    if (intensity > 7.0) return 'Intense';
    if (intensity > 4.0) return 'Modéré';
    return 'Léger';
  }

  bool get requiresAttention {
    final negativeEmotions = ['Tristesse', 'Colère', 'Peur', 'Anxiété'];
    return (intensity > 8.0 && negativeEmotions.contains(primaryEmotion)) ||
        (needSupport == true);
  }

  String get formattedDate {
    if (createdAt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt!);
  }

  String get timeAgo {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 30) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  // Méthode pour créer une copie modifiée
  MoodEntryEnhanced copyWith({
    int? id,
    int? userId,
    String? primaryEmotion,
    List<String>? secondaryEmotions,
    double? intensity,
    Map<String, dynamic>? physicalSensations,
    List<String>? triggers,
    String? note,
    String? context,
    String? weather,
    int? energyLevel,
    int? sleepQuality,
    List<String>? copingStrategiesUsed,
    bool? needSupport,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodEntryEnhanced(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      primaryEmotion: primaryEmotion ?? this.primaryEmotion,
      secondaryEmotions: secondaryEmotions ?? this.secondaryEmotions,
      intensity: intensity ?? this.intensity,
      physicalSensations: physicalSensations ?? this.physicalSensations,
      triggers: triggers ?? this.triggers,
      note: note ?? this.note,
      context: context ?? this.context,
      weather: weather ?? this.weather,
      energyLevel: energyLevel ?? this.energyLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      copingStrategiesUsed: copingStrategiesUsed ?? this.copingStrategiesUsed,
      needSupport: needSupport ?? this.needSupport,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
