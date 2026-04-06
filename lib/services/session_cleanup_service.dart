import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodia/services/user_cache_service.dart';
import 'package:moodia/services/journal_api_service.dart';
import 'package:moodia/services/emotion_api_service.dart';
import 'package:moodia/services/notification_cache_service.dart';
import 'package:moodia/providers/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:moodia/routes/route.dart';

class SessionCleanupService {
  static Future<void> cleanupAndRedirect(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    // 1. Nettoyer SecureStorage
    final storage = const FlutterSecureStorage();
    final secureKeys = [
      'jwt_token',
      'user_id',
      'auth_token',
      'refresh_token',
      'current_user',
    ];
    for (var key in secureKeys) {
      try {
        await storage.delete(key: key);
      } catch (_) {}
    }

    // 2. Nettoyer SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final prefsKeys = [
      'jwt_token',
      'auth_data',
      'current_user',
      'is_logged_in',
      'userId',
      'user_id',
      'email',
      'fullName',
      'remember_me',
      'pending_verification_email',
    ];
    for (var key in prefsKeys) {
      try {
        await prefs.remove(key);
      } catch (_) {}
    }

    // 3. Nettoyer les caches métier
    try {
      await UserCacheService().clearCache();
    } catch (_) {}
    try {
      await JournalApiService().clearCache();
    } catch (_) {}
    try {
      await EmotionApiService().clearCache();
    } catch (_) {}
    try {
      await NotificationCacheService.clearPendingReads();
      await NotificationCacheService.saveNotifications([]);
    } catch (_) {}

    // 4. Nettoyer le provider d'abonnement (si contexte disponible)
    final context = navigatorKey.currentContext;
    if (context != null) {
      try {
        final subscriptionProvider = Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        );
        await subscriptionProvider.clearCache();
      } catch (_) {}
    }

    // 5. Rediriger vers login (vider l'historique)
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}
