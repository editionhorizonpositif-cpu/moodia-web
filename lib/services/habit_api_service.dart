// lib/services/habit_api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'api_service.dart';

class HabitApiService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'v1/habits';

  HabitApiService() : _apiService = ApiService();

  // Méthode pour obtenir les headers avec userId
  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (kDebugMode) {
          print(
            '⚠️ UserId non trouvé dans SharedPreferences pour HabitService',
          );
        }
        final authData = prefs.getString('auth_data');
        if (authData != null) {
          try {
            final data = jsonDecode(authData) as Map<String, dynamic>;
            final extractedUserId = data['userId'];
            if (extractedUserId != null) {
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
      }

      if (kDebugMode) {
        print('👤 HabitService - Utilisation du userId: $userId');
      }
      return await _apiService.getHeadersWithUserId(userId!);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _getHeadersWithUserId: $e');
      }
      return await _apiService.getHeaders();
    }
  }

  // CRUD Habit
  // lib/services/habit_api_service.dart - Améliorez la méthode createHabit
  Future<Habit> createHabit(Map<String, dynamic> habitData) async {
    try {
      if (kDebugMode) {
        print('🎯 DEBUT createHabit');
        print('📝 Données brutes: $habitData');
        print('📝 Frequency: ${habitData['frequency']}');
        print('📝 Category: ${habitData['category']}');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint');
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 POST $url');
        print('📤 Body JSON: ${jsonEncode(habitData)}');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(habitData),
      );

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
        print('📥 Headers: ${response.headers}');
        if (response.body.length > 500) {
          print('📥 Body (tronqué): ${response.body.substring(0, 500)}...');
        } else {
          print('📥 Body: ${response.body}');
        }
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur création habitude: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      // Gérer la réponse formatée avec ApiResponse
      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return Habit.fromJson(jsonResponse['data']);
        } else {
          return Habit.fromJson(jsonResponse);
        }
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur createHabit: $e');
        print('🔍 Stack trace: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<Habit> getHabitById(int id) async {
    try {
      if (kDebugMode) {
        print('🎯 DEBUT getHabitById: $id');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération habitude: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return Habit.fromJson(jsonResponse['data']);
        }
        return Habit.fromJson(jsonResponse);
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getHabitById: $e');
      }
      rethrow;
    }
  }

  Future<List<Habit>> getHabitsByUser(int userId) async {
    try {
      if (kDebugMode) {
        print('🎯 DEBUT getHabitsByUser: $userId');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération habitudes: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      // Gérer la réponse formatée avec ApiResponse
      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'] as List<dynamic>;
          return data.map((json) => Habit.fromJson(json)).toList();
        }
      } else if (jsonResponse is List) {
        return jsonResponse.map((json) => Habit.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getHabitsByUser: $e');
      }
      rethrow;
    }
  }

  Future<Habit> updateHabit(int id, Map<String, dynamic> habitData) async {
    try {
      if (kDebugMode) {
        print('🎯 DEBUT updateHabit: $id');
        print('📝 Données: $habitData');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 PUT $url');
      }

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(habitData),
      );

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur mise à jour habitude: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return Habit.fromJson(jsonResponse['data']);
        }
        return Habit.fromJson(jsonResponse);
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur updateHabit: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteHabit(int id) async {
    try {
      if (kDebugMode) {
        print('🎯 DEBUT deleteHabit: $id');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 DELETE $url');
      }

      final response = await http.delete(url, headers: headers);

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur suppression habitude: $errorMsg');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur deleteHabit: $e');
      }
      rethrow;
    }
  }

  // Habit completion
  Future<Habit> toggleHabitCompletion(int id) async {
    try {
      if (kDebugMode) {
        print('🎯 DEBUT toggleHabitCompletion: $id');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id/toggle');
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 POST $url');
      }

      final response = await http.post(url, headers: headers);

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur toggle completion: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return Habit.fromJson(jsonResponse['data']);
        }
        return Habit.fromJson(jsonResponse);
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur toggleHabitCompletion: $e');
      }
      rethrow;
    }
  }

  // Templates
  Future<List<Map<String, dynamic>>> getHabitTemplates() async {
    try {
      if (kDebugMode) {
        print('🎯 DEBUT getHabitTemplates');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/templates');
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération templates: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'] as List<dynamic>;
          return data.map((json) => json as Map<String, dynamic>).toList();
        }
      } else if (jsonResponse is List) {
        return jsonResponse
            .map((json) => json as Map<String, dynamic>)
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getHabitTemplates: $e');
      }
      return _getFallbackTemplates();
    }
  }

  Future<Habit> createHabitFromTemplate(int templateId, int userId) async {
    try {
      if (kDebugMode) {
        print('🎯 DEBUT createHabitFromTemplate: $templateId, $userId');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/templates/$templateId/create?userId=$userId',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 POST $url');
      }

      final response = await http.post(url, headers: headers);

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur création depuis template: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          return Habit.fromJson(jsonResponse['data']);
        }
        return Habit.fromJson(jsonResponse);
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur createHabitFromTemplate: $e');
      }
      rethrow;
    }
  }

  // Filtres et recherches
  Future<List<Habit>> getHabitsByCategory(int userId, String category) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/category/$category',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur récupération par catégorie');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'] as List<dynamic>;
          return data.map((json) => Habit.fromJson(json)).toList();
        }
      } else if (jsonResponse is List) {
        return jsonResponse.map((json) => Habit.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getHabitsByCategory: $e');
      }
      return [];
    }
  }

  Future<List<Habit>> getTodayHabits(int userId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/today',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur récupération habitudes du jour');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse.containsKey('data')) {
          final data = jsonResponse['data'] as List<dynamic>;
          return data.map((json) => Habit.fromJson(json)).toList();
        }
      } else if (jsonResponse is List) {
        return jsonResponse.map((json) => Habit.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getTodayHabits: $e');
      }
      return [];
    }
  }

  // Helper pour les templates par défaut
  List<Map<String, dynamic>> _getFallbackTemplates() {
    return [
      {
        'id': 1,
        'name': 'Méditation matinale',
        'description':
            '10 minutes de méditation pour commencer la journée en pleine conscience',
        'frequency': 'daily',
        'category': 'mentalBienEtre',
        'goalCount': 1,
        'color': Colors.purple.value,
        'icon': 'self_improvement',
      },
      {
        'id': 2,
        'name': 'Boire 2L d\'eau',
        'description':
            'Maintenir une bonne hydratation tout au long de la journée',
        'frequency': 'daily',
        'category': 'santePhysique',
        'goalCount': 8,
        'color': Colors.blue.value,
        'icon': 'water_drop',
      },
    ];
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
      if (response.body.length > 200) {
        return 'Erreur: ${response.body.substring(0, 200)}...';
      }
      return 'Erreur: ${response.body}';
    }
  }
}
