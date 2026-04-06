import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/numerology_profile.dart';
import 'api_service.dart';

class NumerologyService {
  final ApiService _apiService = ApiService();

  // Cache local pour les profils
  final Map<int, NumerologyProfile> _profileCache = {};
  final Map<int, DateTime> _cacheTimestamps = {};

  // Durée de validité du cache (en heures)
  static const int CACHE_DURATION_HOURS = 24;

  Future<NumerologyProfile> generateProfile(
    Map<String, dynamic> requestData, {
    required String baseUrl,
  }) async {
    try {
      // Simulation de génération de profil (pour le développement)
      await Future.delayed(const Duration(seconds: 2));

      // Pour le développement, on simule un profil
      return _createMockProfile(requestData);

      // Code pour l'API réelle (à décommenter en production) :
      /*
      final url = Uri.parse('$baseUrl/generate');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NumerologyProfile.fromJzon(data);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
      */
    } catch (e) {
      print('Erreur génération profil: $e');

      // En cas d'erreur, créer un profil de secours
      return _createFallbackProfile(requestData);
    }
  }

  Future<NumerologyProfile?> getCachedProfile(int userId) async {
    // Vérifier si le profil est en cache et encore valide
    if (_profileCache.containsKey(userId)) {
      final lastUpdated = _cacheTimestamps[userId];
      if (lastUpdated != null) {
        final now = DateTime.now();
        final cacheAge = now.difference(lastUpdated);

        if (cacheAge.inHours < CACHE_DURATION_HOURS) {
          return _profileCache[userId];
        }
      }
    }

    // Si pas en cache, vérifier dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedProfileKey = 'numerology_profile_$userId';
    final cachedProfileJson = prefs.getString(cachedProfileKey);

    if (cachedProfileJson != null) {
      try {
        final data = jsonDecode(cachedProfileJson);
        final profile = NumerologyProfile.fromJzon(data);

        // Vérifier si le profil n'est pas trop vieux (30 jours max)
        if (profile.updatedAt != null) {
          final profileAge = DateTime.now().difference(profile.updatedAt!);
          if (profileAge.inDays < 30) {
            _profileCache[userId] = profile;
            _cacheTimestamps[userId] = DateTime.now();
            return profile;
          }
        }
      } catch (e) {
        print('Erreur lecture cache: $e');
        await prefs.remove(cachedProfileKey);
      }
    }

    return null;
  }

  Future<void> cacheProfile(int userId, NumerologyProfile profile) async {
    // Mettre en cache mémoire
    _profileCache[userId] = profile;
    _cacheTimestamps[userId] = DateTime.now();

    // Mettre en cache local (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    final cachedProfileKey = 'numerology_profile_$userId';
    await prefs.setString(cachedProfileKey, jsonEncode(profile.toJzon()));
  }

  Future<void> clearCache(int userId) async {
    // Nettoyer le cache mémoire
    _profileCache.remove(userId);
    _cacheTimestamps.remove(userId);

    // Nettoyer le cache local
    final prefs = await SharedPreferences.getInstance();
    final cachedProfileKey = 'numerology_profile_$userId';
    await prefs.remove(cachedProfileKey);
  }

  Future<bool> hasValidProfile(int userId) async {
    final profile = await getCachedProfile(userId);
    return profile != null && _isProfileValid(profile);
  }

  bool _isProfileValid(NumerologyProfile profile) {
    return profile.lifePathNumber != null &&
        profile.expressionNumber != null &&
        profile.realizationNumber != null;
  }

  // Méthodes de calcul numérologique
  int calculateLifePathNumber(DateTime birthDate) {
    int sum = birthDate.day + birthDate.month + _reduceYear(birthDate.year);
    return _reduceToMasterNumber(sum);
  }

  int _reduceYear(int year) {
    int sum = 0;
    while (year > 0) {
      sum += year % 10;
      year ~/= 10;
    }
    return sum;
  }

