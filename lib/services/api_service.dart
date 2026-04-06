// lib/services/api_service.dart - SANS TIMEOUTS (attend la réponse du backend)
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/quote.dart';
import '../models/numerology_profile.dart';
import '../models/meditation.dart';
import '../models/habit.dart';
import '../models/notification.dart';
import '../models/challenge.dart';
import '../models/main_message.dart';
import '../models/auth_dtos.dart';
import '../routes/route.dart';

class ApiService {
  // ⚠️ URL de production
  static const String baseUrl = "https://api.moodia.xyz/api";

  // URL de développement (commentée pour référence)
  //static const String baseUrl = "http://localhost:8080/api";

  // ⚠️ PLUS AUCUN TIMEOUT - Le frontend attendra indéfiniment

  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Cache pour le token
  String? _cachedToken;
  DateTime? _tokenExpiry;

  // Storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Client HTTP
  //final http.Client _httpClient = http.Client();
  http.Client _httpClient = http.Client();
  bool _isClientHealthy = true;

  // ApiService.dart - à ajouter dans la classe
  static GlobalKey<NavigatorState>? navigatorKey;
  static VoidCallback? onSessionExpired;

  // Initialiser les préférences
  Future<void> _initPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  // Réinitialiser le client HTTP en cas de problème
  Future<void> _resetHttpClient() async {
    try {
      _httpClient.close(); // pas d'await
    } catch (e) {}
    _httpClient = http.Client();
    _isClientHealthy = true;
  }

