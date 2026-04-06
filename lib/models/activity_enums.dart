// lib/models/activity_enums.dart - COMPLET ET CORRIGÉ

/// Enum des types d'activités correspondant à ActivityType côté backend
enum ActivityTypeEnum {
  MEDITATION('Méditation guidée', '🧘', 'MEDITATION'),
  BREATHING('Respiration', '🌬️', 'BREATHING'),
  YOGA('Yoga', '🧘‍♀️', 'YOGA'),
  JOURNALING('Journaling', '📓', 'JOURNALING'),
  GRATITUDE('Gratitude', '🙏', 'GRATITUDE'),
  VISUALIZATION('Visualisation', '🌈', 'VISUALIZATION'),
  MINDFUL_WALK('Marche consciente', '🚶', 'MINDFUL_WALK'),
  DAILY_CHALLENGE('Défi quotidien', '🏆', 'DAILY_CHALLENGE'),
  QUOTE_REFLECTION('Réflexion sur citation', '💭', 'QUOTE_REFLECTION'),
  NUMEROLOGY('Numérologie', '🔢', 'NUMEROLOGY'),
  BODY_SCAN('Scan corporel', '👁️', 'BODY_SCAN'),
  SOUND_THERAPY('Sonothérapie', '🎵', 'SOUND_THERAPY'),
  AFFIRMATION('Affirmations', '💫', 'AFFIRMATION'),
  MINDFUL_EATING('Alimentation consciente', '🍎', 'MINDFUL_EATING'),
  STRETCHING('Étirements', '🤸', 'STRETCHING'),
  NATURE_IMMERSION('Immersion nature', '🌳', 'NATURE_IMMERSION'),
  ART_THERAPY('Art-thérapie', '🎨', 'ART_THERAPY'),
  DREAM_JOURNAL('Journal de rêves', '💤', 'DREAM_JOURNAL'),
  ENERGY_WORK('Travail énergétique', '⚡', 'ENERGY_WORK'),
  FORGIVENESS_PRACTICE('Pratique du pardon', '🕊️', 'FORGIVENESS_PRACTICE');

  final String displayName;
  final String emoji;
  final String backendValue;

  const ActivityTypeEnum(this.displayName, this.emoji, this.backendValue);

  /// Afficher le nom avec emoji pour l'UI
  String get displayWithEmoji => '$displayName $emoji';

  /// Afficher seulement le nom
  String get displayWithoutEmoji => displayName;

  /// Obtenir tous les types pour l'affichage (avec emoji)
  static List<String> get displayOptions =>
      values.map((e) => e.displayWithEmoji).toList();

  /// Obtenir le backendValue à partir du displayName avec emoji
  static String? getBackendValueFromDisplay(String displayWithEmoji) {
    for (var type in values) {
      if (type.displayWithEmoji == displayWithEmoji) {
        return type.backendValue;
      }
    }
    return null;
  }

  /// Obtenir le displayName avec emoji à partir du backendValue
  static String? getDisplayFromBackendValue(String backendValue) {
    for (var type in values) {
      if (type.backendValue == backendValue) {
        return type.displayWithEmoji;
      }
    }
    return null;
  }