  int calculateExpressionNumber(String fullName) {
    String normalizedName = _normalizeName(fullName);
    int sum = 0;

    final Map<String, int> letterValues = {
      'A': 1,
      'J': 1,
      'S': 1,
      'B': 2,
      'K': 2,
      'T': 2,
      'C': 3,
      'L': 3,
      'U': 3,
      'D': 4,
      'M': 4,
      'V': 4,
      'E': 5,
      'N': 5,
      'W': 5,
      'F': 6,
      'O': 6,
      'X': 6,
      'G': 7,
      'P': 7,
      'Y': 7,
      'H': 8,
      'Q': 8,
      'Z': 8,
      'I': 9,
      'R': 9,
    };

    for (int i = 0; i < normalizedName.length; i++) {
      final char = normalizedName[i];
      if (char != ' ') {
        sum += letterValues[char] ?? 0;
      }
    }

    return _reduceToMasterNumber(sum);
  }

  int calculateRealizationNumber(String fullName) {
    String normalizedName = _normalizeName(fullName);
    int vowelSum = 0;
    int consonantSum = 0;

    final vowels = 'AEIOUY';
    final Map<String, int> letterValues = {
      'A': 1,
      'J': 1,
      'S': 1,
      'B': 2,
      'K': 2,
      'T': 2,
      'C': 3,
      'L': 3,
      'U': 3,
      'D': 4,
      'M': 4,
      'V': 4,
      'E': 5,
      'N': 5,
      'W': 5,
      'F': 6,
      'O': 6,
      'X': 6,
      'G': 7,
      'P': 7,
      'Y': 7,
      'H': 8,
      'Q': 8,
      'Z': 8,
      'I': 9,
      'R': 9,
    };

    for (int i = 0; i < normalizedName.length; i++) {
      final char = normalizedName[i];
      if (char != ' ') {
        final value = letterValues[char] ?? 0;
        if (vowels.contains(char)) {
          vowelSum += value;
        } else {
          consonantSum += value;
        }
      }
    }

    return _reduceToMasterNumber(vowelSum + consonantSum);
  }

  int calculateSoulUrgeNumber(String fullName) {
    String normalizedName = _normalizeName(fullName);
    int sum = 0;

    final vowels = 'AEIOUY';
    final Map<String, int> letterValues = {
      'A': 1,
      'J': 1,
      'S': 1,
      'B': 2,
      'K': 2,
      'T': 2,
      'C': 3,
      'L': 3,
      'U': 3,
      'D': 4,
      'M': 4,
      'V': 4,
      'E': 5,
      'N': 5,
      'W': 5,
      'F': 6,
      'O': 6,
      'X': 6,
      'G': 7,
      'P': 7,
      'Y': 7,
      'H': 8,
      'Q': 8,
      'Z': 8,
      'I': 9,
      'R': 9,
    };

    for (int i = 0; i < normalizedName.length; i++) {
      final char = normalizedName[i];
      if (char != ' ' && vowels.contains(char)) {
        sum += letterValues[char] ?? 0;
      }
    }

    return _reduceToMasterNumber(sum);
  }

  int calculatePersonalYear(DateTime birthDate, DateTime currentDate) {
    int day = birthDate.day;
    int month = birthDate.month;
    int year = currentDate.year;

    return _reduceToMasterNumber(day + month + _reduceYear(year));
  }

  int calculatePersonalMonth(DateTime birthDate, DateTime currentDate) {
    final personalYear = calculatePersonalYear(birthDate, currentDate);
    return _reduceToMasterNumber(personalYear + currentDate.month);
  }

  int calculatePersonalDay(DateTime birthDate, DateTime currentDate) {
    final personalMonth = calculatePersonalMonth(birthDate, currentDate);
    return _reduceToMasterNumber(personalMonth + currentDate.day);
  }

  int _reduceToMasterNumber(int number) {
    while (number > 9 && number != 11 && number != 22 && number != 33) {
      int sum = 0;
      while (number > 0) {
        sum += number % 10;
        number ~/= 10;
      }
      number = sum;
    }
    return number;
  }

