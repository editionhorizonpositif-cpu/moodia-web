// user_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user.dart';
import '../models/auth_dtos.dart';
import 'api_service.dart';
import 'auth_service.dart';

class UserService with ChangeNotifier {
  late AuthService _authService;
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  static const String _userCacheKey = 'user_cache';
  static const String _lastUpdateKey = 'last_cache_update';

  UserService(AuthService authService) : _authService = authService {
    _initialize();
  }

  // Getters
  User? get currentUser => _currentUser ?? _authService.currentUser;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  // Méthode pour mettre à jour l'AuthService
  void updateAuthService(AuthService authService) {
    _authService = authService;
    _initialize();
  }

  Future<void> _initialize() async {
    // Écouter les changements d'authentification
    _authService.addListener(() {
      if (_authService.isAuthenticated) {
        // Synchroniser l'utilisateur avec AuthService
        _currentUser = _authService.currentUser;
        notifyListeners();
      } else {
        // Déconnexion
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// Charger le profil utilisateur
  Future<void> loadProfile() async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté pour voir votre profil';
      notifyListeners();
      return;
    }

    setLoading(true);

    try {
      // Essayer d'abord le cache
      if (await _isCacheValid()) {
        final cachedUser = await _loadFromCache();
        if (cachedUser != null) {
          _currentUser = cachedUser;
          setLoading(false);
          notifyListeners();
          return;
        }
      }

      // Charger depuis l'API
      await _loadFromApi();

      // Mettre à jour le cache
      await _updateCache();

      _error = null;
    } catch (e) {
      _error = 'Erreur chargement profil: $e';
      if (kDebugMode) {
        print('❌ Load profile error: $e');
      }
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Rafraîchir le profil utilisateur
  Future<void> refreshProfile() async {
    if (_isRefreshing) return;

    setRefreshing(true);

    try {
      await _clearCache();
      await _loadFromApi();
      await _updateCache();

      _error = null;
    } catch (e) {
      _error = 'Erreur rafraîchissement profil: $e';
      if (kDebugMode) {
        print('❌ Refresh profile error: $e');
      }
    } finally {
      setRefreshing(false);
      notifyListeners();
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<bool> updateProfile(UserUpdateRequest request) async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté pour mettre à jour votre profil';
      return false;
    }

    setLoading(true);

    try {
      final success = await _authService.updateProfile(request);

      if (success) {
        _currentUser = _authService.currentUser;
        await _updateCache();
        _error = null;
        return true;
      }

      return false;
    } catch (e) {
      _error = 'Erreur mise à jour profil: $e';
      if (kDebugMode) {
        print('❌ Update profile error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Mettre à jour la date de naissance
  Future<bool> updateBirthDate(DateTime birthDate) async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté';
      return false;
    }

    setLoading(true);

    try {
      final request = UserUpdateRequest(
        firstName: _currentUser?.firstName,
        lastName: _currentUser?.lastName,
        email: _currentUser?.email,
        phoneNumber: _currentUser?.phoneNumber,
        birthDate: birthDate.toIso8601String(),
        gender: _currentUser?.gender,
        bio: _currentUser?.bio,
        timezone: _currentUser?.timezone,
        locale: _currentUser?.locale,
        dailyGoal: _currentUser?.dailyGoal,
        weeklyGoal: _currentUser?.weeklyGoal,
        notificationEnabled: _currentUser?.notificationEnabled,
        pushNotificationEnabled: _currentUser?.pushNotificationEnabled,
        marketingConsent: _currentUser?.marketingConsent,
        profilePictureUrl: _currentUser?.profilePictureUrl,
        websiteUrl: _currentUser?.websiteUrl,
      );

      final success = await updateProfile(request);

      if (success) {
        _showSuccess('Date de naissance mise à jour avec succès');
      }

      return success;
    } catch (e) {
      _error = 'Erreur mise à jour date de naissance: $e';
      if (kDebugMode) {
        print('❌ Update birth date error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Mettre à jour le numéro de téléphone
  Future<bool> updatePhoneNumber(String phoneNumber) async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté';
      return false;
    }

    setLoading(true);

    try {
      final request = UserUpdateRequest(
        firstName: _currentUser?.firstName,
        lastName: _currentUser?.lastName,
        email: _currentUser?.email,
        phoneNumber: phoneNumber,
        birthDate: _currentUser?.birthDate?.toIso8601String(),
        gender: _currentUser?.gender,
        bio: _currentUser?.bio,
        timezone: _currentUser?.timezone,
        locale: _currentUser?.locale,
        dailyGoal: _currentUser?.dailyGoal,
        weeklyGoal: _currentUser?.weeklyGoal,
        notificationEnabled: _currentUser?.notificationEnabled,
        pushNotificationEnabled: _currentUser?.pushNotificationEnabled,
        marketingConsent: _currentUser?.marketingConsent,
        profilePictureUrl: _currentUser?.profilePictureUrl,
        websiteUrl: _currentUser?.websiteUrl,
      );

      final success = await updateProfile(request);

      if (success) {
        _showSuccess('Numéro de téléphone mis à jour avec succès');
      }

      return success;
    } catch (e) {
      _error = 'Erreur mise à jour numéro de téléphone: $e';
      if (kDebugMode) {
        print('❌ Update phone number error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Mettre à jour le fuseau horaire
  Future<bool> updateTimezone(String timezone) async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté';
      return false;
    }

    setLoading(true);

    try {
      final request = UserUpdateRequest(
        firstName: _currentUser?.firstName,
        lastName: _currentUser?.lastName,
        email: _currentUser?.email,
        phoneNumber: _currentUser?.phoneNumber,
        birthDate: _currentUser?.birthDate?.toIso8601String(),
        gender: _currentUser?.gender,
        bio: _currentUser?.bio,
        timezone: timezone,
        locale: _currentUser?.locale,
        dailyGoal: _currentUser?.dailyGoal,
        weeklyGoal: _currentUser?.weeklyGoal,
        notificationEnabled: _currentUser?.notificationEnabled,
        pushNotificationEnabled: _currentUser?.pushNotificationEnabled,
        marketingConsent: _currentUser?.marketingConsent,
        profilePictureUrl: _currentUser?.profilePictureUrl,
        websiteUrl: _currentUser?.websiteUrl,
      );

      final success = await updateProfile(request);

      if (success) {
        _showSuccess('Fuseau horaire mis à jour avec succès');
      }

      return success;
    } catch (e) {
      _error = 'Erreur mise à jour fuseau horaire: $e';
      if (kDebugMode) {
        print('❌ Update timezone error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Mettre à jour les préférences de notification
  Future<bool> updateNotificationPreferences({
    bool? notificationEnabled,
    bool? pushNotificationEnabled,
    String? emailNotificationFrequency,
  }) async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté';
      return false;
    }

    setLoading(true);

    try {
      final request = UserUpdateRequest(
        firstName: _currentUser?.firstName,
        lastName: _currentUser?.lastName,
        email: _currentUser?.email,
        phoneNumber: _currentUser?.phoneNumber,
        birthDate: _currentUser?.birthDate?.toIso8601String(),
        gender: _currentUser?.gender,
        bio: _currentUser?.bio,
        timezone: _currentUser?.timezone,
        locale: _currentUser?.locale,
        dailyGoal: _currentUser?.dailyGoal,
        weeklyGoal: _currentUser?.weeklyGoal,
        notificationEnabled:
            notificationEnabled ?? _currentUser?.notificationEnabled,
        pushNotificationEnabled:
            pushNotificationEnabled ?? _currentUser?.pushNotificationEnabled,
        emailNotificationFrequency:
            emailNotificationFrequency ??
            _currentUser?.emailNotificationFrequency,
        marketingConsent: _currentUser?.marketingConsent,
        profilePictureUrl: _currentUser?.profilePictureUrl,
        websiteUrl: _currentUser?.websiteUrl,
      );

      final success = await updateProfile(request);

      if (success) {
        _showSuccess('Préférences de notification mises à jour');
      }

      return success;
    } catch (e) {
      _error = 'Erreur mise à jour préférences notification: $e';
      if (kDebugMode) {
        print('❌ Update notification preferences error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Mettre à jour le mode sombre
  Future<bool> updateDarkMode(bool darkMode) async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté';
      return false;
    }

    setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', darkMode);

      _showSuccess(darkMode ? 'Mode sombre activé' : 'Mode sombre désactivé');
      return true;
    } catch (e) {
      _error = 'Erreur mise à jour mode sombre: $e';
      if (kDebugMode) {
        print('❌ Update dark mode error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Changer le mot de passe
  Future<bool> changePassword(PasswordChangeRequest request) async {
    return await _authService.changePassword(request);
  }

  /// Demander la suppression de compte
  Future<bool> requestAccountDeletion() async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté';
      return false;
    }

    setLoading(true);

    try {
      await _apiService.requestAccountDeletion();

      // Mettre à jour l'état local de l'utilisateur
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(accountDeletionRequested: true);
        await _updateCache();
        notifyListeners();
      }

      _showSuccess('Demande de suppression de compte envoyée');
      return true;
    } catch (e) {
      _error = 'Erreur demande suppression compte: $e';
      if (kDebugMode) {
        print('❌ Request account deletion error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Annuler la demande de suppression de compte
  Future<bool> cancelAccountDeletion() async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté';
      return false;
    }

    setLoading(true);

    try {
      await _apiService.cancelAccountDeletion();

      // Mettre à jour l'état local de l'utilisateur
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(accountDeletionRequested: false);
        await _updateCache();
        notifyListeners();
      }

      _showSuccess('Demande de suppression de compte annulée');
      return true;
    } catch (e) {
      _error = 'Erreur annulation suppression compte: $e';
      if (kDebugMode) {
        print('❌ Cancel account deletion error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Exporter les données utilisateur
  Future<bool> requestDataExport() async {
    if (!_authService.isAuthenticated) {
      _error = 'Vous devez être connecté';
      return false;
    }

    setLoading(true);

    try {
      await _apiService.requestDataExport();

      // Mettre à jour l'état local de l'utilisateur
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(dataExportRequested: true);
        await _updateCache();
        notifyListeners();
      }

      _showSuccess('Demande d\'export de données envoyée');
      return true;
    } catch (e) {
      _error = 'Erreur demande export données: $e';
      if (kDebugMode) {
        print('❌ Request data export error: $e');
      }
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  /// Charger depuis l'API
  Future<void> _loadFromApi() async {
    try {
      if (kDebugMode) {
        print('📡 Chargement utilisateur depuis API...');
      }

      _currentUser = await _apiService.getCurrentUser();

      if (kDebugMode) {
        print('✅ Profil chargé depuis API: ${_currentUser?.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Load from API error: $e');
      }
      rethrow;
    }
  }

  /// Charger depuis le cache
  Future<User?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_userCacheKey);

      if (cacheString == null) return null;

      final cache = jsonDecode(cacheString);
      final user = User.fromJson(cache);

      if (kDebugMode) {
        print('💾 Utilisateur chargé depuis cache: ${user.email}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Load from cache error: $e');
      }
      await _clearCache();
      return null;
    }
  }

  /// Mettre à jour le cache
  Future<void> _updateCache() async {
    if (_currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCacheKey, jsonEncode(_currentUser!.toJson()));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());

      if (kDebugMode) {
        print('💾 Cache utilisateur mis à jour');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Update cache error: $e');
      }
    }
  }

  /// Vérifier si le cache est valide
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateString = prefs.getString(_lastUpdateKey);

      if (lastUpdateString == null) return false;

      final lastUpdate = DateTime.tryParse(lastUpdateString);
      if (lastUpdate == null) return false;

      final now = DateTime.now();
      final age = now.difference(lastUpdate);

      // Cache valide pendant 5 minutes
      return age.inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  /// Effacer le cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
      await prefs.remove(_lastUpdateKey);

      if (kDebugMode) {
        print('🧹 Cache utilisateur effacé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Clear cache error: $e');
      }
    }
  }

  /// Méthodes d'état
  void setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) {
      _isRefreshing = false;
    }
    notifyListeners();
  }

  void setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Afficher un message de succès
  void _showSuccess(String message) {
    if (kDebugMode) {
      print('✅ Success: $message');
    }
    // Vous pourriez émettre un événement ou utiliser un callback ici
  }

  /// Méthodes utilitaires
  String get userInitials => currentUser?.initials ?? 'U';
  String get userName => currentUser?.displayName ?? 'Utilisateur';
  String get userEmail => currentUser?.email ?? '';
  bool get isPremium => currentUser?.isPremium ?? false;
  bool get emailVerified => currentUser?.emailVerified ?? false;
  DateTime? get memberSince => currentUser?.createdAt;
  Set<String> get roles => currentUser?.roles ?? {};
  bool get isAdmin => currentUser?.isAdmin ?? false;

  /// Vérifier si l'utilisateur a un rôle spécifique
  bool hasRole(String role) {
    return currentUser?.roles.contains(role) ?? false;
  }

  /// Effacer toutes les données
  Future<void> clearAllData() async {
    _currentUser = null;
    _error = null;
    await _clearCache();
    notifyListeners();
  }

  /// Rafraîchir l'utilisateur depuis AuthService
  void refreshFromAuthService() {
    if (_authService.isAuthenticated) {
      _currentUser = _authService.currentUser;
      notifyListeners();
    }
  }

  /// Vérifier l'état actuel
  void debugStatus() {
    if (!kDebugMode) return;

    print('=== USER SERVICE STATUS ===');
    print('Authentifié: ${_authService.isAuthenticated}');
    print('Utilisateur local: ${_currentUser != null}');
    print('Utilisateur AuthService: ${_authService.currentUser != null}');
    print('Email: ${_currentUser?.email ?? _authService.currentUser?.email}');
    print('=========================');
  }
}
