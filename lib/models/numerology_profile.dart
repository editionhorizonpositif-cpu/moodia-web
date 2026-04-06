class NumerologyProfile {
  final int? id;
  final int? userId;
  final DateTime birthDate;
  final String fullName;
  final int? lifePathNumber;
  final int? expressionNumber;
  final int? realizationNumber;
  final int? soulUrgeNumber;
  final int? personalYear;
  final int? personalMonth;
  final int? personalDay;
  final String? summary;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? lifePathInterpretation;
  final String? expressionInterpretation;
  final String? realizationInterpretation;
  final String? soulUrgeInterpretation;
  final String? personalYearInterpretation;
  final String? personalMonthInterpretation;
  final String? personalDayInterpretation;

  NumerologyProfile({
    this.id,
    this.userId,
    required this.birthDate,
    required this.fullName,
    this.lifePathNumber,
    this.expressionNumber,
    this.realizationNumber,
    this.soulUrgeNumber,
    this.personalYear,
    this.personalMonth,
    this.personalDay,
    this.summary,
    this.createdAt,
    this.updatedAt,
    this.lifePathInterpretation,
    this.expressionInterpretation,
    this.realizationInterpretation,
    this.soulUrgeInterpretation,
    this.personalYearInterpretation,
    this.personalMonthInterpretation,
    this.personalDayInterpretation,
  });

  factory NumerologyProfile.fromJzon(Map<String, dynamic> json) {
    // CORRECTION : Utilisez les bonnes clés JSON
    return NumerologyProfile(
      id: json['profileId'] as int?,
      userId: json['userId'] as int?,
      birthDate: DateTime.parse(json['birthDate'] as String),
      fullName: json['fullName'] as String? ?? '',
      lifePathNumber: json['lifePathNumber'] as int?, // Correction ici
      expressionNumber: json['expressionNumber'] as int?, // Correction ici
      realizationNumber: json['realizationNumber'] as int?, // Correction ici
      soulUrgeNumber: json['soulUrgeNumber'] as int?, // Correction ici
      personalYear: json['personalYear'] as int?, // Correction ici
      personalMonth: json['personalMonth'] as int?, // Correction ici
      personalDay: json['personalDay'] as int?, // Correction ici
      summary: json['summary'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      lifePathInterpretation: json['lifePathInterpretation'] as String? ?? '',
      expressionInterpretation:
          json['expressionInterpretation'] as String? ?? '',
      realizationInterpretation:
          json['realizationInterpretation'] as String? ?? '',
      soulUrgeInterpretation: json['soulUrgeInterpretation'] as String? ?? '',
      personalYearInterpretation:
          json['personalYearInterpretation'] as String? ?? '',
      personalMonthInterpretation:
          json['personalMonthInterpretation'] as String? ?? '',
      personalDayInterpretation:
          json['personalDayInterpretation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJzon() {
    return {
      'id': id,
      'userId': userId,
      'birthDate': birthDate.toIso8601String(),
      'fullName': fullName,
      'lifePathNumber': lifePathNumber,
      'expressionNumber': expressionNumber,
      'realizationNumber': realizationNumber,
      'soulUrgeNumber': soulUrgeNumber,
      'personalYear': personalYear,
      'personalMonth': personalMonth,
      'personalDay': personalDay,
      'summary': summary,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lifePathInterpretation': lifePathInterpretation,
      'expressionInterpretation': expressionInterpretation,
      'realizationInterpretation': realizationInterpretation,
      'soulUrgeInterpretation': soulUrgeInterpretation,
      'personalYearInterpretation': personalYearInterpretation,
      'personalMonthInterpretation': personalMonthInterpretation,
      'personalDayInterpretation': personalDayInterpretation,
    };
  }

  // Ajouter des méthodes utiles
  int getAgeInYears() {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool get isComplete {
    return lifePathNumber != null &&
        expressionNumber != null &&
        realizationNumber != null;
  }

  Map<String, dynamic> get mainNumbers {
    return {
      'Chemin de Vie': lifePathNumber,
      'Expression': expressionNumber,
      'Réalisation': realizationNumber,
      'Intime': soulUrgeNumber,
    };
  }

  Map<String, dynamic> get personalNumbers {
    return {'Année': personalYear, 'Mois': personalMonth, 'Jour': personalDay};
  }
}