  /// Obtenir l'ActivityTypeEnum à partir du displayName avec emoji
  static ActivityTypeEnum? fromDisplay(String displayWithEmoji) {
    try {
      return values.firstWhere((e) => e.displayWithEmoji == displayWithEmoji);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir l'ActivityTypeEnum à partir du backendValue
  static ActivityTypeEnum? fromBackendValue(String backendValue) {
    try {
      return values.firstWhere((e) => e.backendValue == backendValue);
    } catch (e) {
      return null;
    }
  }
}

/// Enum des niveaux de difficulté
enum DifficultyLevelEnum {
  BEGINNER('Débutant (1/5)', 'Débutant', 1, 'BEGINNER'),
  EASY('Facile (2/5)', 'Facile', 2, 'EASY'),
  INTERMEDIATE('Intermédiaire (3/5)', 'Intermédiaire', 3, 'INTERMEDIATE'),
  ADVANCED('Avancé (4/5)', 'Avancé', 4, 'ADVANCED'),
  EXPERT('Expert (5/5)', 'Expert', 5, 'EXPERT');

  final String displayName;
  final String shortName;
  final int level;
  final String backendValue;

  const DifficultyLevelEnum(
    this.displayName,
    this.shortName,
    this.level,
    this.backendValue,
  );

  static List<String> get displayOptions =>
      values.map((e) => e.displayName).toList();

  static String? getBackendValueFromDisplay(String displayName) {
    for (var level in values) {
      if (level.displayName == displayName) {
        return level.backendValue;
      }
    }
    return null;
  }

  static String? getDisplayFromBackendValue(String backendValue) {
    for (var level in values) {
      if (level.backendValue == backendValue) {
        return level.displayName;
      }
    }
    return null;
  }
}

/// Enum des catégories de médias
enum MediaCategoryEnum {
  ACTIVITY_COVER('ACTIVITY_COVER'),
  ACTIVITY_LOTTIE('ACTIVITY_LOTTIE'),
  ACTIVITY_AUDIO('ACTIVITY_AUDIO'),
  MEDITATION_AUDIO_VIDEO('MEDITATION_AUDIO_VIDEO'),
  MEDITATION_POSTER('MEDITATION_POSTER');

  final String value;

  const MediaCategoryEnum(this.value);

  @override
  String toString() => value;
}

/// Enum des moments de la journée
enum TimeOfDayEnum {
  MORNING('Matin', 'MORNING'),
  MIDDAY('Midi', 'MIDDAY'),
  AFTERNOON('Après-midi', 'AFTERNOON'),
  EVENING('Soir', 'EVENING'),
  NIGHT('Nuit', 'NIGHT'),
  ANYTIME('Anytime', 'ANYTIME');

  final String displayName;
  final String backendValue;

  const TimeOfDayEnum(this.displayName, this.backendValue);

  static List<String> get displayOptions =>
      values.map((e) => e.displayName).toList();

  static String? getBackendValueFromDisplay(String displayName) {
    for (var time in values) {
      if (time.displayName == displayName) {
        return time.backendValue;
      }
    }
    return null;
  }

  static String? getDisplayFromBackendValue(String backendValue) {
    for (var time in values) {
      if (time.backendValue == backendValue) {
        return time.displayName;
      }
    }
    return null;
  }
}

/// Enum des impacts émotionnels
enum MoodImpactEnum {
  CALM('Calme', 'CALM'),
  ENERGIZING('Énergisant', 'ENERGIZING'),
  RELAXING('Relaxant', 'RELAXING'),
  REVITALIZING('Revitalisant', 'REVITALIZING'),
  SOOTHING('Apaisant', 'SOOTHING'),
  INSPIRING('Inspirant', 'INSPIRING'),
  MOTIVATING('Motivant', 'MOTIVATING');

  final String displayName;
  final String backendValue;

  const MoodImpactEnum(this.displayName, this.backendValue);

  static List<String> get displayOptions =>
      values.map((e) => e.displayName).toList();

  static String? getBackendValueFromDisplay(String displayName) {
    for (var impact in values) {
      if (impact.displayName == displayName) {
        return impact.backendValue;
      }
    }
    return null;
  }

  static String? getDisplayFromBackendValue(String backendValue) {
    for (var impact in values) {
      if (impact.backendValue == backendValue) {
        return impact.displayName;
      }
    }
    return null;
  }
}

/// Enum des environnements idéaux
enum IdealEnvironmentEnum {
  QUIET('Calme, sans distraction', 'QUIET'),
  OUTDOOR('Extérieur', 'OUTDOOR'),
  INDOOR('Intérieur', 'INDOOR'),
  SILENT('Silencieux', 'SILENT'),
  WITH_MUSIC('Avec musique', 'WITH_MUSIC'),
  ANYWHERE('Peu importe', 'ANYWHERE');

  final String displayName;
  final String backendValue;

  const IdealEnvironmentEnum(this.displayName, this.backendValue);

  static List<String> get displayOptions =>
      values.map((e) => e.displayName).toList();

  static String? getBackendValueFromDisplay(String displayName) {
    for (var env in values) {
      if (env.displayName == displayName) {
        return env.backendValue;
      }
    }
    return null;
  }

  static String? getDisplayFromBackendValue(String backendValue) {
    for (var env in values) {
      if (env.backendValue == backendValue) {
        return env.displayName;
      }
    }
    return null;
  }
}

/// Enum des équipements requis
enum EquipmentRequiredEnum {
  NONE('Aucun', 'NONE'),
  MAT('Tapis', 'MAT'),
  CUSHION('Coussin', 'CUSHION'),
  CHAIR('Chaise', 'CHAIR'),
  BLANKET('Couverture', 'BLANKET'),
  ACCESSORIES('Accessoires', 'ACCESSORIES');

  final String displayName;
  final String backendValue;

  const EquipmentRequiredEnum(this.displayName, this.backendValue);

  static List<String> get displayOptions =>
      values.map((e) => e.displayName).toList();

  static String? getBackendValueFromDisplay(String displayName) {
    for (var eq in values) {
      if (eq.displayName == displayName) {
        return eq.backendValue;
      }
    }
    return null;
  }

  static String? getDisplayFromBackendValue(String backendValue) {
    for (var eq in values) {
      if (eq.backendValue == backendValue) {
        return eq.displayName;
      }
    }
    return null;
  }
}
