/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../models/challenge_category.dart';
import '../models/challenge_participation.dart';
import '../models/challenge_completion.dart';
import '../models/challenge_statistics.dart';
import '../models/challenge_completion_statistics.dart';
import '../models/category_statistics.dart';
import '../models/paged_response.dart';
import '../models/challenge_request_dtos.dart';
import 'api_service.dart';

class ChallengeApiService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'v1/challenges';
  static const String _categoryEndpoint = 'challenge-categories';
  static const String _completionEndpoint = 'completions';

  ChallengeApiService(this._apiService);

  // ==================== MÉTHODES UTILITAIRES ====================

  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (kDebugMode) print('⚠️ UserId non trouvé dans SharedPreferences');
        return await _apiService.getHeaders();
      }

      if (kDebugMode) print('👤 Utilisation du userId: $userId');
      return await _apiService.getHeadersWithUserId(userId);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur _getHeadersWithUserId: $e');
      return await _apiService.getHeaders();
    }
  }

  Future<int?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('userId');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur récupération userId: $e');
      return null;
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      if (response.body.isEmpty) return 'Réponse vide du serveur';

      final jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ??
            jsonBody['error'] ??
            jsonBody['detail'] ??
            'Erreur serveur (${response.statusCode})';
      }
      return 'Erreur: ${response.statusCode}';
    } catch (e) {
      return 'Erreur: ${response.statusCode}';
    }
  }

  // ==================== MÉTHODES CHALLENGES ====================

  // Récupérer tous les défis avec pagination
  Future<PagedResponse<Challenge>> getAllChallenges({
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    try {
      if (kDebugMode) print('📋 DEBUT getAllChallenges');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('📤 GET $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) print('📥 Status: ${response.statusCode}');

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      if (response.body.isEmpty) {
        return PagedResponse<Challenge>(
          content: [],
          page: page,
          size: size,
          totalElements: 0,
          totalPages: 0,
          last: true,
          first: true,
          empty: true,
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getAllChallenges: $e');
      rethrow;
    }
  }

  // Récupérer les défis actifs
  Future<PagedResponse<Challenge>> getActiveChallenges({
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/active',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getActiveChallenges: $e');
      rethrow;
    }
  }

  // Récupérer un défi par ID
  Future<Challenge> getChallengeById(int id, {int? userId}) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');

      Map<String, String> headers;
      if (userId != null) {
        headers = await _apiService.getHeadersWithUserId(userId);
      } else {
        headers = await _getHeadersWithUserId();
      }

      if (kDebugMode) print('📤 GET $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        throw Exception('Défi non trouvé');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengeById: $e');
      rethrow;
    }
  }

  // Récupérer un défi avec statut utilisateur
  Future<Challenge> getChallengeByIdWithUserStatus(int id, int userId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$id',
      ).replace(queryParameters: {'userId': userId.toString()});

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 GET $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        throw Exception('Défi non trouvé');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengeByIdWithUserStatus: $e');
      rethrow;
    }
  }

  // Récupérer les défis par catégorie
  Future<PagedResponse<Challenge>> getChallengesByCategory(
    int categoryId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/category/$categoryId',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengesByCategory: $e');
      rethrow;
    }
  }

  // Récupérer les défis par difficulté
  Future<PagedResponse<Challenge>> getChallengesByDifficulty(
    String difficulty, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/difficulty/$difficulty',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengesByDifficulty: $e');
      rethrow;
    }
  }

  // Récupérer les défis en vedette
  Future<PagedResponse<Challenge>> getFeaturedChallenges({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/featured',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getFeaturedChallenges: $e');
      rethrow;
    }
  }

  // Récupérer les défis avec places disponibles
  Future<PagedResponse<Challenge>> getChallengesWithAvailableSlots({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/available-slots',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengesWithAvailableSlots: $e');
      rethrow;
    }
  }

  // Rechercher des défis
  Future<PagedResponse<Challenge>> searchChallenges(
    String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'keyword': keyword,
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/search',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur searchChallenges: $e');
      rethrow;
    }
  }

  // Récupérer les défis recommandés pour un utilisateur
  Future<List<Challenge>> getRecommendedChallenges(int userId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/recommended',
      ).replace(queryParameters: {'userId': userId.toString()});

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonList = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return jsonList
          .map((json) => Challenge.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getRecommendedChallenges: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES ADMIN ====================

  // Créer un nouveau défi
  Future<Challenge> createChallenge(CreateChallengeRequest request) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 POST $url');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur création (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur createChallenge: $e');
      rethrow;
    }
  }

  // Mettre à jour un défi
  Future<Challenge> updateChallenge(
    int id,
    UpdateChallengeRequest request,
  ) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 PUT $url');

      final response = await http
          .put(url, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur mise à jour (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateChallenge: $e');
      rethrow;
    }
  }

  // Supprimer un défi (soft delete)
  Future<void> deleteChallenge(int id) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 DELETE $url');

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur suppression (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur deleteChallenge: $e');
      rethrow;
    }
  }

  // Activer/désactiver un défi
  Future<Challenge> toggleChallengeStatus(int id, bool active) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$id/status',
      ).replace(queryParameters: {'active': active.toString()});

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 PATCH $url');

      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur changement statut (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur toggleChallengeStatus: $e');
      rethrow;
    }
  }

  // Approuver un défi
  Future<Challenge> approveChallenge(int id) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id/approve');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 PATCH $url');

      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur approbation (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur approveChallenge: $e');
      rethrow;
    }
  }

  // Rejeter un défi
  Future<Challenge> rejectChallenge(int id) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id/reject');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 PATCH $url');

      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur rejet (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur rejectChallenge: $e');
      rethrow;
    }
  }

  // Récupérer les défis par statut (admin)
  Future<PagedResponse<Challenge>> getChallengesByStatus(
    String status, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/admin/status/$status',
      ).replace(queryParameters: queryParams);

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengesByStatus: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES PARTICIPATION ====================

  // Rejoindre un défi
  Future<Challenge> joinChallenge(
    int challengeId,
    ChallengeParticipationRequest request,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$challengeId/join',
      );

      final headers = await _apiService.getHeadersWithUserId(request.userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 POST $url');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur adhésion (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur joinChallenge: $e');
      rethrow;
    }
  }

  // Quitter un défi
  Future<void> leaveChallenge(int challengeId, int userId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$challengeId/leave',
      ).replace(queryParameters: {'userId': userId.toString()});

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 DELETE $url');

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur abandon (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur leaveChallenge: $e');
      rethrow;
    }
  }

  // Mettre à jour la progression
  Future<Challenge> updateProgress(
    int challengeId,
    int userId,
    ChallengeProgressRequest request,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$challengeId/progress',
      ).replace(queryParameters: {'userId': userId.toString()});

      final headers = await _apiService.getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 POST $url');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur progression (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateProgress: $e');
      rethrow;
    }
  }

  // Compléter un défi
  Future<Challenge> completeChallenge(int challengeId, int userId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$challengeId/complete',
      ).replace(queryParameters: {'userId': userId.toString()});

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 POST $url');

      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur complétion (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return Challenge.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur completeChallenge: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES PARTICIPATIONS ====================

  // Récupérer une participation par ID
  Future<ChallengeParticipation> getParticipation(int participationId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/participations/$participationId',
      );

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        throw Exception('Participation non trouvée');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeParticipation.fromJson(
        jsonResponse as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getParticipation: $e');
      rethrow;
    }
  }

  // Récupérer les participations d'un défi
  Future<PagedResponse<ChallengeParticipation>> getChallengeParticipations(
    int challengeId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$challengeId/participations',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<ChallengeParticipation>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => ChallengeParticipation.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengeParticipations: $e');
      rethrow;
    }
  }

  // Récupérer les participations d'un utilisateur
  Future<PagedResponse<ChallengeParticipation>> getUserParticipations(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/participations',
      ).replace(queryParameters: queryParams);

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<ChallengeParticipation>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => ChallengeParticipation.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserParticipations: $e');
      rethrow;
    }
  }

  // Mettre à jour le statut d'une participation (admin)
  Future<ChallengeParticipation> updateParticipationStatus(
    int participationId,
    String status,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/participations/$participationId/status',
      ).replace(queryParameters: {'status': status});

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 PATCH $url');

      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur mise à jour statut (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeParticipation.fromJson(
        jsonResponse as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateParticipationStatus: $e');
      rethrow;
    }
  }

  // Récupérer le classement d'un défi
  Future<List<ChallengeParticipation>> getLeaderboard(
    int challengeId, {
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$challengeId/leaderboard',
      ).replace(queryParameters: {'limit': limit.toString()});

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonList = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return jsonList
          .map(
            (json) =>
                ChallengeParticipation.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getLeaderboard: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES UTILISATEUR ====================

  // Récupérer les défis d'un utilisateur
  Future<PagedResponse<Challenge>> getUserChallenges(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId',
      ).replace(queryParameters: queryParams);

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserChallenges: $e');
      rethrow;
    }
  }

  // Récupérer les défis actifs d'un utilisateur
  Future<PagedResponse<Challenge>> getUserActiveChallenges(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/active',
      ).replace(queryParameters: queryParams);

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserActiveChallenges: $e');
      rethrow;
    }
  }

  // Récupérer les défis complétés d'un utilisateur
  Future<PagedResponse<Challenge>> getUserCompletedChallenges(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/completed',
      ).replace(queryParameters: queryParams);

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Challenge>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Challenge.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserCompletedChallenges: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES COMPLETIONS ====================

  // Enregistrer une complétion
  Future<ChallengeCompletion> recordCompletion(
    int challengeId,
    int userId,
    ChallengeCompletionRequest request,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/challenge/$challengeId/user/$userId',
      );

      final headers = await _apiService.getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 POST $url');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur enregistrement complétion (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletion.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur recordCompletion: $e');
      rethrow;
    }
  }

  // Récupérer une complétion par ID
  Future<ChallengeCompletion> getCompletionById(int id) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_completionEndpoint/$id');

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        throw Exception('Complétion non trouvée');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletion.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getCompletionById: $e');
      rethrow;
    }
  }

  // Récupérer la complétion d'un utilisateur pour un défi
  Future<ChallengeCompletion> getCompletionByChallengeAndUser(
    int challengeId,
    int userId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/challenge/$challengeId/user/$userId',
      );

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        throw Exception('Complétion non trouvée');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletion.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getCompletionByChallengeAndUser: $e');
      rethrow;
    }
  }

  // Récupérer les complétions d'un utilisateur
  Future<PagedResponse<ChallengeCompletion>> getUserCompletions(
    int userId, {
    int page = 0,
    int size = 20,
    String sort = 'completedAt,desc',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/user/$userId',
      ).replace(queryParameters: queryParams);

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<ChallengeCompletion>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => ChallengeCompletion.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserCompletions: $e');
      rethrow;
    }
  }

  // Récupérer les complétions d'un défi
  Future<PagedResponse<ChallengeCompletion>> getChallengeCompletions(
    int challengeId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/challenge/$challengeId',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<ChallengeCompletion>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => ChallengeCompletion.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengeCompletions: $e');
      rethrow;
    }
  }

  // Récupérer les complétions publiques
  Future<PagedResponse<ChallengeCompletion>> getPublicCompletions({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/public',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<ChallengeCompletion>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => ChallengeCompletion.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getPublicCompletions: $e');
      rethrow;
    }
  }

  // Récupérer les jalons de complétion d'un utilisateur
  Future<List<ChallengeCompletion>> getMilestoneCompletions(int userId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/user/$userId/milestones',
      );

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonList = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return jsonList
          .map(
            (json) =>
                ChallengeCompletion.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getMilestoneCompletions: $e');
      rethrow;
    }
  }

  // Mettre à jour une complétion
  Future<ChallengeCompletion> updateCompletion(
    int id,
    ChallengeCompletionRequest request,
  ) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_completionEndpoint/$id');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 PUT $url');

      final response = await http
          .put(url, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur mise à jour (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletion.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateCompletion: $e');
      rethrow;
    }
  }

  // Supprimer une complétion
  Future<void> deleteCompletion(int id) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_completionEndpoint/$id');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 DELETE $url');

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur suppression (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur deleteCompletion: $e');
      rethrow;
    }
  }

  // Émettre un certificat pour une complétion
  Future<ChallengeCompletion> issueCertificate(int id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/$id/certificate',
      );

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 POST $url');

      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur certificat (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletion.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur issueCertificate: $e');
      rethrow;
    }
  }

  // Modifier la visibilité d'une complétion
  Future<ChallengeCompletion> toggleCompletionVisibility(
    int id,
    bool isPublic,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/$id/visibility',
      ).replace(queryParameters: {'isPublic': isPublic.toString()});

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 PATCH $url');

      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur changement visibilité (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletion.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur toggleCompletionVisibility: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES CATÉGORIES ====================

  // Récupérer toutes les catégories
  Future<PagedResponse<ChallengeCategory>> getAllCategories({
    int page = 0,
    int size = 20,
    String sort = 'sortOrder,asc',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_categoryEndpoint',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<ChallengeCategory>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => ChallengeCategory.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getAllCategories: $e');
      rethrow;
    }
  }

  // Récupérer les catégories actives
  Future<List<ChallengeCategory>> getActiveCategories() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_categoryEndpoint/active');

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonList = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return jsonList
          .map(
            (json) => ChallengeCategory.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getActiveCategories: $e');
      rethrow;
    }
  }

  // Récupérer une catégorie par ID
  Future<ChallengeCategory> getCategoryById(int id) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_categoryEndpoint/$id');

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        throw Exception('Catégorie non trouvée');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCategory.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getCategoryById: $e');
      rethrow;
    }
  }

  // Récupérer les catégories avec défis actifs
  Future<List<ChallengeCategory>> getCategoriesWithActiveChallenges() async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_categoryEndpoint/with-challenges',
      );

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonList = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return jsonList
          .map(
            (json) => ChallengeCategory.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getCategoriesWithActiveChallenges: $e');
      rethrow;
    }
  }

  // Récupérer les catégories avec nombre de défis
  Future<PagedResponse<ChallengeCategory>> getCategoriesWithChallengeCount({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_categoryEndpoint/with-count',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<ChallengeCategory>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => ChallengeCategory.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getCategoriesWithChallengeCount: $e');
      rethrow;
    }
  }

  // Rechercher des catégories
  Future<PagedResponse<ChallengeCategory>> searchCategories(
    String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'keyword': keyword,
        'page': page.toString(),
        'size': size.toString(),
      };

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_categoryEndpoint/search',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<ChallengeCategory>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => ChallengeCategory.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur searchCategories: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES ADMIN CATÉGORIES ====================

  // Créer une catégorie
  Future<ChallengeCategory> createCategory(
    ChallengeCategoryRequest request,
  ) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_categoryEndpoint');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 POST $url');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur création catégorie (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCategory.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur createCategory: $e');
      rethrow;
    }
  }

  // Mettre à jour une catégorie
  Future<ChallengeCategory> updateCategory(
    int id,
    ChallengeCategoryRequest request,
  ) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_categoryEndpoint/$id');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 PUT $url');

      final response = await http
          .put(url, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur mise à jour catégorie (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCategory.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateCategory: $e');
      rethrow;
    }
  }

  // Supprimer une catégorie
  Future<void> deleteCategory(int id) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_categoryEndpoint/$id');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 DELETE $url');

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur suppression catégorie (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur deleteCategory: $e');
      rethrow;
    }
  }

  // Activer/désactiver une catégorie
  Future<ChallengeCategory> toggleCategoryStatus(int id, bool active) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_categoryEndpoint/$id/status',
      ).replace(queryParameters: {'active': active.toString()});

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);

      if (kDebugMode) print('📤 PATCH $url');

      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur changement statut catégorie (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCategory.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur toggleCategoryStatus: $e');
      rethrow;
    }
  }

  // Mettre à jour l'ordre des catégories
  Future<void> updateCategoryOrder(List<int> categoryIds) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_categoryEndpoint/reorder');

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Utilisateur non connecté');

      final headers = await _apiService.getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) print('📤 POST $url');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(categoryIds))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur mise à jour ordre (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateCategoryOrder: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES STATISTIQUES ====================

  // Récupérer les statistiques globales des défis
  Future<ChallengeStatistics> getChallengeStatistics() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/statistics');

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeStatistics.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengeStatistics: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques d'un utilisateur
  Future<ChallengeStatistics> getUserChallengeStatistics(int userId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/statistics/user/$userId',
      );

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeStatistics.fromJson(jsonResponse as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserChallengeStatistics: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques des catégories
  Future<ChallengeCategoryStatistics> getCategoryStatistics() async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_categoryEndpoint/statistics',
      );

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCategoryStatistics.fromJson(
        jsonResponse as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getCategoryStatistics: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques de complétion d'un utilisateur
  Future<ChallengeCompletionStatistics> getUserCompletionStatistics(
    int userId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/statistics/user/$userId',
      );

      final headers = await _apiService.getHeadersWithUserId(userId);
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletionStatistics.fromJson(
        jsonResponse as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserCompletionStatistics: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques de complétion d'un défi
  Future<ChallengeCompletionStatistics> getChallengeCompletionStatistics(
    int challengeId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/statistics/challenge/$challengeId',
      );

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletionStatistics.fromJson(
        jsonResponse as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getChallengeCompletionStatistics: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques globales de complétion
  Future<ChallengeCompletionStatistics> getGlobalCompletionStatistics() async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_completionEndpoint/statistics/global',
      );

      final headers = await _getHeadersWithUserId();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur (${response.statusCode}): ${_parseErrorMessage(response)}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return ChallengeCompletionStatistics.fromJson(
        jsonResponse as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getGlobalCompletionStatistics: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES DE DÉBOGAGE ====================

  Future<void> debugUserId() async {
    if (!kDebugMode) return;

    print('=== DÉBOGAGE CHALLENGE USERID ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final authData = prefs.getString('auth_data');

      print('👤 UserId: $userId');
      print('🔐 Auth data présent: ${authData != null ? "OUI" : "NON"}');

      if (authData != null) {
        try {
          final data = jsonDecode(authData) as Map<String, dynamic>;
          print('👤 UserId dans auth_data: ${data['userId']}');
        } catch (e) {
          print('❌ Erreur parsing auth_data: $e');
        }
      }

      final headers = await _getHeadersWithUserId();
      print(
        '📤 Headers X-User-Id: ${headers.containsKey('X-User-Id') ? headers['X-User-Id'] : 'ABSENT'}',
      );
    } catch (e) {
      print('❌ Erreur debugUserId: $e');
    }
    print('=== FIN DÉBOGAGE ===');
  }

  void clearCache() {
    // Si vous avez des maps de cache, videz-les
    if (kDebugMode) print('🧹 ChallengeApiService cache cleared');
  }
}*/
