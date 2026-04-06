// lib/services/numerology_api_service.dart - Version corrigée

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/numerology_profile.dart';
import '../models/numerology_message.dart';
import 'api_service.dart';

class NumerologyApiService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'numerology';
  static const String _messageEndpoint = 'numerologyMessage';

  // Cache sophistiqué
  static final Map<String, CacheEntry<NumerologyProfile>> _profileCache = {};
  static const Duration _cacheDuration = Duration(minutes: 15);

  // Rate limiting
  static final Map<String, DateTime> _lastRequest = {};
  static const Duration _rateLimitDelay = Duration(milliseconds: 500);

  NumerologyApiService(this._apiService);

  // ========== GESTION DU CACHE ==========

  void _cacheProfile(int userId, NumerologyProfile profile) {
    _profileCache[userId.toString()] = CacheEntry(
      data: profile,
      timestamp: DateTime.now(),
      ttl: _cacheDuration,
    );
    if (kDebugMode) {
      print('💾 Profil $userId mis en cache');
    }
  }

  NumerologyProfile? _getCachedProfile(int userId) {
    final entry = _profileCache[userId.toString()];
    if (entry != null && !entry.isExpired) {
      if (kDebugMode) {
        print('📦 Cache HIT pour userId: $userId');
      }
      return entry.data;
    }
    return null;
  }

  void _invalidateCache(int userId) {
    _profileCache.remove(userId.toString());
  }

  Future<void> _applyRateLimit(String key) async {
    final last = _lastRequest[key];
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < _rateLimitDelay) {
        await Future.delayed(_rateLimitDelay - elapsed);
      }
    }
    _lastRequest[key] = DateTime.now();
  }

  // ========== HEADERS AVEC USER ID ==========

  Future<Map<String, String>> _getHeadersWithUserId([int? userId]) async {
    try {
      if (userId != null) {
        return await _apiService.getHeadersWithUserId(userId);
      }

      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getInt('userId');

      if (savedUserId != null) {
        return await _apiService.getHeadersWithUserId(savedUserId);
      }

      return await _apiService.getHeaders();
    } catch (e) {
      return await _apiService.getHeaders();
    }
  }

  // ========== PROFIL NUMÉROLOGIQUE ==========

  /// Génère un nouveau profil numérologique
  Future<NumerologyProfile> generateProfile({
    required int userId,
    required DateTime birthDate,
    required String fullName,
    bool bypassCache = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (kDebugMode) {
        print('🌟 GÉNÉRATION PROFIL - userId: $userId');
      }

      await _applyRateLimit('generate_$userId');

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/generate');
      final headers = await _getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({
        'userId': userId,
        'birthDate': birthDate.toIso8601String().split('T')[0],
        'fullName': fullName.trim(),
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final profile = NumerologyProfile.fromJzon(jsonResponse);
        _cacheProfile(userId, profile);
        return profile;
      }

      if (response.statusCode == 409) {
        throw NumerologyException.conflict('Un profil existe déjà');
      }

      if (response.statusCode == 400) {
        throw NumerologyException.validation(_parseErrorMessage(response));
      }

      throw NumerologyException.server(
        'Erreur génération profil (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw NumerologyException.timeout(
        'Le serveur met trop de temps à répondre',
      );
    } catch (e) {
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  Future<List<NumerologyMessage>> fetchNumerologyMessages() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_messageEndpoint');
      final headers = await _apiService.getHeaders();

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return jsonList
            .map((json) => NumerologyMessage.fromJson(json))
            .toList();
      } else {
        throw NumerologyException.server(
          'Erreur chargement messages (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur fetchNumerologyMessages: $e');
      }
      rethrow;
    }
  }

  /// Récupère le profil numérologique d'un utilisateur
  /// Retourne null si le profil n'existe pas (404)
  /// Lance une exception pour les autres erreurs (500, etc.)
  Future<NumerologyProfile?> getProfileByUserId(
    int userId, {
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (kDebugMode) {
        print('🔍 RECHERCHE PROFIL - userId: $userId');
      }

      // Vérifier le cache si pas de force refresh
      if (!forceRefresh) {
        final cached = _getCachedProfile(userId);
        if (cached != null) {
          return cached;
        }
      }

      await _applyRateLimit('get_$userId');

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/numerology-profile/$userId',
      );
      final headers = await _getHeadersWithUserId(userId);

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
        print('⏱️ Temps: ${stopwatch.elapsedMilliseconds}ms');
      }

      // === GESTION DU 404 ===
      if (response.statusCode == 404) {
        if (kDebugMode) {
          print('📭 Profil non trouvé (404) - Retourne null');
        }
        return null;
      }

      // === GESTION DU SUCCÈS ===
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final profile = NumerologyProfile.fromJzon(jsonResponse);
        _cacheProfile(userId, profile);
        return profile;
      }

      // === GESTION DES AUTRES ERREURS (500, etc.) ===
      if (kDebugMode) {
        print(
          '❌ Erreur serveur ${response.statusCode} - Body: ${response.body}',
        );
      }

      throw NumerologyException.server(
        'Erreur serveur (${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    } on TimeoutException {
      throw NumerologyException.timeout('Délai de réponse dépassé');
    } catch (e) {
      if (e is NumerologyException) rethrow;
      throw NumerologyException.unknown('Erreur inattendue: $e');
    } finally {
      stopwatch.stop();
    }
  }

  /// Met à jour un profil existant
  Future<NumerologyProfile> updateProfile({
    required int profileId,
    required int userId,
    required DateTime birthDate,
    required String fullName,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 MISE À JOUR PROFIL - id: $profileId, userId: $userId');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/update-profile/$profileId',
      );
      final headers = await _getHeadersWithUserId(userId);
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({
        'userId': userId,
        'birthDate': birthDate.toIso8601String().split('T')[0],
        'fullName': fullName.trim(),
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final profile = NumerologyProfile.fromJzon(jsonResponse);
        _invalidateCache(userId);
        _cacheProfile(userId, profile);
        return profile;
      }

      throw NumerologyException.server(
        'Erreur mise à jour profil (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour profil: $e');
      }
      rethrow;
    }
  }

  /// Vérifie si un profil existe
  Future<bool> hasProfile(int userId) async {
    try {
      final profile = await getProfileByUserId(userId);
      return profile != null;
    } on NumerologyException catch (e) {
      if (e.type == NumerologyExceptionType.notFound) {
        return false;
      }
      rethrow;
    }
  }

  /// Nettoie le cache
  void clearCache([int? userId]) {
    if (userId != null) {
      _invalidateCache(userId);
    } else {
      _profileCache.clear();
      if (kDebugMode) {
        print('🧹 Cache complet nettoyé');
      }
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ??
            jsonBody['error'] ??
            jsonBody['detail'] ??
            'Erreur inconnue';
      }
      return response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
    } catch (e) {
      return 'Erreur ${response.statusCode}';
    }
  }
}

