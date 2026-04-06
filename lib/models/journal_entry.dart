import 'package:flutter/material.dart';

class JournalEntry {
  final String? id;
  final int? userId;
  final String content;
  final String? title;
  final int? moodRating;
  final EntryType entryType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrivate;
  final Set<String> tags;
  final int? wordCount;

  JournalEntry({
    this.id,
    this.userId,
    required this.content,
    this.title,
    this.moodRating,
    this.entryType = EntryType.GENERAL,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPrivate = true,
    Set<String>? tags,
    this.wordCount,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       tags = tags ?? {};

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    // Fonction utilitaire locale
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        return DateTime.parse(value as String);
      } catch (_) {
        return DateTime.now();
      }
    }

    return JournalEntry(
      id: json['id']?.toString(),
      userId: json['userId'] as int?,
      content: json['content'] ?? '',
      title: json['title'],
      moodRating: json['moodRating'] as int?,
      entryType: EntryType.values.firstWhere(
        (e) => e.name == (json['entryType'] ?? 'GENERAL'),
        orElse: () => EntryType.GENERAL,
      ),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      isPrivate: json['isPrivate'] ?? true,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ??
          {},
      wordCount: json['wordCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'content': content,
      if (title != null && title!.isNotEmpty) 'title': title,
      if (moodRating != null) 'moodRating': moodRating,
      'entryType': entryType.name,
      'isPrivate': isPrivate,
      'tags': tags.toList(),
    };
  }

  JournalEntry copyWith({
    String? id,
    int? userId,
    String? content,
    String? title,
    int? moodRating,
    EntryType? entryType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrivate,
    Set<String>? tags,
    int? wordCount,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      title: title ?? this.title,
      moodRating: moodRating ?? this.moodRating,
      entryType: entryType ?? this.entryType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrivate: isPrivate ?? this.isPrivate,
      tags: tags ?? this.tags,
      wordCount: wordCount ?? this.wordCount,
    );
  }
}

enum EntryType {
  GRATITUDE('Gratitude', Icons.favorite, Colors.pink),
  REFLECTION('Réflexion', Icons.psychology, Colors.deepPurple),
  GOAL('Objectif', Icons.flag, Colors.blue),
  CHALLENGE('Défi', Icons.fitness_center, Colors.orange),
  ACHIEVEMENT('Réussite', Icons.star, Colors.yellow),
  DREAM('Rêve', Icons.nightlight_round, Colors.indigo),
  AFFIRMATION('Affirmation', Icons.chat, Colors.green),
  GENERAL('Général', Icons.edit_note, Colors.grey);

  final String displayName;
  final IconData icon;
  final Color color;

  const EntryType(this.displayName, this.icon, this.color);
}

class JournalStatistics {
  final int totalEntries;
  final double averageMood; // AJOUTÉ
  final int entriesThisMonth; // AJOUTÉ
  final double averageWordsPerEntry; // CHANGÉ: double au lieu de int
  final int totalWords;
  final int longestStreak;
  final DateTime? mostActiveDate;
  final Map<String, int> entryTypeDistribution;
  final Map<int, int> moodDistribution;
  final Map<String, int> tagFrequency;
  final Map<String, int> entriesByDayOfWeek;
  final List<DailyActivity> dailyActivity; // AJOUTÉ
  final List<JournalEntry> recentEntries; // AJOUTÉ

  JournalStatistics({
    required this.totalEntries,
    required this.averageMood, // AJOUTÉ
    required this.entriesThisMonth, // AJOUTÉ
    required this.averageWordsPerEntry,
    required this.totalWords,
    required this.longestStreak,
    this.mostActiveDate,
    required this.entryTypeDistribution,
    required this.moodDistribution,
    required this.tagFrequency,
    required this.entriesByDayOfWeek,
    required this.dailyActivity, // AJOUTÉ
    required this.recentEntries, // AJOUTÉ
  });

  factory JournalStatistics.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les valeurs numériques
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    double safeParseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Parser moodDistribution avec des clés qui peuvent être String dans le JSON
    Map<int, int> parseMoodDistribution(dynamic value) {
      final Map<int, int> result = {};
      if (value is Map) {
        value.forEach((k, v) {
          int? key;
          if (k is int) {
            key = k;
          } else if (k is String) {
            key = int.tryParse(k);
          }

          if (key != null) {
            result[key] = safeParseInt(v);
          }
        });
      }
      return result;
    }

    return JournalStatistics(
      totalEntries: safeParseInt(json['totalEntries']),
      averageMood: safeParseDouble(json['averageMood']), // AJOUTÉ
      entriesThisMonth: safeParseInt(json['entriesThisMonth']), // AJOUTÉ
      averageWordsPerEntry: safeParseDouble(json['averageWordsPerEntry']),
      totalWords: safeParseInt(json['totalWords']),
      longestStreak: safeParseInt(json['longestStreak']),
      mostActiveDate: json['mostActiveDate'] != null
          ? DateTime.tryParse(json['mostActiveDate'])
          : null,
      entryTypeDistribution: _parseStringIntMap(json['entryTypeDistribution']),
      moodDistribution: parseMoodDistribution(json['moodDistribution']),
      tagFrequency: _parseStringIntMap(json['tagFrequency']),
      entriesByDayOfWeek: _parseStringIntMap(json['entriesByDayOfWeek']),
      dailyActivity:
          (json['dailyActivity'] as List<dynamic>?)
              ?.map((e) => DailyActivity.fromJson(e))
              .toList() ??
          [], // AJOUTÉ
      recentEntries:
          (json['recentEntries'] as List<dynamic>?)
              ?.map((e) => JournalEntry.fromJson(e))
              .toList() ??
          [], // AJOUTÉ
    );
  }

  static Map<String, int> _parseStringIntMap(dynamic value) {
    final Map<String, int> result = {};
    if (value is Map) {
      value.forEach((k, v) {
        if (k is String) {
          final intVal = _safeParseInt(v);
          if (intVal != null) {
            result[k] = intVal;
          }
        }
      });
    }
    return result;
  }

  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class DailyActivity {
  final DateTime date;
  final int entryCount;
  final double averageMood;

  DailyActivity({
    required this.date,
    required this.entryCount,
    required this.averageMood,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      date: DateTime.parse(json['date'] as String),
      entryCount: json['entryCount'] ?? 0,
      averageMood: (json['averageMood'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'entryCount': entryCount,
    'averageMood': averageMood,
  };
}

class CreateJournalEntryRequest {
  final String content;
  final String? title;
  final int? moodRating;
  final String entryType;
  final bool isPrivate;
  final List<String> tags;

  CreateJournalEntryRequest({
    required this.content,
    this.title,
    this.moodRating,
    required this.entryType,
    this.isPrivate = true,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (title != null && title!.isNotEmpty) 'title': title,
      if (moodRating != null) 'moodRating': moodRating,
      'entryType': entryType,
      'isPrivate': isPrivate,
      'tags': tags,
    };
  }
}

class UpdateJournalEntryRequest {
  final String? content;
  final String? title;
  final int? moodRating;
  final String? entryType;
  final bool? isPrivate;
  final List<String>? tags;

  UpdateJournalEntryRequest({
    this.content,
    this.title,
    this.moodRating,
    this.entryType,
    this.isPrivate,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (content != null) map['content'] = content;
    if (title != null) map['title'] = title;
    if (moodRating != null) map['moodRating'] = moodRating;
    if (entryType != null) map['entryType'] = entryType;
    if (isPrivate != null) map['isPrivate'] = isPrivate;
    if (tags != null) map['tags'] = tags;
    return map;
  }
}
