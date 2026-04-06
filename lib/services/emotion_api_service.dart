// lib/services/emotion_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/mood_entry_enhanced.dart';
import 'api_service.dart';

class EmotionApiService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'mood-entries';

  EmotionApiService() : _apiService = ApiService();

  // Méthode pour obtenir les headers avec userId
  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      // Obtenir userId depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ UserId non trouvé dans SharedPreferences');
        }
        // Essayer de récupérer depuis auth_data
        final authData = prefs.getString('auth_data');
        if (authData != null) {
          try {
            final data = jsonDecode(authData) as Map<String, dynamic>;
            final extractedUserId = data['userId'];
            if (extractedUserId != null) {
              // Sauvegarder pour usage futur
              await prefs.setInt('userId', extractedUserId as int);
              if (kDebugMode) {
                print('👤 UserId récupéré depuis auth_data: $extractedUserId');
              }
              return await _apiService.getHeadersWithUserId(
                extractedUserId as int,
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Erreur parsing auth_data: $e');
            }
          }
        }
        // Fallback: headers sans userId
        if (kDebugMode) {
          print('⚠️ Utilisation des headers sans userId');
        }
        return await _apiService.getHeaders();
      }

      if (kDebugMode) {
        print('👤 Utilisation du userId: $userId');
      }
      return await _apiService.getHeadersWithUserId(userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _getHeadersWithUserId: $e');
      }
      // Fallback: headers sans userId
      return await _apiService.getHeaders();
    }
  }

  // Récupérer toutes les entrées d'humeur
  Future<List<MoodEntryEnhanced>> getEnhancedMoodEntries() async {
    try {
      if (kDebugMode) {
        print('🧠 DEBUT getEnhancedMoodEntries');
      }

      // Obtenir userId
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID non disponible. Veuillez vous reconnecter.');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
        if (headers.containsKey('X-User-Id')) {
          print('👤 X-User-Id envoyé: ${headers['X-User-Id']}');
        }
      }

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
        print('📥 Content length: ${response.contentLength} bytes');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération humeurs: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'] as List<dynamic>;
          return data.map((json) => MoodEntryEnhanced.fromJson(json)).toList();
        }
      } else if (jsonResponse is List) {
        return jsonResponse
            .map((json) => MoodEntryEnhanced.fromJson(json))
            .toList();
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getEnhancedMoodEntries: $e');
      }
      rethrow;
    }
  }

  // Sauvegarder une nouvelle entrée
  Future<MoodEntryEnhanced> saveEnhancedMoodEntry(
    MoodEntryEnhanced entry,
  ) async {
    try {
      if (kDebugMode) {
        print('🧠 DEBUT saveEnhancedMoodEntry');
        print('🎯 Émotion primaire: ${entry.primaryEmotion}');
        print('⚡ Intensité: ${entry.intensity}');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint');
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 POST $url');
        print('📤 Body: ${jsonEncode(entry.toJson())}');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(entry.toJson()),
      );

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur sauvegarde humeur: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      // Gérer la réponse formatée avec ApiResponse
      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return MoodEntryEnhanced.fromJson(jsonResponse['data']);
        } else {
          return MoodEntryEnhanced.fromJson(jsonResponse);
        }
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur saveEnhancedMoodEntry: $e');
      }
      rethrow;
    }
  }

  // Analyser le texte pour détecter l'émotion
  Future<Map<String, dynamic>> analyzeTextEmotion(String text) async {
    try {
      if (kDebugMode) {
        print('🔍 DEBUT analyzeTextEmotion');
        print('📝 Texte: ${text.length} caractères');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/analyze-text',
      );
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      final body = {'text': text};

      if (kDebugMode) {
        print('📤 POST $url');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur analyse texte: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
        return jsonResponse;
      }

      // Fallback: analyse simple basée sur les mots clés
      return _fallbackTextAnalysis(text);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur analyzeTextEmotion: $e');
        print('🔄 Utilisation de l\'analyse de fallback');
      }
      return _fallbackTextAnalysis(text);
    }
  }

  // Fallback pour l'analyse de texte (si le serveur n'est pas disponible)
  Map<String, dynamic> _fallbackTextAnalysis(String text) {
    final lowercaseText = text.toLowerCase();

    // Détection des émotions basée sur les mots clés
    final positiveWords = [
      'heureux',
      'content',
      'joyeux',
      'bien',
      'super',
      'génial',
      'merveilleux',
      'excellent',
    ];
    final negativeWords = [
      'triste',
      'malheureux',
      'colère',
      'énervé',
      'fatigué',
      'stressé',
      'anxieux',
      'déprimé',
    ];
    final fearWords = ['peur', 'inquiet', 'anxieux', 'paniqué', 'terrifié'];
    final angerWords = ['colère', 'énervé', 'fâché', 'furieux', 'rage'];
    final loveWords = ['amour', 'aimer', 'adorer', 'affection', 'tendre'];

    int positiveScore = 0;
    int negativeScore = 0;
    int fearScore = 0;
    int angerScore = 0;
    int loveScore = 0;

    for (final word in positiveWords) {
      if (lowercaseText.contains(word)) positiveScore++;
    }
    for (final word in negativeWords) {
      if (lowercaseText.contains(word)) negativeScore++;
    }
    for (final word in fearWords) {
      if (lowercaseText.contains(word)) fearScore++;
    }
    for (final word in angerWords) {
      if (lowercaseText.contains(word)) angerScore++;
    }
    for (final word in loveWords) {
      if (lowercaseText.contains(word)) loveScore++;
    }

    final scores = {
      'Joie': positiveScore,
      'Tristesse': negativeScore,
      'Peur': fearScore,
      'Colère': angerScore,
      'Amour': loveScore,
    };

    final dominantEmotion = scores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'dominantEmotion': dominantEmotion,
      'confidence': 0.7,
      'scores': scores,
      'analysis': 'Analyse locale basée sur les mots clés',
    };
  }

  // Récupérer les statistiques
  // Dans EmotionApiService.dart
  Future<Map<String, dynamic>> getUserStatistics(int days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID non disponible');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/statistics?days=$days',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📊 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          print(
            '📥 Body preview: ${response.body.substring(0, min(300, response.body.length))}...',
          );
        }
      }

      if (response.statusCode >= 400) {
        throw Exception('Erreur récupération statistiques');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      // Log pour déboguer
      if (kDebugMode) {
        print('🔍 Response type: ${jsonResponse.runtimeType}');
        if (jsonResponse is Map<String, dynamic>) {
          print('🔍 Keys: ${jsonResponse.keys.join(', ')}');
        }
      }

      // Retourner directement la réponse sans wrapper
      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
        return jsonResponse;
      }

      return {};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getUserStatistics: $e');
      }
      return {};
    }
  }

  // Récupérer les entrées récentes
  Future<List<MoodEntryEnhanced>> getRecentMoodEntries(int days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID non disponible');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/recent?days=$days',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur récupération entrées récentes');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'] as List<dynamic>;
          return data.map((json) => MoodEntryEnhanced.fromJson(json)).toList();
        }
      } else if (jsonResponse is List) {
        return jsonResponse
            .map((json) => MoodEntryEnhanced.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getRecentMoodEntries: $e');
      }
      return [];
    }
  }

  // Récupérer les entrées nécessitant une attention
  Future<List<MoodEntryEnhanced>> getEntriesRequiringAttention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID non disponible');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/needs-attention',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur récupération entrées à risque');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'] as List<dynamic>;
          return data.map((json) => MoodEntryEnhanced.fromJson(json)).toList();
        }
      } else if (jsonResponse is List) {
        return jsonResponse
            .map((json) => MoodEntryEnhanced.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getEntriesRequiringAttention: $e');
      }
      return [];
    }
  }

  // Mettre à jour une entrée
  Future<MoodEntryEnhanced> updateMoodEntry(MoodEntryEnhanced entry) async {
    try {
      if (kDebugMode) {
        print('🧠 DEBUT updateMoodEntry: ${entry.id}');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/${entry.id}');
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(entry.toJson()),
      );

      if (response.statusCode >= 400) {
        throw Exception('Erreur mise à jour humeur');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return MoodEntryEnhanced.fromJson(jsonResponse['data']);
        }
        return MoodEntryEnhanced.fromJson(jsonResponse);
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur updateMoodEntry: $e');
      }
      rethrow;
    }
  }

  // Supprimer une entrée
  Future<void> deleteMoodEntry(int id) async {
    try {
      if (kDebugMode) {
        print('🧠 DEBUT deleteMoodEntry: $id');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');
      final headers = await _getHeadersWithUserId();

      final response = await http.delete(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur suppression humeur');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur deleteMoodEntry: $e');
      }
      rethrow;
    }
  }

  // Récupérer le dashboard summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID non disponible');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/dashboard',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur récupération dashboard');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
        return jsonResponse;
      }

      return {};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getDashboardSummary: $e');
      }
      return {};
    }
  }

  // Détecter les patterns
  Future<Map<String, dynamic>> detectPatterns(int days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID non disponible');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/patterns?days=$days',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur détection patterns');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return jsonResponse['data'] as Map<String, dynamic>;
        }
        return jsonResponse;
      }

      return {};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur detectPatterns: $e');
      }
      return {};
    }
  }

  // Générer des recommandations
  Future<List<String>> generateRecommendations(int days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID non disponible');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/recommendations?days=$days',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur génération recommandations');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return List<String>.from(jsonResponse['data']);
        } else if (jsonResponse.containsKey('recommendations')) {
          return List<String>.from(jsonResponse['recommendations']);
        }
      }

      // Recommandations par défaut
      return [
        'Essayez de méditer 10 minutes par jour',
        'Notez 3 choses positives chaque soir',
        'Faites une promenade dans la nature',
        'Contactez un ami proche pour discuter',
        'Pratiquez la respiration profonde',
      ];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur generateRecommendations: $e');
      }
      return [
        'Essayez de méditer 10 minutes par jour',
        'Notez 3 choses positives chaque soir',
        'Faites une promenade dans la nature',
      ];
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return 'Réponse vide du serveur';
      }

      final jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ??
            jsonBody['error'] ??
            jsonBody['detail'] ??
            'Erreur serveur (${response.statusCode})';
      }
      return 'Erreur: ${response.statusCode}';
    } catch (e) {
      // Si le body n'est pas du JSON
      if (response.body.length > 200) {
        return 'Erreur: ${response.body.substring(0, 200)}...';
      }
      return 'Erreur: ${response.body}';
    }
  }

  /// Nettoie les caches mémoire (et plus tard les SharedPreferences si besoin)
  Future<void> clearCache() async {
    // Aucun cache persistant pour l’instant, mais on peut ajouter ici
    // la suppression de clés SharedPreferences si nécessaire.
    if (kDebugMode) print('🧹 EmotionApiService cache cleared');
    return Future.value();
  }
}