// ========== EXCEPTIONS PERSONNALISÉES ==========

enum NumerologyExceptionType {
  notFound,
  conflict,
  validation,
  server,
  timeout,
  network,
  unknown,
}

class NumerologyException implements Exception {
  final String message;
  final NumerologyExceptionType type;
  final int? statusCode;
  final String? body;
  final dynamic originalError;

  NumerologyException(
    this.message, {
    this.type = NumerologyExceptionType.unknown,
    this.statusCode,
    this.body,
    this.originalError,
  });

  factory NumerologyException.notFound(String message) {
    return NumerologyException(message, type: NumerologyExceptionType.notFound);
  }

  factory NumerologyException.conflict(String message) {
    return NumerologyException(message, type: NumerologyExceptionType.conflict);
  }

  factory NumerologyException.validation(String message) {
    return NumerologyException(
      message,
      type: NumerologyExceptionType.validation,
    );
  }

  factory NumerologyException.server(
    String message, {
    int? statusCode,
    String? body,
  }) {
    return NumerologyException(
      message,
      type: NumerologyExceptionType.server,
      statusCode: statusCode,
      body: body,
    );
  }

  factory NumerologyException.timeout(String message) {
    return NumerologyException(message, type: NumerologyExceptionType.timeout);
  }

  factory NumerologyException.network(String message) {
    return NumerologyException(message, type: NumerologyExceptionType.network);
  }

  factory NumerologyException.unknown(String message, {dynamic error}) {
    return NumerologyException(
      message,
      type: NumerologyExceptionType.unknown,
      originalError: error,
    );
  }

  @override
  String toString() {
    return 'NumerologyException($type): $message${statusCode != null ? ' [$statusCode]' : ''}';
  }
}

// ========== ENTRÉE DE CACHE ==========

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({required this.data, required this.timestamp, required this.ttl});

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}
