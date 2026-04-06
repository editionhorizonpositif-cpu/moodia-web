// lib/services/analytics_service.dart - Version sans Firebase

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:convert';

import '../models/user.dart';
import '../models/user_stats.dart';

/// Service d'analytics et de tracking pour Moodia
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  bool _analyticsEnabled = true;
  bool _debugMode = false;

  // Configuration
  static const String _appName = 'Moodia';
  static const String _appVersion = '1.0.0';

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal() {
    _initialize();
  }

  /// Initialisation du service
  Future<void> _initialize() async {
    try {
      // Charger les préférences utilisateur
      final prefs = await SharedPreferences.getInstance();
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
      _debugMode = prefs.getBool('debug_mode') ?? false;

      if (_debugMode) {
        debugPrint('AnalyticsService initialisé');
      }
    } catch (e) {
      debugPrint('Erreur initialisation AnalyticsService: $e');
    }
  }

  /// Activer/désactiver les analytics
  Future<void> setAnalyticsEnabled(bool enabled) async {
    _analyticsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', enabled);

    if (_debugMode) {
      debugPrint('Analytics ${enabled ? 'activé' : 'désactivé'}');
    }
  }

  /// Activer/désactiver le mode debug
  Future<void> setDebugMode(bool enabled) async {
    _debugMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debug_mode', enabled);
  }

  /// Track un événement personnalisé
  static Future<void> trackEvent({
    required String name,
    Map<String, dynamic>? parameters,
    bool forceTrack = false,
  }) async {
    final instance = AnalyticsService();

    if (!instance._analyticsEnabled && !forceTrack) return;

    try {
      // Log local pour le debug
      if (instance._debugMode) {
        debugPrint('Event tracked: $name - $parameters');
      }

      // Sauvegarder l'événement localement pour batch processing
      await _storeEventLocally(name, parameters);

      // Option: Envoyer immédiatement au serveur si en WiFi
      await _sendEventToServer(name, parameters);
    } catch (e) {
      debugPrint('Erreur tracking event $name: $e');
    }
  }

  /// Track une vue d'écran
  static Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    final instance = AnalyticsService();

    if (!instance._analyticsEnabled) return;

    try {
      // Événement personnalisé
      await trackEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': screenName,
          'screen_class': screenClass ?? screenName,
          'app_name': _appName,
          'app_version': _appVersion,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
    } catch (e) {
      debugPrint('Erreur tracking screen view $screenName: $e');
    }
  }

  /// Track une session utilisateur
  static Future<void> trackSession({
    required String sessionType,
    required int duration, // en secondes
    required String category,
    Map<String, dynamic>? additionalParams,
  }) async {
    await trackEvent(
      name: 'session_completed',
      parameters: {
        'session_type': sessionType,
        'duration_seconds': duration,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
    );
  }

  /// Track une entrée d'humeur
  static Future<void> trackMoodEntry({
    required int moodLevel, // 1-10
    required String moodCategory,
    String? note,
    Map<String, dynamic>? additionalParams,
  }) async {
    await trackEvent(
      name: 'mood_recorded',
      parameters: {
        'mood_level': moodLevel,
        'mood_category': moodCategory,
        'note_length': note?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
    );
  }

  /// Track une habitude complétée
  static Future<void> trackHabitCompletion({
    required String habitName,
    required String frequency,
    required int streak,
    Map<String, dynamic>? additionalParams,
  }) async {
    await trackEvent(
      name: 'habit_completed',
      parameters: {
        'habit_name': habitName,
        'frequency': frequency,
        'current_streak': streak,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
    );
  }

  /// Track un événement d'erreur
  static Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? screen,
    Map<String, dynamic>? additionalParams,
  }) async {
    await trackEvent(
      name: 'error_occurred',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'screen': screen ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
      forceTrack: true, // Toujours tracker les erreurs
    );
  }

  /// Track un événement de conversion (achat, inscription, etc.)
  static Future<void> trackConversion({
    required String conversionType,
    required double value,
    String? currency,
    Map<String, dynamic>? additionalParams,
  }) async {
    await trackEvent(
      name: 'conversion',
      parameters: {
        'conversion_type': conversionType,
        'value': value,
        'currency': currency ?? 'EUR',
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
    );
  }

  /// Track un engagement utilisateur
  static Future<void> trackEngagement({
    required String engagementType,
    required int duration,
    String? contentId,
    Map<String, dynamic>? additionalParams,
  }) async {
    await trackEvent(
      name: 'engagement',
      parameters: {
        'engagement_type': engagementType,
        'duration_seconds': duration,
        'content_id': contentId,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
    );
  }

  /// Track une action utilisateur générique
  static Future<void> trackUserAction({
    required String action,
    required String context,
    Map<String, dynamic>? additionalParams,
  }) async {
    await trackEvent(
      name: 'user_action',
      parameters: {
        'action': action,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalParams,
      },
    );
  }

  /// Envoyer les statistiques utilisateur au serveur
  static Future<void> sendUserStats({
    required User user,
    required UserStats stats,
    String? period,
  }) async {
    try {
      // Préparer les données de statistiques
      final statsData = {
        'user_id': user.id,
        'period': period ?? 'weekly',
        'stats': stats.toJson(),
        'collected_at': DateTime.now().toIso8601String(),
      };

      // Track l'événement
      await trackEvent(name: 'user_stats_synced', parameters: statsData);

      // Envoyer directement au serveur
      await _sendStatsToServer(statsData);
    } catch (e) {
      debugPrint('Erreur envoi stats utilisateur: $e');
    }
  }

  /// Générer un rapport d'analytics
  static Future<Map<String, dynamic>> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      // Récupérer les événements stockés localement
      final events = await _getStoredEvents(startDate, endDate);

      // Calculer les métriques
      final metrics = _calculateMetrics(events);

      // Ajouter les informations de période
      final report = {
        'report_id': 'report_${DateTime.now().millisecondsSinceEpoch}',
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'user_id': userId,
        'metrics': metrics,
        'total_events': events.length,
        'generated_at': DateTime.now().toIso8601String(),
      };

      return report;
    } catch (e) {
      debugPrint('Erreur génération rapport: $e');
      return {
        'error': e.toString(),
        'generated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Stocker un événement localement
  static Future<void> _storeEventLocally(
    String name,
    Map<String, dynamic>? parameters,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = prefs.getStringList('analytics_events') ?? [];

      final eventData = {
        'name': name,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'device_id': await _getDeviceId(),
      };

      events.add(jsonEncode(eventData));

      // Garder seulement les 1000 derniers événements
      if (events.length > 1000) {
        events.removeAt(0);
      }

      await prefs.setStringList('analytics_events', events);
    } catch (e) {
      debugPrint('Erreur stockage événement local: $e');
    }
  }

  /// Envoyer un événement au serveur
  static Future<void> _sendEventToServer(
    String name,
    Map<String, dynamic>? parameters,
  ) async {
    try {
      // Cette méthode est à implémenter selon votre API
      // Exemple avec votre ApiService :
      /*
      final apiService = ApiService();
      await apiService.trackAnalyticsEvent({
        'event_name': name,
        'event_data': parameters,
        'timestamp': DateTime.now().toIso8601String(),
        'device_id': await _getDeviceId(),
        'app_version': _appVersion,
      });
      */

      // Pour l'instant, juste log en debug
      final instance = AnalyticsService();
      if (instance._debugMode) {
        debugPrint('Event ready for server: $name');
      }
    } catch (e) {
      debugPrint('Erreur envoi événement au serveur: $e');
      // Ne pas throw, on continue avec le stockage local
    }
  }

  /// Envoyer les stats au serveur
  static Future<void> _sendStatsToServer(Map<String, dynamic> statsData) async {
    try {
      // À implémenter avec votre ApiService
      /*
      final apiService = ApiService();
      await apiService.sendUserStats(statsData);
      */

      final instance = AnalyticsService();
      if (instance._debugMode) {
        debugPrint('Stats ready for server: $statsData');
      }
    } catch (e) {
      debugPrint('Erreur envoi stats au serveur: $e');
    }
  }

  /// Récupérer les événements stockés
  static Future<List<Map<String, dynamic>>> _getStoredEvents(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final events = prefs.getStringList('analytics_events') ?? [];

    final filteredEvents = <Map<String, dynamic>>[];

    for (final eventString in events) {
      try {
        final event = jsonDecode(eventString) as Map<String, dynamic>;
        final timestamp = DateTime.parse(event['timestamp']);

        if (timestamp.isAfter(startDate) && timestamp.isBefore(endDate)) {
          filteredEvents.add(event);
        }
      } catch (e) {
        debugPrint('Erreur parsing événement: $e');
      }
    }

    return filteredEvents;
  }

  /// Calculer les métriques à partir des événements
  static Map<String, dynamic> _calculateMetrics(
    List<Map<String, dynamic>> events,
  ) {
    final metrics = <String, dynamic>{
      'session_count': 0,
      'average_session_duration': 0.0,
      'mood_entries': 0,
      'average_mood': 0.0,
      'habit_completions': 0,
      'screen_views': {},
      'error_count': 0,
      'unique_event_types': {},
    };

    int totalSessionDuration = 0;
    int totalMoodScore = 0;

    for (final event in events) {
      final name = event['name'] as String;
      final params = event['parameters'] as Map<String, dynamic>;

      // Compter les types d'événements uniques
      metrics['unique_event_types'][name] =
          (metrics['unique_event_types'][name] ?? 0) + 1;

      switch (name) {
        case 'session_completed':
          metrics['session_count']++;
          totalSessionDuration += params['duration_seconds'] as int;
          break;

        case 'mood_recorded':
          metrics['mood_entries']++;
          totalMoodScore += params['mood_level'] as int;
          break;

        case 'habit_completed':
          metrics['habit_completions']++;
          break;

        case 'screen_view':
          final screen = params['screen_name'] as String;
          metrics['screen_views'][screen] =
              (metrics['screen_views'][screen] ?? 0) + 1;
          break;

        case 'error_occurred':
          metrics['error_count']++;
          break;
      }
    }

    // Calculer les moyennes
    if (metrics['session_count'] > 0) {
      metrics['average_session_duration'] =
          totalSessionDuration / metrics['session_count'];
    }

    if (metrics['mood_entries'] > 0) {
      metrics['average_mood'] = totalMoodScore / metrics['mood_entries'];
    }

    return metrics;
  }

  /// Générer un ID d'appareil unique
  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      // Générer un nouvel ID
      final random = math.Random();
      deviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(100000)}';
      await prefs.setString('device_id', deviceId);
    }

    return deviceId;
  }

  /// Nettoyer les anciens événements
  static Future<void> cleanupOldEvents({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final prefs = await SharedPreferences.getInstance();
    final events = prefs.getStringList('analytics_events') ?? [];

    final filteredEvents = <String>[];

    for (final eventString in events) {
      try {
        final event = jsonDecode(eventString) as Map<String, dynamic>;
        final timestamp = DateTime.parse(event['timestamp']);

        if (timestamp.isAfter(cutoffDate)) {
          filteredEvents.add(eventString);
        }
      } catch (e) {
        // Ignorer les événements malformés
      }
    }

    await prefs.setStringList('analytics_events', filteredEvents);
  }

  /// Envoyer les événements en batch au serveur
  static Future<void> sendBatchToServer() async {
    final instance = AnalyticsService();

    try {
      final prefs = await SharedPreferences.getInstance();
      final events = prefs.getStringList('analytics_events') ?? [];

      if (events.isEmpty) return;

      // Pour l'instant, on simule juste l'envoi
      if (instance._debugMode) {
        debugPrint('Batch de ${events.length} événements prêt à être envoyé');
      }

      // TODO: Implémenter l'envoi batch vers votre API
      /*
      final batchData = {
        'events': events.map((e) => jsonDecode(e)).toList(),
        'device_id': await _getDeviceId(),
        'sent_at': DateTime.now().toIso8601String(),
      };
      
      // Envoyer au serveur
      final apiService = ApiService();
      final response = await apiService.sendAnalyticsBatch(batchData);
      
      if (response.success) {
        // Effacer les événements envoyés
        await prefs.remove('analytics_events');
      }
      */
    } catch (e) {
      debugPrint('Erreur envoi batch: $e');
    }
  }

  /// Méthodes utilitaires
  static String get currentSessionId {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  static bool get isEnabled {
    return _instance._analyticsEnabled;
  }

  /// Obtenir les statistiques d'usage
  static Future<Map<String, dynamic>> getUsageStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final events = await _getStoredEvents(startDate, endDate);
      return _calculateMetrics(events);
    } catch (e) {
      debugPrint('Erreur récupération stats usage: $e');
      return {};
    }
  }

  /// Exporter les données analytics
  static Future<String> exportAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final sDate =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final eDate = endDate ?? DateTime.now();

      final events = await _getStoredEvents(sDate, eDate);
      final report = await generateReport(startDate: sDate, endDate: eDate);

      final exportData = {
        'export_info': {
          'exported_at': DateTime.now().toIso8601String(),
          'date_range': {
            'start': sDate.toIso8601String(),
            'end': eDate.toIso8601String(),
          },
          'total_events': events.length,
        },
        'report': report,
        'raw_events': events,
      };

      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('Erreur export analytics: $e');
      return '{"error": "${e.toString()}"}';
    }
  }
}

// Extension pour le formatage JSON
extension JsonEncodeExtension on Map<String, dynamic> {
  String toJsonString() => jsonEncode(this);
}

extension JsonDecodeExtension on String {
  Map<String, dynamic> fromJsonString() =>
      jsonDecode(this) as Map<String, dynamic>;
}