  String _normalizeName(String name) {
    return name
        .toUpperCase()
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ë', 'E')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ä', 'A')
        .replaceAll('Ç', 'C')
        .replaceAll('Î', 'I')
        .replaceAll('Ï', 'I')
        .replaceAll('Ô', 'O')
        .replaceAll('Ö', 'O')
        .replaceAll('Ù', 'U')
        .replaceAll('Û', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ÿ', 'Y');
  }

  // Méthodes pour créer des profils simulés
  NumerologyProfile _createMockProfile(Map<String, dynamic> requestData) {
    final userId = requestData['userId'] as int?;
    final fullName = requestData['fullName'] as String? ?? 'Utilisateur';
    final birthDate = DateTime.parse(requestData['birthDate'] as String);
    final now = DateTime.now();

    // Calculer les nombres
    final lifePathNumber = calculateLifePathNumber(birthDate);
    final expressionNumber = calculateExpressionNumber(fullName);
    final realizationNumber = calculateRealizationNumber(fullName);
    final soulUrgeNumber = calculateSoulUrgeNumber(fullName);
    final personalYear = calculatePersonalYear(birthDate, now);
    final personalMonth = calculatePersonalMonth(birthDate, now);
    final personalDay = calculatePersonalDay(birthDate, now);

    return NumerologyProfile(
      userId: userId,
      birthDate: birthDate,
      fullName: fullName,
      lifePathNumber: lifePathNumber,
      expressionNumber: expressionNumber,
      realizationNumber: realizationNumber,
      soulUrgeNumber: soulUrgeNumber,
      personalYear: personalYear,
      personalMonth: personalMonth,
      personalDay: personalDay,
      summary: _generateSummary(
        fullName,
        lifePathNumber,
        expressionNumber,
        realizationNumber,
      ),
      createdAt: now,
      updatedAt: now,
      lifePathInterpretation: _getLifePathInterpretation(lifePathNumber),
      expressionInterpretation: _getExpressionInterpretation(expressionNumber),
      realizationInterpretation: _getRealizationInterpretation(
        realizationNumber,
      ),
      soulUrgeInterpretation: _getSoulUrgeInterpretation(soulUrgeNumber),
      personalYearInterpretation: _getPersonalYearInterpretation(personalYear),
      personalMonthInterpretation: _getPersonalMonthInterpretation(
        personalMonth,
      ),
      personalDayInterpretation: _getPersonalDayInterpretation(personalDay),
    );
  }

  NumerologyProfile _createFallbackProfile(Map<String, dynamic> requestData) {
    final userId = requestData['userId'] as int?;
    final fullName = requestData['fullName'] as String? ?? 'Utilisateur';
    final birthDate = DateTime.parse(requestData['birthDate'] as String);
    final now = DateTime.now();

    return NumerologyProfile(
      userId: userId,
      birthDate: birthDate,
      fullName: fullName,
      lifePathNumber: 5,
      expressionNumber: 3,
      realizationNumber: 7,
      soulUrgeNumber: 9,
      personalYear: 5,
      personalMonth: 9,
      personalDay: 3,
      summary:
          'Votre profil révèle une personnalité équilibrée entre aventure et réflexion.',
      createdAt: now,
      updatedAt: now,
      lifePathInterpretation:
          'Le libre chercheur d\'expériences et d\'aventures.',
      expressionInterpretation: 'L\'artiste communicatif et joyeux.',
      realizationInterpretation: 'Le chercheur spirituel et analytique.',
      soulUrgeInterpretation: 'L\'humaniste au grand cœur.',
      personalYearInterpretation: 'Année de changement et de liberté.',
      personalMonthInterpretation: 'Mois de complétion et de réflexion.',
      personalDayInterpretation: 'Jour de créativité et d\'expression.',
    );
  }

