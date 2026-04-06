// lib/services/auth_service.dart - Version COMPLÈTE CORRIGÉE
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../models/user.dart';
import '../models/auth_dtos.dart';
import 'api_service.dart';
import 'user_cache_service.dart';
import '../routes/route.dart';
import '../services/notification_cache_service.dart';
import '../services/journal_api_service.dart';
import '../services/emotion_api_service.dart';
import '../providers/subscription_provider.dart';

class AuthService with ChangeNotifier {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'current_user';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _offlineCredentialsKey = 'offline_credentials';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final SharedPreferences _prefs;
  final ApiService _apiService;
  final UserCacheService _userCache = UserCacheService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _authError;
  String? _authToken;

  // Constructeur privé
  AuthService._(this._apiService);

  // Factory method pour l'initialisation asynchrone
  static Future<AuthService> create(ApiService apiService) async {
    final instance = AuthService._(apiService);
    await instance._initialize();
    return instance;
  }

  // Méthode pour créer avec SharedPreferences (pour compatibilité)
  factory AuthService(SharedPreferences prefs, ApiService apiService) {
    final instance = AuthService._(apiService);
    instance._prefs = prefs;
    return instance;
  }

  // Initialisation asynchrone
  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get authError => _authError;
  String? get authToken => _authToken;
  bool get canWorkOffline => _currentUser != null;

