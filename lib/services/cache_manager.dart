// lib/services/cache_manager.dart
import 'package:flutter/foundation.dart';

import 'user_cache_service.dart';
import 'notification_api_service.dart';
import 'meditation_service.dart';
import 'journal_api_service.dart';
import 'emotion_api_service.dart';
//import 'challenge_api_service.dart';
import 'completion_service.dart';

class CacheManager {
  final UserCacheService userCache;
  final NotificationApiService notificationApi;
  final MeditationService meditationService;
  final JournalApiService journalApi;
  final EmotionApiService emotionApi;
  //final ChallengeApiService challengeApi;
  final CompletionService completionService;

  CacheManager({
    required this.userCache,
    required this.notificationApi,
    required this.meditationService,
    required this.journalApi,
    required this.emotionApi,
    //required this.challengeApi,
    required this.completionService,
  });

  /// Vide TOUS les caches de tous les services
  Future<void> clearAllCaches() async {
    if (kDebugMode) print('🧹 Nettoyage global des caches...');

    // On exécute en parallèle pour aller plus vite
    await Future.wait([
      userCache.clearCache(),
      meditationService.clearCache(),
      Future.sync(() => notificationApi.clearCache()),
      Future.sync(() => journalApi.clearCache()),
      Future.sync(() => emotionApi.clearCache()),
      //Future.sync(() => challengeApi.clearCache()),
      Future.sync(() => completionService.clearCache()),
    ]);

    if (kDebugMode) print('✅ Nettoyage global terminé');
  }
}