  // Méthodes d'interprétation
  String _getLifePathInterpretation(int number) {
    final interpretations = {
      1: 'Le leader né, indépendant et pionnier. Votre chemin vous pousse à prendre des initiatives et à créer.',
      2: 'Le diplomate sensible, coopératif et pacificateur. Vous excellez dans les relations et la collaboration.',
      3: 'L\'artiste communicatif, joyeux et créatif. Vous exprimez votre joie de vivre à travers l\'art et la communication.',
      4: 'Le bâtisseur pratique, stable et travailleur. Vous construisez des fondations solides avec persévérance.',
      5: 'L\'aventurier libre, adaptable et curieux. Vous cherchez la variété et les nouvelles expériences.',
      6: 'Le protecteur nourricier, responsable et attentionné. Vous prenez soin des autres avec amour.',
      7: 'Le chercheur spirituel, analytique et introspectif. Vous cherchez la vérité et la connaissance profonde.',
      8: 'Le stratège ambitieux, puissant et efficace. Vous excellez dans le monde matériel et l\'organisation.',
      9: 'L\'humaniste compatissant, sage et altruiste. Vous servez l\'humanité avec un grand cœur.',
      11: 'L\'illuminateur intuitif, visionnaire et inspirant. Vous guidez les autres par votre sagesse.',
      22: 'Le maître bâtisseur, visionnaire et réalisateur. Vous transformez les grands rêves en réalité.',
      33: 'L\'enseignant suprême, guérisseur et guide spirituel. Vous apportez compassion et service au monde.',
    };

    return interpretations[number] ??
        'Votre chemin de vie est unique et spécial.';
  }

  String _getExpressionInterpretation(int number) {
    final interpretations = {
      1: 'Votre potentiel s\'exprime par le leadership, l\'innovation et l\'indépendance.',
      2: 'Vous vous exprimez avec diplomatie, sensibilité et talent pour la coopération.',
      3: 'Votre expression est créative, joyeuse et communicative. L\'art est votre langage.',
      4: 'Vous exprimez votre potentiel par le travail pratique, l\'organisation et la stabilité.',
      5: 'Votre expression est libre, adaptative et curieuse. Le changement vous stimule.',
      6: 'Vous vous exprimez avec responsabilité, amour et talent pour prendre soin des autres.',
      7: 'Votre expression est analytique, spirituelle et profonde. La sagesse vous guide.',
      8: 'Vous exprimez votre puissance par l\'ambition, l\'efficacité et le sens des affaires.',
      9: 'Votre expression est altruiste, sage et compatissante. Vous servez l\'humanité.',
    };

    return interpretations[number] ??
        'Votre potentiel d\'expression est riche et diversifié.';
  }

  String _getRealizationInterpretation(int number) {
    final interpretations = {
      1: 'Vous accomplissez par l\'initiative, le courage et la création de nouvelles voies.',
      2: 'Vos réalisations viennent de la coopération, de la patience et du travail d\'équipe.',
      3: 'Vous accomplissez à travers la créativité, la joie et l\'expression artistique.',
      4: 'Vos réalisations sont concrètes, stables et basées sur un travail assidu.',
      5: 'Vous accomplissez en embrassant le changement, la liberté et les nouvelles expériences.',
      6: 'Vos réalisations viennent du service, de la famille et de la création d\'harmonie.',
      7: 'Vous accomplissez par la recherche, l\'analyse et la quête de connaissance.',
      8: 'Vos réalisations sont matérielles, ambitieuses et marquées par le succès.',
      9: 'Vous accomplissez à travers le service humanitaire, la sagesse et l\'altruisme.',
    };

    return interpretations[number] ??
        'Vos accomplissements sont uniques et significatifs.';
  }

