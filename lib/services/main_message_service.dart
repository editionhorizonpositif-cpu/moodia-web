// lib/services/main_message_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/main_message.dart';
import '../services/api_service.dart';

class MainMessageService {
  final ApiService _apiService;
  static const String baseUrl = "https://api.moodia.xyz/api";

  // Clés pour SharedPreferences
  static const String _cachedMessagesKey = 'main_messages_cache';
  static const String _cacheTimestampKey = 'main_messages_timestamp';

  // Cache en mémoire
  List<MainMessage>? _cachedMessages;
  DateTime? _lastCacheUpdate;

  // Durée de validité du cache (30 minutes)
  static const Duration cacheValidity = Duration(minutes: 30);

  MainMessageService(this._apiService) {
    // Charger le cache persistant au démarrage
    _loadCacheFromPrefs();
  }

  // ========== GESTION DU CACHE PERSISTANT ==========

  /// Sauvegarde les messages dans SharedPreferences
  Future<void> _persistCache(List<MainMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await prefs.setString(_cachedMessagesKey, jsonEncode(messagesJson));
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      if (kDebugMode) print('💾 Messages sauvegardés dans SharedPreferences');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sauvegarde cache: $e');
    }
  }

  /// Charge le cache depuis SharedPreferences
  Future<void> _loadCacheFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      final messagesJson = prefs.getString(_cachedMessagesKey);

      if (timestamp != null && messagesJson != null) {
        final List<dynamic> decoded = jsonDecode(messagesJson);
        _cachedMessages = decoded
            .map((json) => MainMessage.fromJson(json as Map<String, dynamic>))
            .toList();
        _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (kDebugMode) {
          print(
            '📦 Cache chargé depuis SharedPreferences (${_cachedMessages!.length} messages)',
          );
        }
      } else {
        if (kDebugMode) print('ℹ️ Aucun cache trouvé dans SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement cache: $e');
    }
  }

  // ========== GESTION DU CACHE MÉMOIRE ==========

  bool _isCacheValid() {
    if (_cachedMessages == null || _lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < cacheValidity;
  }

  void _updateCache(List<MainMessage> messages) {
    _cachedMessages = messages;
    _lastCacheUpdate = DateTime.now();
    // Sauvegarde persistante
    _persistCache(messages);
  }

  // ========== VÉRIFICATION DE LA CONNECTIVITÉ ==========

  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // ========== MÉTHODES PUBLIQUES ==========

  /// Récupère les messages utilisateur (selon audience) avec cache
  Future<UserMessagesResponse> getUserMessages({
    String audience = 'ALL',
    bool forceRefresh = false,
  }) async {
    log('🔄 getUserMessages - audience: $audience', name: 'MainMessageService');
    final hasInternet = await hasInternetConnection();

    if (forceRefresh && hasInternet) {
      return await _fetchUserMessages(audience);
    }

    if (hasInternet) {
      try {
        return await _fetchUserMessages(audience);
      } catch (e) {
        log(
          '⚠️ Échec backend, utilisation du cache',
          name: 'MainMessageService',
        );
        if (_isCacheValid()) {
          return UserMessagesResponse(
            audience: audience,
            total: _cachedMessages!.length,
            messages: _cachedMessages!,
          );
        }
        rethrow;
      }
    } else {
      log('📴 Hors-ligne - utilisation du cache', name: 'MainMessageService');
      if (_isCacheValid()) {
        return UserMessagesResponse(
          audience: audience,
          total: _cachedMessages!.length,
          messages: _cachedMessages!,
        );
      }
      throw Exception('📴 Mode hors-ligne: Aucune donnée en cache disponible');
    }
  }

  /// Récupère les messages actifs (sans pagination)
  Future<List<MainMessage>> getActiveMessages() async {
    log('🔄 getActiveMessages', name: 'MainMessageService');
    final hasInternet = await hasInternetConnection();

    if (hasInternet) {
      try {
        final url = Uri.parse(_buildUrl('v1/messages/active'));
        final headers = await _apiService.getHeaders();
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List<dynamic>;
          final messages = data
              .map((item) => MainMessage.fromJson(item))
              .toList();
          _updateCache(messages);
          return messages;
        }
        if (response.statusCode == 204) {
          _updateCache([]);
          return [];
        }
        throw Exception('Erreur ${response.statusCode}');
      } catch (e) {
        log('❌ Erreur getActiveMessages: $e', name: 'MainMessageService');
        if (_isCacheValid()) {
          return _cachedMessages!.where((msg) => msg.isActive == true).toList();
        }
        rethrow;
      }
    } else {
      if (_isCacheValid()) {
        return _cachedMessages!.where((msg) => msg.isActive == true).toList();
      }
      throw Exception('📴 Mode hors-ligne: Aucune donnée en cache');
    }
  }

  /// Récupère tous les messages (paginés)
  Future<PaginatedResponse<MainMessage>> getAllMessages({
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
    bool forceRefresh = false,
  }) async {
    final hasInternet = await hasInternetConnection();

    if (!hasInternet && page == 0 && _isCacheValid() && !forceRefresh) {
      return PaginatedResponse<MainMessage>(
        content: _cachedMessages!,
        totalElements: _cachedMessages!.length,
        totalPages: 1,
        size: size,
        number: 0,
        first: true,
        last: true,
        numberOfElements: _cachedMessages!.length,
        empty: _cachedMessages!.isEmpty,
      );
    }

    if (!hasInternet) {
      throw Exception('Mode hors-ligne: Données non disponibles');
    }

    try {
      final url = Uri.parse(_buildUrl('v1/messages')).replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          'sort': sort,
        },
      );
      final headers = await _apiService.getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = PaginatedResponse<MainMessage>.fromJson(
          data,
          (json) => MainMessage.fromJson(json),
        );
        if (page == 0) _updateCache(result.content);
        return result;
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      log('❌ Erreur getAllMessages: $e', name: 'MainMessageService');
      rethrow;
    }
  }

  // ========== MÉTHODES PRIVÉES ==========

  Future<UserMessagesResponse> _fetchUserMessages(String audience) async {
    try {
      final url = Uri.parse(_buildUrl('v1/messages/user?audience=$audience'));
      final headers = await _apiService.getHeaders();
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = UserMessagesResponse.fromJson(data);
        _updateCache(result.messages);
        return result;
      }
      if (response.statusCode == 204) {
        _updateCache([]);
        return UserMessagesResponse(audience: audience, total: 0, messages: []);
      }
      throw Exception('Erreur ${response.statusCode}');
    } on TimeoutException {
      throw Exception('Délai d\'attente dépassé');
    } catch (e) {
      log('❌ Erreur _fetchUserMessages: $e', name: 'MainMessageService');
      rethrow;
    }
  }

  String _buildUrl(String endpoint) {
    if (endpoint.startsWith('/')) endpoint = endpoint.substring(1);
    return '$baseUrl/$endpoint';
  }

  /// Vider le cache (mémoire et persistant)
  Future<void> clearCache() async {
    _cachedMessages = null;
    _lastCacheUpdate = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedMessagesKey);
      await prefs.remove(_cacheTimestampKey);
      log(
        '🧹 Cache (mémoire + SharedPreferences) vidé',
        name: 'MainMessageService',
      );
    } catch (e) {
      log('❌ Erreur clearCache: $e', name: 'MainMessageService');
    }
  }
}

// ========== CLASSE PAGINATEDRESPONSE (inchangée) ==========
class PaginatedResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final int numberOfElements;
  final bool empty;

  PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.numberOfElements,
    required this.empty,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return PaginatedResponse<T>(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJson(item))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      size: json['size'] as int,
      number: json['number'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
      numberOfElements: json['numberOfElements'] as int,
      empty: json['empty'] as bool,
    );
  }
}