  // Récupération du token
  Future<String?> _getToken() async {
    if (kDebugMode) {
      print('=== DEBUT _getToken() ===');
    }

    // Si cache valide
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now())) {
      if (kDebugMode) {
        print('✅ Token depuis cache (valide jusqu\'à ${_tokenExpiry})');
      }
      return _cachedToken;
    }

    await _initPrefs();

    String? token;

    try {
      // 1. Essayer SecureStorage
      token = await _secureStorage.read(key: 'jwt_token');
      if (kDebugMode && token != null) {
        print('🔐 Token SecureStorage: ${token.length} chars');
      }

      // 2. Si SecureStorage vide, essayer SharedPreferences
      if (token == null || token.isEmpty || token.length < 10) {
        token = _prefs!.getString('jwt_token');
        if (kDebugMode && token != null) {
          print('📱 Token SharedPreferences: ${token.length} chars');
        }

        // Si on a un token depuis SharedPreferences, le migrer vers SecureStorage
        if (token != null && token.isNotEmpty && token.length > 10) {
          await _secureStorage.write(key: 'jwt_token', value: token);
          if (kDebugMode) {
            print('🔄 Token migré vers SecureStorage');
          }
        }
      }

      // 3. Vérifier auth_data
      if (token == null || token.isEmpty || token.length < 10) {
        final authData = _prefs!.getString('auth_data');
        if (authData != null) {
          try {
            final data = jsonDecode(authData) as Map<String, dynamic>;
            token = data['token'] as String?;

            if (token != null && token.isNotEmpty && token.length > 10) {
              // Sauvegarder dans les deux storages
              await _secureStorage.write(key: 'jwt_token', value: token);
              await _prefs!.setString('jwt_token', token);

              if (kDebugMode) {
                print('📄 Token extrait de auth_data: ${token.length} chars');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Erreur parsing auth_data: $e');
            }
          }
        }
      }

      // VÉRIFICATION CRITIQUE DU TOKEN
      if (token != null) {
        if (token.length < 10) {
          if (kDebugMode) {
            print('⚠️ Token trop court: ${token.length} chars - Éliminé');
          }
          token = null;

          await _secureStorage.delete(key: 'jwt_token');
          await _prefs!.remove('jwt_token');
          await _prefs!.remove('auth_data');
        } else {
          _cachedToken = token;
          _tokenExpiry = DateTime.now().add(const Duration(hours: 4));

          if (kDebugMode) {
            print('✅ Token validé et mis en cache');
            print('   Longueur: ${token.length} chars');
            print('   Début: ${token.substring(0, min(30, token.length))}...');
            print('   Cache valide jusqu\'à: $_tokenExpiry');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Aucun token valide trouvé');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _getToken(): $e');
      }
      token = null;
    }

    if (kDebugMode) {
      print('=== FIN _getToken() ===');
      print('Token final: ${token != null ? "${token.length} chars" : "NULL"}');
    }

    return token;
  }

  // Méthode publique pour obtenir le token JWT
  Future<String?> getToken() async {
    return await _getToken();
  }

  // Méthode publique pour obtenir les headers avec authentification
  Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    return await _getHeaders(includeAuth: includeAuth);
  }

  // Vérifier la connexion au serveur
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Pas de connexion au serveur: $e');
      }
      return false;
    }
  }

  // Méthode publique pour obtenir les headers avec userId
  Future<Map<String, String>> getHeadersWithUserId(int userId) async {
    final headers = await _getHeaders();
    headers['X-User-Id'] = userId.toString();
    return headers;
  }

  // Debug complet de l'état d'authentification
  Future<void> debugAuth() async {
    if (!kDebugMode) return;

    print('=== DÉBOGAGE AUTH COMPLET ===');

    try {
      await _initPrefs();

      // 1. Vérifier SecureStorage
      final secureToken = await _secureStorage.read(key: 'jwt_token');
      print(
        '🔐 SecureStorage - jwt_token: ${secureToken != null ? "PRÉSENT" : "ABSENT"}',
      );
      if (secureToken != null) {
        print('   Longueur: ${secureToken.length}');
        print(
          '   Début: ${secureToken.substring(0, min(30, secureToken.length))}...',
        );
      }

      // 2. Vérifier SharedPreferences
      final prefToken = _prefs!.getString('jwt_token');
      print(
        '📱 SharedPreferences - jwt_token: ${prefToken != null ? "PRÉSENT" : "ABSENT"}',
      );

      final authData = _prefs!.getString('auth_data');
      print(
        '📱 SharedPreferences - auth_data: ${authData != null ? "PRÉSENT" : "ABSENT"}',
      );
      if (authData != null) {
        try {
          final data = jsonDecode(authData) as Map<String, dynamic>;
          print(
            '   Token dans auth_data: ${data['token'] != null ? "PRÉSENT" : "ABSENT"}',
          );
          print('   UserId: ${data['userId']}');
          print('   Email: ${data['email']}');
        } catch (e) {
          print('   Erreur parsing auth_data: $e');
        }
      }

      final userId = _prefs!.getInt('userId');
      print('📱 SharedPreferences - userId: $userId');

      final isLoggedIn = _prefs!.getBool('is_logged_in');
      print('📱 SharedPreferences - is_logged_in: $isLoggedIn');

      // 3. Vérifier le cache
      print(
        '💾 Token en cache: ${_cachedToken != null ? "PRÉSENT" : "ABSENT"}',
      );
      print('💾 Token expire: $_tokenExpiry');
      if (_cachedToken != null && _tokenExpiry != null) {
        print('💾 Token valide: ${_tokenExpiry!.isAfter(DateTime.now())}');
      }
    } catch (e) {
      print('❌ Erreur débogage: $e');
    }
  }

  // Rafraîchir le token depuis auth_data
  Future<bool> refreshToken() async {
    try {
      await _initPrefs();

      final authData = _prefs!.getString('auth_data');
      if (authData == null || authData.isEmpty) {
        return false;
      }

      final data = jsonDecode(authData) as Map<String, dynamic>;
      final token = data['token'] as String?;

      if (token == null || token.isEmpty) {
        return false;
      }

      await _secureStorage.write(key: 'jwt_token', value: token);
      await _prefs!.setString('jwt_token', token);

      _cachedToken = token;
      _tokenExpiry = DateTime.now().add(const Duration(hours: 4));

      if (kDebugMode) {
        print('🔄 Token rafraîchi avec succès');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur rafraîchissement token: $e');
      }
      return false;
    }
  }

  // Valider et obtenir le token
  Future<void> _validateToken() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('❌ Token non disponible, tentative de rafraîchissement...');
        }

        final refreshed = await refreshToken();
        if (!refreshed) {
          if (kDebugMode) {
            print('❌ Impossible de rafraîchir le token');
          }
          throw Exception('Token non disponible. Veuillez vous reconnecter.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur validation token: $e');
      }
      rethrow;
    }
  }

  // Initialisation du service
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔧 Initialisation ApiService...');
      print('🌐 URL de base: $baseUrl');
    }

    await _initPrefs();
    await debugAuth();

    try {
      await _validateToken();
      if (kDebugMode) {
        print('✅ ApiService initialisé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ ApiService initialisé sans token valide');
      }
    }
  }

  // Effacer le cache du token
  Future<void> _clearTokenCache() async {
    _cachedToken = null;
    _tokenExpiry = null;

    try {
      await _secureStorage.delete(key: 'jwt_token');
      await _initPrefs();
      await _prefs!.remove('jwt_token');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur nettoyage cache token: $e');
      }
    }
  }

  // Sauvegarder le token après une connexion réussie
  Future<void> saveToken(String token) async {
    try {
      if (kDebugMode) {
        print(
          '💾 Sauvegarde du token: ${token.substring(0, min(30, token.length))}...',
        );
      }

      await _secureStorage.write(key: 'jwt_token', value: token);
      await _initPrefs();
      await _prefs!.setString('jwt_token', token);

      _cachedToken = token;
      _tokenExpiry = DateTime.now().add(const Duration(hours: 4));

      if (kDebugMode) {
        print('✅ Token sauvegardé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sauvegarde token: $e');
      }
      rethrow;
    }
  }

  // Obtenir les headers avec authentification
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = Map<String, String>.from(_defaultHeaders);

    if (kDebugMode) {
      print('🔄 DEBUT _getHeaders(includeAuth: $includeAuth)');
    }

    if (includeAuth) {
      try {
        final token = await _getToken();

        if (token != null && token.isNotEmpty && token.length > 10) {
          headers['Authorization'] = 'Bearer $token';

          if (kDebugMode) {
            print('🔐 Token AJOUTÉ aux headers');
            print('   Longueur: ${token.length}');
            print('   Début: ${token.substring(0, min(30, token.length))}...');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Pas de token valide - headers SANS auth');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur récupération token pour headers: $e');
        }
      }
    }

    if (kDebugMode) {
      print(
        '📤 Headers finaux: ${headers.keys.map((k) => '$k: ${k == 'Authorization' ? '[BEARER TOKEN]' : headers[k]}').toList()}',
      );
      print('🔄 FIN _getHeaders');
    }

    return headers;
  }

  // Parser les messages d'erreur
  String _parseErrorMessage(http.Response response) {
    try {
      final jsonBody = jsonDecode(response.body);
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ??
            jsonBody['error'] ??
            'Unknown error occurred';
      }
      return 'Server error: ${response.statusCode}';
    } catch (e) {
      return 'Server error: ${response.statusCode}';
    }
  }

  // Gestion des réponses
  Future<http.Response> _handleResponse(http.Response response) async {
    if (kDebugMode) {
      print(
        '📥 Réponse ${response.statusCode} pour ${response.request?.url.path}',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      if (kDebugMode) print('❌ Token invalide/expiré (${response.statusCode})');

      // 1. Nettoyer le token local
      await _clearTokenCache();

      // 2. Déclencher le callback global s'il existe
      onSessionExpired?.call();

      // 3. Rediriger vers login via le navigatorKey
      if (navigatorKey?.currentContext != null) {
        Future.microtask(() {
          navigatorKey!.currentState!.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        });
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: response.statusCode == 401
            ? 'Session expirée. Veuillez vous reconnecter.'
            : 'Accès non autorisé.',
        body: response.body,
        requiresLogout: true,
      );
    }

    if (response.statusCode >= 400) {
      final errorMsg = _parseErrorMessage(response);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMsg,
        body: response.body,
      );
    }

    return response;
  }

  // Méthode safeRequest SANS TIMEOUT
  Future<http.Response> safeRequest({
    required String method,
    required String path,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final requestHeaders = await getHeaders(includeAuth: true);

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    if (!_isClientHealthy) {
      if (kDebugMode) {
        print('⚠️ Client HTTP en cours de réinitialisation, attente...');
      }
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    try {
      late http.Response response;

      if (kDebugMode) {
        print('🌐 $method $path');
      }

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await _httpClient.post(
            url,
            headers: requestHeaders,
            body: body,
          );
          break;
        case 'PUT':
          response = await _httpClient.put(
            url,
            headers: requestHeaders,
            body: body,
          );
          break;
        case 'DELETE':
          response = await _httpClient.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Méthode non supportée: $method');
      }

      if (kDebugMode) {
        print('📥 Réponse $method $path: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur $method $path: $e');
      }
      rethrow;
    }
  }

  // Méthodes génériques pour les requêtes

  Future<List<T>> _getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final stopwatch = Stopwatch()..start();

    if (kDebugMode) {
      print('🚀 DEBUT _getList pour: $endpoint');
    }

    try {
      final response = await safeRequest(method: 'GET', path: '/$endpoint');

      stopwatch.stop();

      if (kDebugMode) {
        print('✅ Réponse reçue pour $endpoint');
        print('📥 Status: ${response.statusCode}');
        print('📦 Taille: ${response.body.length} chars');
        print('⏱️ Temps HTTP: ${stopwatch.elapsedMilliseconds}ms');
      }

      if (response.statusCode >= 400) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Erreur ${response.statusCode}',
        );
      }

      final parsingStopwatch = Stopwatch()..start();
      final utf8Body = utf8.decode(response.bodyBytes);
      final jsonList = json.decode(utf8Body) as List<dynamic>;
      parsingStopwatch.stop();

      if (kDebugMode) {
        print('✅ Parsing terminé en ${parsingStopwatch.elapsedMilliseconds}ms');
        print('✅ $endpoint: ${jsonList.length} items');
        print('⏱️ Temps total: ${stopwatch.elapsedMilliseconds}ms');
      }

      return jsonList.map((json) => fromJson(json)).toList();
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        print('❌ Erreur dans _getList($endpoint)');
        print('⏱️ Temps écoulé: ${stopwatch.elapsedMilliseconds}ms');
      }
      rethrow;
    }
  }

  Future<T> _getItem<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    await _validateToken();

    try {
      final response = await safeRequest(method: 'GET', path: '/$endpoint');

      final handledResponse = await _handleResponse(response);
      final decodedBody = jsonDecode(utf8.decode(handledResponse.bodyBytes));
      return fromJson(decodedBody);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _getItem $endpoint: $e');
      }
      rethrow;
    }
  }

  Future<T> _addItem<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    await _validateToken();

    try {
      final response = await safeRequest(
        method: 'POST',
        path: '/$endpoint',
        body: jsonEncode(body),
      );

      final handledResponse = await _handleResponse(response);
      return fromJson(jsonDecode(utf8.decode(handledResponse.bodyBytes)));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _addItem $endpoint: $e');
      }
      rethrow;
    }
  }

  Future<T> _updateItem<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    await _validateToken();

    try {
      final response = await safeRequest(
        method: 'PUT',
        path: '/$endpoint',
        body: jsonEncode(body),
      );

      final handledResponse = await _handleResponse(response);
      return fromJson(jsonDecode(utf8.decode(handledResponse.bodyBytes)));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _updateItem $endpoint: $e');
      }
      rethrow;
    }
  }

  Future<void> _deleteItem(String endpoint) async {
    await _validateToken();

    try {
      final response = await safeRequest(method: 'DELETE', path: '/$endpoint');

      await _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _deleteItem $endpoint: $e');
      }
      rethrow;
    }
  }

  // ========== MÉTHODES PUBLIQUES ==========

  // Endpoints d'authentification (sans auth)
  Future<dynamic> register(SignupRequest request) async {
    final url = Uri.parse('$baseUrl/users/register');
    final headers = await _getHeaders(includeAuth: false);

    if (kDebugMode) {
      print('📤 POST $url (register)');
    }

    final response = await _httpClient.post(
      url,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    final handledResponse = await _handleResponse(response);
    final responseData = jsonDecode(handledResponse.body);

    // L'utilisateur est créé, on ignore l'erreur d'email
    if (kDebugMode) {
      print('✅ Inscription réussie pour: ${request.email}');
    }

    return responseData;
  }

  Future<dynamic> login(LoginRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (kDebugMode) {
        print('🚀 DEBUT ApiService.login()');
        print('📧 Email: ${request.email}');
      }

      final url = Uri.parse('$baseUrl/users/login');
      final headers = await _getHeaders(includeAuth: false);
      final body = jsonEncode(request.toJson());

      if (kDebugMode) {
        print('🌐 Envoi requête POST...');
      }

      final response = await _httpClient.post(
        url,
        headers: headers,
        body: body,
      );
      // ⚠️ SUPPRIME .timeout(longTimeout)

      if (kDebugMode) {
        print('✅ Réponse HTTP reçue');
        print('⏱️ Temps: ${stopwatch.elapsedMilliseconds}ms');
        print('📥 Status: ${response.statusCode}');
      }

      final handledResponse = await _handleResponse(response);
      final responseData = jsonDecode(handledResponse.body);

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('token')) {
        final token = responseData['token'] as String;
        await saveToken(token);
      }

      stopwatch.stop();

      return responseData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERREUR dans ApiService.login(): $e');
      }
      rethrow;
    }
  }

  Future<dynamic> verifyEmail(EmailVerificationRequest request) async {
    final url = Uri.parse('$baseUrl/users/verify-email');
    final headers = await _getHeaders(includeAuth: false);

    final response = await _httpClient.post(
      url,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );
    // ⚠️ SUPPRIME .timeout(timeout)

    final handledResponse = await _handleResponse(response);
    return jsonDecode(handledResponse.body);
  }

  Future<dynamic> verifyEmailViaLink(String token) async {
    final url = Uri.parse('$baseUrl/users/verify-email/link?token=$token');
    final headers = await _getHeaders(includeAuth: false);

    final response = await _httpClient.get(url, headers: headers);
    // ⚠️ SUPPRIME .timeout(timeout)

    final handledResponse = await _handleResponse(response);
    return jsonDecode(handledResponse.body);
  }

  Future<void> resendVerification(String email) async {
    final url = Uri.parse('$baseUrl/users/resend-verification');
    final headers = await _getHeaders(includeAuth: false);

    final response = await _httpClient.post(
      url,
      headers: headers,
      body: jsonEncode({'email': email}),
    );
    // ⚠️ SUPPRIME .timeout(timeout)

    await _handleResponse(response);
  }

  Future<void> requestPasswordReset(String email) async {
    final url = Uri.parse('$baseUrl/users/password-reset/request');
    final headers = await _getHeaders(includeAuth: false);

    final response = await _httpClient.post(
      url,
      headers: headers,
      body: jsonEncode({'email': email}),
    );
    // ⚠️ SUPPRIME .timeout(timeout)

    await _handleResponse(response);
  }

  Future<void> resetPassword(PasswordResetRequest request) async {
    final url = Uri.parse('$baseUrl/users/password-reset/confirm');
    final headers = await _getHeaders(includeAuth: false);

    final response = await _httpClient.post(
      url,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );
    // ⚠️ SUPPRIME .timeout(timeout)

    await _handleResponse(response);
  }

  // Endpoints utilisateur (avec auth)
  Future<User> getCurrentUser() async {
    try {
      await _validateToken();

      final url = Uri.parse('$baseUrl/users/me');
      final headers = await _getHeaders();

      if (kDebugMode) {
        print('📤 GET $url (getCurrentUser)');
      }

      final response = await _httpClient.get(url, headers: headers);
      // ⚠️ SUPPRIME .timeout(shortTimeout)

      final handledResponse = await _handleResponse(response);
      final decodedBody = jsonDecode(utf8.decode(handledResponse.bodyBytes));
      return User.fromJson(decodedBody);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur dans getCurrentUser: $e');
      }
      rethrow;
    }
  }

  Future<User> updateUser(UserUpdateRequest request) async {
    return await _updateItem<User>(
      'users/me',
      request.toJson(),
      (json) => User.fromJson(json),
    );
  }

  Future<void> changePassword(PasswordChangeRequest request) async {
    final url = Uri.parse('$baseUrl/users/me/password');
    final headers = await _getHeaders();

    final response = await _httpClient.put(
      url,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );
    // ⚠️ SUPPRIME .timeout(timeout)

    await _handleResponse(response);
  }

  Future<void> requestAccountDeletion() async {
    final url = Uri.parse('$baseUrl/users/me/deletion-request');
    final headers = await _getHeaders();

    final response = await _httpClient.post(url, headers: headers);
    // ⚠️ SUPPRIME .timeout(timeout)

    await _handleResponse(response);
  }

  Future<void> cancelAccountDeletion() async {
    final url = Uri.parse('$baseUrl/users/me/deletion-request');
    final headers = await _getHeaders();

    final response = await _httpClient.delete(url, headers: headers);
    // ⚠️ SUPPRIME .timeout(timeout)

    await _handleResponse(response);
  }

  Future<void> requestDataExport() async {
    final url = Uri.parse('$baseUrl/users/me/data-export');
    final headers = await _getHeaders();

    final response = await _httpClient.post(url, headers: headers);
    // ⚠️ SUPPRIME .timeout(timeout)

    await _handleResponse(response);
  }

  Future<bool> checkEmailVerified() async {
    final response = await _getItem<Map<String, dynamic>>(
      'users/me/email-verified',
      (json) => json,
    );
    return response['emailVerified'] ?? false;
  }

  // Autres méthodes GET
  Future<List<Quote>> getQuotes() async =>
      await _getList<Quote>('quote', (json) => Quote.fromJson(json));

  Future<PaginatedResponse<MainMessage>> getMainMessagesPaginated({
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    try {
      final response = await safeRequest(
        method: 'GET',
        path: '/api/v1/messages?page=$page&size=$size&sort=$sort',
      );

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return PaginatedResponse<MainMessage>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => MainMessage.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getMainMessagesPaginated: $e');
      }
      rethrow;
    }
  }

  Future<UserMessagesResponse> getUserMessages({
    String audience = 'ALL',
  }) async {
    try {
      final response = await safeRequest(
        method: 'GET',
        path: '/api/v1/messages/user?audience=$audience',
      );

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return UserMessagesResponse.fromJson(
        jsonResponse as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getUserMessages: $e');
      }
      rethrow;
    }
  }

  Future<List<Challenge>> getChallenges() async => await _getList<Challenge>(
    'challenge',
    (json) => Challenge.fromJson(json),
  );

  Future<List<Challenge>> getChallengesByVibration(int? vibration) async =>
      await _getList<Challenge>(
        'challenge/by-vibration/$vibration',
        (json) => Challenge.fromJson(json),
      );

  Future<NumerologyProfile> getNumerologyProfileByUserId(int? userId) async =>
      await _getItem<NumerologyProfile>(
        'numerology/numerology-profile/$userId',
        (json) => NumerologyProfile.fromJzon(json),
      );

  Future<List<Habit>> getHabits() async =>
      await _getList<Habit>('habit', (json) => Habit.fromJson(json));

  Future<List<Habit>> getHabitsByUser(int? userId) async =>
      await _getList<Habit>(
        'habit/by_user/$userId',
        (json) => Habit.fromJson(json),
      );

  Future<Habit> getHabitId(int id) async =>
      await _getItem<Habit>('habit/$id', (json) => Habit.fromJson(json));

  Future<List<Meditation>> getMeditations({
    int page = 0,
    int size = 20,
    String sort = 'displayOrder,asc',
  }) async {
    try {
      final response = await safeRequest(
        method: 'GET',
        path: '/meditations?page=$page&size=$size&sort=$sort',
      );

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse.containsKey('content')) {
        final content = jsonResponse['content'] as List<dynamic>;
        return content
            .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (jsonResponse is List) {
        return jsonResponse
            .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération méditations: $e');
      }
      rethrow;
    }
  }

  Future<Meditation> getMeditationId(int id) async =>
      await _getItem<Meditation>(
        'meditation/$id',
        (json) => Meditation.fromJson(json),
      );

  Future<List<NotificationModel>> getNotificationsByUser(int userId) async =>
      await _getList<NotificationModel>(
        'notifications/by-user/$userId',
        (json) => NotificationModel.fromJson(json),
      );

  Future<NotificationModel> getNotificationById(int id) async =>
      await _getItem<NotificationModel>(
        'notifications/$id',
        (json) => NotificationModel.fromJson(json),
      );

  // Méthodes POST
  Future<Quote> addQuote(Quote quote) async {
    final body = {
      'text': quote.text,
      'author': quote.author,
      'category': quote.category,
    };
    return await _addItem<Quote>(
      'quote/create-new-quote',
      body,
      (json) => Quote.fromJson(json),
    );
  }

  Future<Habit> addHabit(Habit habit) async {
    final body = {
      'userId': habit.userId,
      'name': habit.name,
      'frequency': habit.frequency,
      'goalCount': habit.goalCount,
    };
    return await _addItem<Habit>(
      'habit/create-new-habit',
      body,
      (json) => Habit.fromJson(json),
    );
  }

  Future<NumerologyProfile> getUserNumerologyProfile(int userId) async {
    try {
      return await _getItem<NumerologyProfile>(
        'numerology/numerology-profile/$userId',
        (json) => NumerologyProfile.fromJzon(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération profil numérologique: $e');
      }
      rethrow;
    }
  }

  Future<NumerologyProfile> saveNumerologyProfile(
    NumerologyProfile profile,
  ) async {
    try {
      return await _addItem<NumerologyProfile>(
        'numerology/save-profile',
        profile.toJzon(),
        (json) => NumerologyProfile.fromJzon(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sauvegarde profil numérologique: $e');
      }
      rethrow;
    }
  }

  // Méthodes PUT
  Future<Quote> updateQuote(Quote quote) async => await _updateItem<Quote>(
    'quotes/update-quote/${quote.id}',
    quote.toJson(),
    (json) => Quote.fromJson(json),
  );

  Future<Habit> updateHabit(Habit habit) async {
    return await _updateItem<Habit>(
      'habit/update/${habit.id}',
      habit.toJson(),
      (json) => Habit.fromJson(json),
    );
  }

  Future<void> markNotificationAsRead(int id) async {
    final url = Uri.parse('$baseUrl/notifications/$id/read');
    final headers = await _getHeaders();

    final response = await _httpClient.put(url, headers: headers);
    // ⚠️ SUPPRIME .timeout(timeout)

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await _clearTokenCache();
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception(
        'Erreur ${response.statusCode}: Impossible de marquer la notification comme lue',
      );
    }
  }

  // Méthodes DELETE
  Future<void> deleteQuote(int id) async =>
      await _deleteItem('quotes/delete-quote/$id');

  Future<void> deleteJournalEntry(int id) async =>
      await _deleteItem('journalEntry/delete-journalEntry/$id');

  Future<void> deleteHabit(int id) async =>
      await _deleteItem('habit/delete-habit/$id');

  Future<void> deleteNotification(int id) async =>
      await _deleteItem('notifications/delete-notification/$id');

  // Déconnexion
  Future<void> logout() async {
    await _clearTokenCache();
    await _initPrefs();
    await _prefs!.remove('auth_data');
    await _prefs!.remove('is_logged_in');
    await _prefs!.remove('userId');
    _cachedToken = null;
    _tokenExpiry = null;

    await _resetHttpClient(); // ← recrée un client opérationnel

    if (kDebugMode) print('👋 Déconnexion complète');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;
  final bool requiresLogout;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.body,
    this.requiresLogout = false,
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, requiresLogout: $requiresLogout)';
}