  String _getSoulUrgeInterpretation(int number) {
    final interpretations = {
      1: 'Votre désir intime est l\'indépendance, le leadership et la reconnaissance personnelle.',
      2: 'Vous désirez profondément l\'harmonie, la paix et des relations équilibrées.',
      3: 'Votre âme aspire à la créativité, à la joie et à l\'expression artistique.',
      4: 'Vous désirez la stabilité, la sécurité et une fondation solide dans votre vie.',
      5: 'Votre désir le plus profond est la liberté, l\'aventure et le changement.',
      6: 'Vous aspirez à l\'amour, à la famille et à prendre soin des autres.',
      7: 'Votre âme cherche la connaissance, la spiritualité et la vérité profonde.',
      8: 'Vous désirez le succès, l\'abondance et la reconnaissance matérielle.',
      9: 'Votre aspiration la plus profonde est le service, l\'humanité et l\'amour universel.',
    };

    return interpretations[number] ??
        'Vos désirs intimes sont riches et profonds.';
  }

  String _getPersonalYearInterpretation(int year) {
    final interpretations = {
      1: 'Année de nouveaux départs, d\'initiatives et d\'indépendance.',
      2: 'Année de relations, de coopération et de développement personnel.',
      3: 'Année de créativité, d\'expression et de joie de vivre.',
      4: 'Année de travail, de stabilité et de construction de fondations.',
      5: 'Année de changement, de liberté et d\'opportunités nouvelles.',
      6: 'Année de famille, de responsabilités et d\'harmonie.',
      7: 'Année de réflexion, de spiritualité et de développement intérieur.',
      8: 'Année de succès matériel, de reconnaissance et d\'abondance.',
      9: 'Année de complétion, de transformation et de nouveaux cycles.',
    };

    return interpretations[year] ??
        'Cette année vous apporte des énergies uniques.';
  }

  String _getPersonalMonthInterpretation(int month) {
    final interpretations = {
      1: 'Mois pour prendre des initiatives et commencer de nouveaux projets.',
      2: 'Mois pour développer les relations et travailler en coopération.',
      3: 'Mois pour exprimer votre créativité et votre joie de vivre.',
      4: 'Mois pour travailler dur et construire des fondations solides.',
      5: 'Mois pour embrasser le changement et explorer de nouvelles possibilités.',
      6: 'Mois pour prendre soin de la famille et créer l\'harmonie.',
      7: 'Mois pour la réflexion intérieure et le développement spirituel.',
      8: 'Mois pour atteindre des objectifs matériels et obtenir la reconnaissance.',
      9: 'Mois pour terminer des cycles et préparer de nouveaux départs.',
    };

    return interpretations[month] ??
        'Ce mois vous apporte des opportunités de croissance.';
  }

  String _getPersonalDayInterpretation(int day) {
    final interpretations = {
      1: 'Jour idéal pour prendre des décisions importantes et des initiatives.',
      2: 'Jour parfait pour la coopération et les échanges harmonieux.',
      3: 'Jour propice à la créativité et à l\'expression personnelle.',
      4: 'Jour favorable au travail structuré et aux projets pratiques.',
      5: 'Jour d\'aventure, de changement et de nouvelles expériences.',
      6: 'Jour pour prendre soin des autres et créer l\'harmonie familiale.',
      7: 'Jour pour la réflexion, l\'étude et le développement intérieur.',
      8: 'Jour idéal pour les affaires, les finances et la reconnaissance.',
      9: 'Jour pour terminer des projets et se préparer à de nouveaux cycles.',
    };

    return interpretations[day] ??
        'Profitez de l\'énergie spéciale de ce jour.';
  }

  String _generateSummary(
    String fullName,
    int lifePath,
    int expression,
    int realization,
  ) {
    final summaries = [
      'Votre profil numérologique révèle une personnalité unique et équilibrée. '
          'Votre chemin de vie $lifePath vous guide vers des expériences enrichissantes '
          'tandis que votre expression $expression illumine vos relations.',

      'L\'harmonie entre votre chemin de vie $lifePath, votre expression $expression '
          'et vos réalisations $realization crée un équilibre parfait entre vos aspirations '
          'intérieures et vos accomplissements extérieurs.',

      'Vos nombres sacrés ($lifePath, $expression, $realization) travaillent en synergie '
          'pour vous guider vers votre plus haut potentiel. Chaque jour est une opportunité '
          'de grandir et d\'évoluer.',
    ];

    return summaries[Random().nextInt(summaries.length)];
  }