  /// ⭐ RESTAURER L'UTILISATEUR DEPUIS LE CACHE
  void setUserFromCache(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    _isLoading = false;

    // Récupérer le token depuis SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      _authToken = prefs.getString('jwt_token');
      notifyListeners();
    });

    if (kDebugMode) {
      debugPrint('✅ Utilisateur restauré depuis cache: ${user.email}');
    }
    notifyListeners();
  }

  /// Initialise le service - TOUJOURS charger le cache en priorité
  //@override
  Future<void> initialize() async {
    setLoading(true);

    if (kDebugMode) {
      print('=== DEBUT AuthService.initialize() ===');
    }

    try {
      // Étape 1: Vérifier le cache utilisateur permanent
      final cachedUser = await _userCache.loadCachedUser();

      if (cachedUser != null) {
        // Utilisateur trouvé en cache - connexion automatique
        _currentUser = cachedUser;
        _isAuthenticated = true;

        // Charger le token depuis le stockage
        _authToken = await _secureStorage.read(key: _tokenKey);

        if (kDebugMode) {
          print('✅ Connexion automatique depuis cache: ${cachedUser.email}');
          print('   - Premium: ${cachedUser.isPremium}');
          print('   - Token présent: ${_authToken != null}');
        }

        // Tenter une validation en arrière-plan (optionnel)
        _validateTokenInBackground();
      } else {
        if (kDebugMode) {
          print('ℹ️ Aucun utilisateur en cache');
        }
        _isAuthenticated = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur critique dans initialize(): $e');
      }
      _isAuthenticated = false;
    } finally {
      setLoading(false);
      notifyListeners();

      if (kDebugMode) {
        print('=== ÉTAT FINAL AuthService ===');
        print('✅ Authentifié: $_isAuthenticated');
        print(
          '✅ Utilisateur: ${_currentUser != null ? _currentUser!.email : "ABSENT"}',
        );
        print('============================\n');
      }
    }
  }

  /// Validation du token en arrière-plan (ne bloque pas)
  Future<void> _validateTokenInBackground() async {
    try {
      if (_authToken != null && _authToken!.isNotEmpty) {
        final user = await _apiService.getCurrentUser().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Hors-ligne'),
        );

        // Mettre à jour si différent
        if (user != _currentUser) {
          _currentUser = user;
          await _userCache.cacheUser(user);
          notifyListeners();

          if (kDebugMode) {
            print('✅ Données utilisateur mises à jour depuis serveur');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ℹ️ Mode hors-ligne - utilisation des données en cache');
      }
      // Pas d'erreur, on garde le cache
    }
  }

  /// ✅ Rafraîchir les données utilisateur depuis le serveur
  Future<void> refreshUserData() async {
    if (!_isAuthenticated) return;

    setLoading(true);
    try {
      if (kDebugMode) {
        print('🔄 Rafraîchissement des données utilisateur...');
      }

      final user = await _apiService.getCurrentUser();
      _currentUser = user;

      // Mettre à jour le stockage
      await _prefs.setString(_userKey, jsonEncode(user.toJson()));
      await _userCache.cacheUser(user);

      // Mettre à jour auth_data
      final authDataJson = _prefs.getString('auth_data');
      if (authDataJson != null) {
        try {
          final authData = jsonDecode(authDataJson) as Map<String, dynamic>;
          authData['premium'] = user.isPremium;
          authData['emailVerified'] = user.emailVerified;
          authData['fullName'] = user.fullName;
          await _prefs.setString('auth_data', jsonEncode(authData));
        } catch (e) {
          if (kDebugMode) print('❌ Erreur mise à jour auth_data: $e');
        }
      }

      // Mettre à jour les flags individuels
      await _prefs.setBool('user_premium', user.isPremium);

      if (kDebugMode) {
        print('✅ Données utilisateur rafraîchies avec succès');
        print('   - Email: ${user.email}');
        print('   - Premium: ${user.isPremium}');
        print('   - Streak: ${user.currentStreakDays} jours');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur rafraîchissement données utilisateur: $e');
      }
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// ✅ MÉTHODE PRINCIPALE: Connexion avec support hors-ligne
  Future<bool> login(LoginRequest request, {bool rememberMe = true}) async {
    setLoading(true);
    clearError();

    try {
      if (kDebugMode) {
        print('🔐 Tentative de connexion pour: ${request.email}');
      }

      // 1. TENTER LA CONNEXION EN LIGNE D'ABORD
      try {
        final response = await _apiService.login(request);
        final authResponse = AuthResponse.fromJson(response);

        // Succès - sauvegarder TOUT de façon permanente
        await _saveAuthData(authResponse);
        await _userCache.cacheUser(authResponse.user);

        // Sauvegarder les identifiants pour le hors-ligne (si demandé)
        if (rememberMe) {
          await _saveOfflineCredentials(request.email, request.password);
        }

        if (kDebugMode) {
          print('✅ Connexion en ligne réussie');
        }

        notifyListeners();
        return true;
      } catch (e) {
        // 2. ÉCHEC DE LA CONNEXION EN LIGNE - Tenter le mode hors-ligne
        if (kDebugMode) {
          print('⚠️ Connexion en ligne échouée, tentative hors-ligne...');
        }

        // Vérifier si on a des identifiants en cache
        final offlineSuccess = await _attemptOfflineLogin(request);

        if (offlineSuccess) {
          if (kDebugMode) {
            print('✅ Connexion hors-ligne réussie');
          }
          notifyListeners();
          return true;
        }

        // 3. ÉCHEC TOTAL
        throw Exception('Identifiants incorrects ou serveur inaccessible');
      }
    } catch (e) {
      _authError = _getErrorMessage(e);
      if (kDebugMode) print('❌ Échec connexion: $e');
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Tentative de connexion hors-ligne
  Future<bool> _attemptOfflineLogin(LoginRequest request) async {
    try {
      // 1. Vérifier si on a des identifiants en cache
      final credentials = await _getOfflineCredentials();

      if (credentials == null) {
        if (kDebugMode) print('ℹ️ Aucun identifiant en cache');
        return false;
      }

      // 2. Vérifier que l'email correspond
      if (credentials['email'] != request.email) {
        if (kDebugMode) print('ℹ️ Email différent du cache');
        return false;
      }

      // 3. Vérifier le mot de passe
      // NOTE: En production, utilisez un hash sécurisé comme bcrypt
      if (credentials['password'] != request.password) {
        if (kDebugMode) print('ℹ️ Mot de passe incorrect');
        return false;
      }

      // 4. Charger l'utilisateur depuis le cache
      final cachedUser = await _userCache.loadCachedUser();
      if (cachedUser == null) return false;

      // 5. Restaurer la session
      _currentUser = cachedUser;
      _isAuthenticated = true;

      // Récupérer le token s'il existe
      _authToken = await _secureStorage.read(key: _tokenKey);

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur offline login: $e');
      return false;
    }
  }

  /// Sauvegarder les identifiants pour le hors-ligne
  Future<void> _saveOfflineCredentials(String email, String password) async {
    try {
      // ⚠️ ATTENTION: En production, il faut hasher le mot de passe !
      // Utilisez bcrypt: https://pub.dev/packages/bcrypt
      final credentials = {
        'email': email,
        'password': password, // En prod: hash(password)
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _secureStorage.write(
        key: _offlineCredentialsKey,
        value: jsonEncode(credentials),
      );

      if (kDebugMode) {
        print('✅ Identifiants sauvegardés pour mode hors-ligne');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sauvegarde credentials: $e');
    }
  }

  /// Récupérer les identifiants hors-ligne
  Future<Map<String, String>?> _getOfflineCredentials() async {
    try {
      final credentialsJson = await _secureStorage.read(
        key: _offlineCredentialsKey,
      );
      if (credentialsJson == null) return null;

      return Map<String, String>.from(jsonDecode(credentialsJson));
    } catch (e) {
      return null;
    }
  }

  /// Effacer les identifiants hors-ligne
  Future<void> _clearOfflineCredentials() async {
    await _secureStorage.delete(key: _offlineCredentialsKey);
  }

  /// Sauvegarde des données d'authentification
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    try {
      // Mettre à jour les données locales
      _currentUser = authResponse.user;
      _authToken = authResponse.token;
      _isAuthenticated = true;

      // Sauvegarder le token
      await _secureStorage.write(key: _tokenKey, value: authResponse.token);
      await _prefs.setString('jwt_token', authResponse.token);

      // Sauvegarder l'userId dans SecureStorage
      await _secureStorage.write(
        key: _userIdKey,
        value: authResponse.userId.toString(),
      );

      // Sauvegarder l'utilisateur dans SharedPreferences
      await _prefs.setString(_userKey, jsonEncode(authResponse.user.toJson()));

      // Sauvegarder dans auth_data
      final authData = {
        'token': authResponse.token,
        'userId': authResponse.userId,
        'email': authResponse.user.email,
        'fullName': authResponse.user.fullName,
        'username': authResponse.user.username,
        'roles': authResponse.user.roles.toList(),
        'premium': authResponse.user.isPremium,
        'emailVerified': authResponse.user.emailVerified,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 4))
            .toIso8601String(),
      };
      await _prefs.setString('auth_data', jsonEncode(authData));

      // Marquer comme connecté
      await _prefs.setBool('is_logged_in', true);
      await _prefs.setInt('userId', authResponse.userId);
      await _prefs.setBool('user_premium', authResponse.user.isPremium);

      if (kDebugMode) {
        print('=== DONNÉES SAUVEGARDÉES ===');
        print('✅ Premium: ${authResponse.user.isPremium}');
        print('✅ UserId: ${authResponse.userId}');
        print('✅ Email: ${authResponse.user.email}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur _saveAuthData: $e');
      rethrow;
    }
  }

  /// Nettoyage des données
  Future<void> _clearAuthData() async {
    try {
      // Effacer d'abord le token local
      _authToken = null;

      // Nettoyer SecureStorage
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userIdKey);

      // Nettoyer SharedPreferences
      await _prefs.remove(_userKey);
      await _prefs.remove(_rememberMeKey);
      await _prefs.remove('jwt_token');
      await _prefs.remove('auth_data');
      await _prefs.remove('is_logged_in');
      await _prefs.remove('userId');

      if (kDebugMode) print('✅ Données d\'authentification effacées');
    } catch (e) {
      if (kDebugMode) print('❌ Error clearing auth data: $e');
    }
  }

  /// Gestion des erreurs
  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 401) return 'Email ou mot de passe incorrect';
      if (error.statusCode == 403) return 'Compte non vérifié';
      if (error.statusCode == 0)
        return 'Mode hors-ligne: Identifiants incorrects';
      return 'Erreur serveur: ${error.statusCode}';
    } else if (error is TimeoutException) {
      return 'Délai d\'attente dépassé. Vérifiez votre connexion.';
    }
    return 'Erreur de connexion: ${error.toString()}';
  }

  /// Déconnexion
  // Dans AuthService
  Future<void> logout() async {
    setLoading(true);
    try {
      // Tentative de déconnexion côté serveur (optionnelle)
      try {
        await _apiService.logout();
      } catch (e) {
        if (kDebugMode) print('⚠️ Erreur logout serveur (ignorée) : $e');
      }

      // Nettoyage local FORCÉ
      await _clearAuthData();
      await _userCache.clearCache();
      await _clearOfflineCredentials();

      _currentUser = null;
      _isAuthenticated = false;
      _authToken = null;
      _authError = null;

      notifyListeners();
      if (kDebugMode) print('👋 Déconnexion locale réussie');
    } catch (e) {
      if (kDebugMode) print('❌ Logout error: $e');
      rethrow;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Inscription
  Future<bool> register(SignupRequest request) async {
    setLoading(true);
    clearError();

    try {
      final response = await _apiService.register(request);
      final authResponse = AuthResponse.fromJson(response);

      await _saveAuthData(authResponse);
      await _userCache.cacheUser(authResponse.user);

      notifyListeners();

      if (kDebugMode)
        print('🎉 Inscription réussie pour: ${authResponse.user.email}');
      return true;
    } on ApiException catch (e) {
      _authError = e.message;
      return false;
    } catch (e) {
      _authError = 'Registration failed: ${e.toString()}';
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// ✅ Vérification d'email (avec code)
  Future<bool> verifyEmail(EmailVerificationRequest request) async {
    setLoading(true);
    clearError();

    try {
      final response = await _apiService.verifyEmail(request);
      final authResponse = AuthResponse.fromJson(response);

      await _saveAuthData(authResponse);
      await _userCache.cacheUser(authResponse.user);

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _authError = e.message;
      return false;
    } catch (e) {
      _authError = 'Email verification failed: ${e.toString()}';
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// ✅ Vérification d'email via lien
  Future<bool> verifyEmailViaLink(String token) async {
    setLoading(true);
    clearError();

    try {
      final response = await _apiService.verifyEmailViaLink(token);
      final authResponse = AuthResponse.fromJson(response);

      await _saveAuthData(authResponse);
      await _userCache.cacheUser(authResponse.user);

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _authError = e.message;
      return false;
    } catch (e) {
      _authError = 'Email verification failed: ${e.toString()}';
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// ✅ Renvoyer le code de vérification
  Future<void> resendVerification(String email) async {
    setLoading(true);
    clearError();

    try {
      await _apiService.resendVerification(email);
    } on ApiException catch (e) {
      _authError = e.message;
      rethrow;
    } catch (e) {
      _authError = 'Failed to resend verification: ${e.toString()}';
      rethrow;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// ✅ Demande de réinitialisation de mot de passe
  Future<void> requestPasswordReset(String email) async {
    setLoading(true);
    clearError();

    try {
      await _apiService.requestPasswordReset(email);
    } on ApiException catch (e) {
      _authError = e.message;
      rethrow;
    } catch (e) {
      _authError = 'Password reset request failed: ${e.toString()}';
      rethrow;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// ✅ RÉINITIALISATION DE MOT DE PASSE
  Future<void> resetPassword(PasswordResetRequest request) async {
    setLoading(true);
    clearError();

    try {
      await _apiService.resetPassword(request);
    } on ApiException catch (e) {
      _authError = e.message;
      rethrow;
    } catch (e) {
      _authError = 'Password reset failed: ${e.toString()}';
      rethrow;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Synchroniser le statut premium
  Future<void> syncPremiumStatus(bool isPremium) async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(isPremium: isPremium);
      _currentUser = updatedUser;

      await _prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      await _userCache.updatePremiumStatus(isPremium);

      final authDataJson = _prefs.getString('auth_data');
      if (authDataJson != null) {
        try {
          final authData = jsonDecode(authDataJson) as Map<String, dynamic>;
          authData['premium'] = isPremium;
          await _prefs.setString('auth_data', jsonEncode(authData));
        } catch (e) {
          print('❌ Erreur mise à jour auth_data: $e');
        }
      }

      await _prefs.setBool('user_premium', isPremium);
      notifyListeners();

      if (kDebugMode)
        print('✅ Premium status synced in AuthService: $isPremium');
    }
  }

  /// Vérifier l'état d'authentification
  bool isExplicitlyAuthenticated() {
    return _isAuthenticated && _currentUser != null;
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile(UserUpdateRequest request) async {
    setLoading(true);
    clearError();

    try {
      final updatedUser = await _apiService.updateUser(request);
      _currentUser = updatedUser;

      await _prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
      await _userCache.cacheUser(updatedUser);

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _authError = e.message;
      return false;
    } catch (e) {
      _authError = 'Profile update failed: ${e.toString()}';
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Changer le mot de passe
  Future<bool> changePassword(PasswordChangeRequest request) async {
    setLoading(true);
    clearError();

    try {
      await _apiService.changePassword(request);
      return true;
    } on ApiException catch (e) {
      _authError = e.message;
      return false;
    } catch (e) {
      _authError = 'Password change failed: ${e.toString()}';
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Vérifier si l'email est vérifié
  Future<bool> checkEmailVerified() async {
    try {
      return await _apiService.checkEmailVerified();
    } catch (e) {
      if (kDebugMode) print('❌ Check email verified error: $e');
      return false;
    }
  }

  /// Méthodes utilitaires
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _authError = null;
    notifyListeners();
  }

  bool get isRememberMeEnabled {
    return _prefs.getBool(_rememberMeKey) ?? false;
  }

  Future<void> setRememberMe(bool remember) async {
    await _prefs.setBool(_rememberMeKey, remember);
    notifyListeners();
  }

  Future<String?> getToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return _authToken;
    }
    try {
      _authToken = await _secureStorage.read(key: _tokenKey);
      return _authToken;
    } catch (e) {
      return null;
    }
  }

  /// Vérifier l'état d'authentification (pour débogage)
  Future<void> debugAuthStatus() async {
    if (!kDebugMode) return;

    print('=== ÉTAT AUTH SERVICE ===');
    print('Authentifié: $_isAuthenticated');
    print('Token présent: ${_authToken != null && _authToken!.isNotEmpty}');
    print('Utilisateur présent: ${_currentUser != null}');
    if (_currentUser != null) {
      print('Email: ${_currentUser!.email}');
      print('ID: ${_currentUser!.id}');
    }
    print('is_logged_in: ${_prefs.getBool('is_logged_in')}');
    print('userId dans prefs: ${_prefs.getInt('userId')}');
    print('=======================');
  }

  // auth_service.dart
  Future<void> forceLogoutAndRedirect(BuildContext context) async {
    // 1. Annuler tous les timers (si nécessaire)
    // 2. Nettoyer les données d’auth
    await _clearAuthData(); // token, user_data, prefs
    await _userCache.clearCache(); // cache utilisateur
    await _clearOfflineCredentials(); // identifiants sauvegardés

    // 3. Supprimer les flags temporaires
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_verification_email');

    // 4. Déconnexion côté serveur (optionnelle, on ignore l’erreur)
    try {
      await _apiService.logout();
    } catch (_) {}

    // 5. Redirection vers login avec effacement complet de l’historique
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false, // supprime toutes les routes précédentes
      );
    }
  }
}

// Extension pour compatibilité
extension AuthServiceExtension on AuthService {
  static Future<AuthService> createWithPrefs(ApiService apiService) async {
    final prefs = await SharedPreferences.getInstance();
    return AuthService(prefs, apiService);
  }
}
