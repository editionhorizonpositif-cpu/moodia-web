// lib/services/user_cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  static const String _userCacheKey = 'cached_user';
  static const String _userSecureKey = 'secure_user_data';
  static const String _userEmailKey = 'user_email';
  static const String _userFullNameKey = 'user_fullname';
  static const String _userIdKey = 'user_id';
  static const String _userPremiumKey = 'user_is_premium';
  static const String _userAuthenticatedKey = 'user_is_authenticated';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  User? _memoryCache;

  /// Sauvegarde PERMANENTE de l'utilisateur
  Future<void> cacheUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());

      // Stockage permanent dans SharedPreferences
      await prefs.setString(_userCacheKey, userJson);

      // Stockage sécurisé (pour les données sensibles)
      await _secureStorage.write(key: _userSecureKey, value: userJson);

      // Champs individuels pour accès ultra-rapide
      await prefs.setString(_userEmailKey, user.email);
      await prefs.setString(_userFullNameKey, user.fullName);
      await prefs.setInt(_userIdKey, user.id ?? 0);
      await prefs.setBool(_userPremiumKey, user.isPremium);
      await prefs.setBool(_userAuthenticatedKey, true);

      // Cache mémoire
      _memoryCache = user;

      if (kDebugMode) {
        print('✅ Utilisateur sauvegardé PERMANENTEMENT: ${user.email}');
        print('   - Premium: ${user.isPremium}');
        print('   - ID: ${user.id}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur cacheUser: $e');
    }
  }

  /// Charger l'utilisateur depuis le cache permanent
  Future<User?> loadCachedUser() async {
    // 1. Vérifier le cache mémoire (ultra-rapide)
    if (_memoryCache != null) {
      if (kDebugMode) print('✅ Utilisateur chargé depuis mémoire cache');
      return _memoryCache;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // 2. Vérifier si un utilisateur est authentifié
      final isAuthenticated = prefs.getBool(_userAuthenticatedKey) ?? false;
      if (!isAuthenticated) return null;

      // 3. Essayer de charger depuis SecureStorage (le plus sécurisé)
      try {
        final secureJson = await _secureStorage.read(key: _userSecureKey);
        if (secureJson != null) {
          final user = User.fromJson(jsonDecode(secureJson));
          _memoryCache = user;
          if (kDebugMode) {
            print('✅ Utilisateur chargé depuis SecureStorage: ${user.email}');
          }
          return user;
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Erreur lecture SecureStorage: $e');
      }

      // 4. Fallback sur SharedPreferences
      final userJson = prefs.getString(_userCacheKey);
      if (userJson != null) {
        final user = User.fromJson(jsonDecode(userJson));
        _memoryCache = user;
        if (kDebugMode) {
          print('✅ Utilisateur chargé depuis SharedPreferences: ${user.email}');
        }
        return user;
      }

      // 5. Dernier recours : reconstruction depuis champs individuels
      return await _reconstructUserFromFields();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur loadCachedUser: $e');
      return null;
    }
  }

  /// Reconstruire l'utilisateur depuis les champs individuels
  Future<User?> _reconstructUserFromFields() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final email = prefs.getString(_userEmailKey);
      final fullName = prefs.getString(_userFullNameKey);
      final userId = prefs.getInt(_userIdKey);
      final isPremium = prefs.getBool(_userPremiumKey) ?? false;

      if (email == null || fullName == null || userId == null) {
        return null;
      }

      // Créer un utilisateur basique
      final user = User(
        id: userId,
        fullName: fullName,
        email: email,
        isPremium: isPremium,
        isActive: true,
        emailVerified: true, // Supposé vrai si déjà connecté
        locale: 'fr_FR',
        dailyGoal: 1,
        weeklyGoal: 7,
        notificationEnabled: true,
        pushNotificationEnabled: true,
        marketingConsent: false,
        accountDeletionRequested: false,
        dataExportRequested: false,
        twoFactorEnabled: false,
        streakCount: 0,
        currentStreakDays: 0,
        bestStreakDays: 0,
        totalActivitiesCompleted: 0,
        totalTimeMinutes: 0,
      );

      if (kDebugMode) {
        print('🔄 Utilisateur reconstruit depuis champs individuels');
      }

      return user;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur reconstruction: $e');
      return null;
    }
  }

  /// Vérifier si un utilisateur est en cache
  Future<bool> isUserCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_userAuthenticatedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir l'email depuis le cache
  Future<String?> getCachedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir le statut premium depuis le cache
  Future<bool> getCachedPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_userPremiumKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mettre à jour partiellement l'utilisateur en cache
  Future<void> updateCachedUser({
    String? fullName,
    String? email,
    bool? isPremium,
    int? streakCount,
    int? currentStreakDays,
    int? bestStreakDays,
    int? totalActivitiesCompleted,
    int? totalTimeMinutes,
  }) async {
    try {
      final currentUser = await loadCachedUser();
      if (currentUser == null) return;

      final updatedUser = currentUser.copyWith(
        fullName: fullName,
        email: email,
        isPremium: isPremium,
        streakCount: streakCount,
        currentStreakDays: currentStreakDays,
        bestStreakDays: bestStreakDays,
        totalActivitiesCompleted: totalActivitiesCompleted,
        totalTimeMinutes: totalTimeMinutes,
      );

      await cacheUser(updatedUser);

      if (kDebugMode) {
        print('✅ Cache utilisateur mis à jour');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateCachedUser: $e');
    }
  }

  /// Mettre à jour uniquement le statut premium
  Future<void> updatePremiumStatus(bool isPremium) async {
    await updateCachedUser(isPremium: isPremium);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userPremiumKey, isPremium);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updatePremiumStatus: $e');
    }
  }

  /// Effacer complètement le cache (à la déconnexion)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Supprimer toutes les données utilisateur
      await prefs.remove(_userCacheKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userFullNameKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userPremiumKey);
      await prefs.remove(_userAuthenticatedKey);

      // Supprimer les données sécurisées
      await _secureStorage.delete(key: _userSecureKey);

      // Vider le cache mémoire
      _memoryCache = null;

      if (kDebugMode) {
        print('🧹 Cache utilisateur complètement effacé');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur clearCache: $e');
    }
  }

  /// Obtenir les statistiques du cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool(_userAuthenticatedKey) ?? false;
      final email = await getCachedEmail();

      return {
        'isAuthenticated': isAuthenticated,
        'email': email ?? 'Non connecté',
        'hasSecureData': await _secureStorage.containsKey(key: _userSecureKey),
        'hasPrefsData': prefs.containsKey(_userCacheKey),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Vider uniquement le cache mémoire
  void clearMemoryCache() {
    _memoryCache = null;
  }
}