  // Méthodes pour les recommandations
  List<String> generateDailyRecommendations(NumerologyProfile profile) {
    final recommendations = <String>[];
    final now = DateTime.now();
    final personalDay = calculatePersonalDay(profile.birthDate, now);

    recommendations.add(
      'Méditez avec votre nombre chemin de vie (${profile.lifePathNumber})',
    );

    switch (personalDay) {
      case 1:
        recommendations.add('Prenez une décision importante aujourd\'hui');
        recommendations.add('Lancez un nouveau projet');
        break;
      case 2:
        recommendations.add('Coopérez avec d\'autres personnes');
        recommendations.add('Écoutez attentivement vos proches');
        break;
      case 3:
        recommendations.add('Exprimez votre créativité');
        recommendations.add('Partagez votre joie avec les autres');
        break;
      case 4:
        recommendations.add('Organisez votre espace de travail');
        recommendations.add('Travaillez sur des projets concrets');
        break;
      case 5:
        recommendations.add('Essayez quelque chose de nouveau');
        recommendations.add('Sortez de votre zone de confort');
        break;
      case 6:
        recommendations.add('Prenez soin de votre famille');
        recommendations.add('Créez de l\'harmonie dans votre environnement');
        break;
      case 7:
        recommendations.add('Prenez du temps pour la réflexion');
        recommendations.add('Lisez un livre inspirant');
        break;
      case 8:
        recommendations.add('Travaillez sur vos objectifs financiers');
        recommendations.add('Planifiez votre succès');
        break;
      case 9:
        recommendations.add('Terminez des projets en cours');
        recommendations.add('Préparez-vous à un nouveau cycle');
        break;
    }

    // Ajouter des recommandations basées sur le profil
    if (profile.lifePathNumber == 7 || profile.realizationNumber == 7) {
      recommendations.add('Pratiquez la méditation quotidienne');
    }

    if (profile.expressionNumber == 3 || profile.lifePathNumber == 3) {
      recommendations.add('Exprimez-vous à travers l\'art ou l\'écriture');
    }

    if (profile.soulUrgeNumber == 6 || profile.lifePathNumber == 6) {
      recommendations.add('Prenez soin des autres aujourd\'hui');
    }

    return recommendations;
  }

  // Méthode pour obtenir l'énergie du jour
  Map<String, dynamic> getDailyEnergy(NumerologyProfile profile) {
    final now = DateTime.now();
    final personalDay = calculatePersonalDay(profile.birthDate, now);

    final energies = {
      1: {'energy': 'Début', 'color': 0xFF8B6B9E, 'icon': '🚀'},
      2: {'energy': 'Coopération', 'color': 0xFF5D8CAE, 'icon': '🤝'},
      3: {'energy': 'Créativité', 'color': 0xFFF6C667, 'icon': '🎨'},
      4: {'energy': 'Stabilité', 'color': 0xFF4CAF50, 'icon': '🏗️'},
      5: {'energy': 'Changement', 'color': 0xFFFF9800, 'icon': '🌀'},
      6: {'energy': 'Harmonie', 'color': 0xFFE91E63, 'icon': '❤️'},
      7: {'energy': 'Spiritualité', 'color': 0xFF9C27B0, 'icon': '🧘'},
      8: {'energy': 'Succès', 'color': 0xFF2196F3, 'icon': '💼'},
      9: {'energy': 'Transformation', 'color': 0xFF607D8B, 'icon': '🔄'},
    };

    return energies[personalDay] ??
        {'energy': 'Équilibre', 'color': 0xFF8B6B9E, 'icon': '⚖️'};
  }
}
