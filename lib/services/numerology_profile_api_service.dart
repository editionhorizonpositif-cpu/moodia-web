// lib/services/numerology_profile_api_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/numerology_profile.dart';
import 'numerology_api_service.dart';

class NumerologyProfileApiService {
  final NumerologyApiService _numerologyApiService;

  // Stream pour les changements de profil
  final _profileStreamController =
      StreamController<NumerologyProfile?>.broadcast();
  Stream<NumerologyProfile?> get profileStream =>
      _profileStreamController.stream;

  // État du profil
  NumerologyProfile? _currentProfile;
  NumerologyProfile? get currentProfile => _currentProfile;

  NumerologyProfileApiService(this._numerologyApiService);

  /// Charge le profil avec gestion d'état intelligente
  Future<NumerologyProfile?> loadProfile({
    required int userId,
    bool forceRefresh = false,
    bool autoCreateIfMissing = false,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 LOAD PROFILE - userId: $userId');
      }

      // 1. Essayer de charger le profil
      NumerologyProfile? profile;

      try {
        profile = await _numerologyApiService.getProfileByUserId(
          userId,
          forceRefresh: forceRefresh,
        );

        // Si profile est null (404), et autoCreateIfMissing=true, on crée
        if (profile == null && autoCreateIfMissing) {
          if (kDebugMode) {
            print('🆕 Profil non trouvé, tentative de création automatique...');
          }

          final prefs = await SharedPreferences.getInstance();
          final savedName = prefs.getString('numerology_fullName');
          final savedDateStr = prefs.getString('numerology_birthDate');

          if (savedName != null && savedDateStr != null) {
            final birthDate = DateTime.parse(savedDateStr);

            profile = await _numerologyApiService.generateProfile(
              userId: userId,
              birthDate: birthDate,
              fullName: savedName,
            );

            if (kDebugMode) {
              print('✅ Profil créé automatiquement');
            }
          }
        }
      } on NumerologyException catch (e) {
        // Pour les erreurs serveur (500), on les propage
        if (e.type == NumerologyExceptionType.server) {
          if (kDebugMode) {
            print('❌ Erreur serveur critique: $e');
          }
          rethrow;
        }
        // Pour les autres erreurs, on retourne null
        if (kDebugMode) {
          print('⚠️ Erreur non critique: $e');
        }
        return null;
      }

      // 2. Mettre à jour l'état courant
      if (profile != null) {
        _currentProfile = profile;
        _profileStreamController.add(profile);
        await _cacheProfileMetadata(userId, profile);
      } else {
        _currentProfile = null;
        _profileStreamController.add(null);
      }

      return profile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur loadProfile: $e');
      }
      _profileStreamController.add(null);
      rethrow;
    }
  }

  /// Rafraîchit le profil
  Future<NumerologyProfile?> refreshProfile(int userId) async {
    _numerologyApiService.clearCache(userId);
    return await loadProfile(
      userId: userId,
      forceRefresh: true,
      autoCreateIfMissing: false,
    );
  }

  Future<void> _cacheProfileMetadata(
    int userId,
    NumerologyProfile profile,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('numerology_profile_id', profile.userId ?? 0);
      await prefs.setInt('numerology_life_path', profile.lifePathNumber ?? 0);
      await prefs.setString(
        'numerology_last_update',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur cache métadonnées: $e');
      }
    }
  }

  Future<Map<String, dynamic>> getCachedMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'profileId': prefs.getInt('numerology_profile_id'),
        'lifePath': prefs.getInt('numerology_life_path'),
        'lastUpdate': prefs.getString('numerology_last_update'),
      };
    } catch (e) {
      return {};
    }
  }

  Future<bool> canAutoCreateProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasName = prefs.containsKey('numerology_fullName');
      final hasDate = prefs.containsKey('numerology_birthDate');
      return hasName && hasDate;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveProfileData({
    required String fullName,
    required DateTime birthDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('numerology_fullName', fullName.trim());
      await prefs.setString(
        'numerology_birthDate',
        birthDate.toIso8601String(),
      );

      if (kDebugMode) {
        print('💾 Données profil sauvegardées');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sauvegarde données: $e');
      }
      rethrow;
    }
  }

  Future<void> clearProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('numerology_fullName');
      await prefs.remove('numerology_birthDate');
      await prefs.remove('numerology_profile_id');
      await prefs.remove('numerology_life_path');
      await prefs.remove('numerology_last_update');

      _currentProfile = null;
      _profileStreamController.add(null);

      if (kDebugMode) {
        print('🧹 Données profil nettoyées');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur nettoyage données: $e');
      }
    }
  }

  void dispose() {
    _profileStreamController.close();
  }
}
