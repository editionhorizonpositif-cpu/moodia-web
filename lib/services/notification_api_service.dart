// lib/services/notification_api_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/notification.dart';
import 'api_service.dart';
import 'notification_cache_service.dart'; // Ajout de l'import du service de cache

class NotificationApiService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'notifications';

  NotificationApiService() : _apiService = ApiService();

  // Méthode pour obtenir les headers avec userId
  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ UserId non trouvé dans SharedPreferences');
        }
        // Essayer de récupérer depuis auth_data
        final authData = prefs.getString('auth_data');
        if (authData != null) {
          try {
            final data = jsonDecode(authData) as Map<String, dynamic>;
            final extractedUserId = data['userId'];
            if (extractedUserId != null) {
              await prefs.setInt('userId', extractedUserId as int);
              if (kDebugMode) {
                print('👤 UserId récupéré depuis auth_data: $extractedUserId');
              }
              return await _apiService.getHeadersWithUserId(extractedUserId);
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Erreur parsing auth_data: $e');
            }
          }
        }
        return await _apiService.getHeaders();
      }

      return await _apiService.getHeadersWithUserId(userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _getHeadersWithUserId: $e');
      }
      return await _apiService.getHeaders();
    }
  }

  // Récupérer mes notifications paginées
  Future<List<NotificationModel>> getMyNotifications({
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ UserId non disponible');
        }
        return [];
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/my').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          'sort': sort,
        },
      );

      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      // DEBUG: Afficher la réponse
      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          print(
            '📥 Body preview: ${response.body.substring(0, min(500, response.body.length))}...',
          );
        }
      }

      if (response.statusCode >= 400) {
        if (kDebugMode) {
          print('⚠️ Erreur HTTP: ${response.statusCode}');
        }
        return [];
      }

      // CORRECTION: Vérifier si la réponse est vide
      if (response.body.isEmpty) {
        return [];
      }

      try {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

        if (jsonResponse is Map<String, dynamic>) {
          // API Spring paginée
          final content = (jsonResponse['content'] ?? []) as List<dynamic>;
          final notifications = <NotificationModel>[];

          for (var json in content) {
            try {
              final notification = NotificationModel.fromJson(
                json as Map<String, dynamic>,
              );
              notifications.add(notification);
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Erreur parsing notification individuelle: $e');
                print('⚠️ JSON: $json');
              }
              // Continuer avec la suivante
            }
          }

          return notifications;
        } else if (jsonResponse is List) {
          // API non paginée
          final notifications = <NotificationModel>[];

          for (var json in jsonResponse) {
            try {
              final notification = NotificationModel.fromJson(
                json as Map<String, dynamic>,
              );
              notifications.add(notification);
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Erreur parsing notification individuelle: $e');
                print('⚠️ JSON: $json');
              }
              // Continuer avec la suivante
            }
          }

          return notifications;
        }

        return [];
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing JSON réponse: $e');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getMyNotifications: $e');
      }
      return [];
    }
  }

  // Récupérer mes notifications non lues
  Future<List<NotificationModel>> getMyUnreadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return [];
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/my/unread');
      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      // DEBUG
      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        if (kDebugMode) {
          print('⚠️ Erreur HTTP: ${response.statusCode}');
        }
        return [];
      }

      if (response.body.isEmpty) {
        return [];
      }

      try {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

        if (jsonResponse is List) {
          final notifications = <NotificationModel>[];

          for (var json in jsonResponse) {
            try {
              final notification = NotificationModel.fromJson(
                json as Map<String, dynamic>,
              );
              notifications.add(notification);
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Erreur parsing notification non lue: $e');
              }
            }
          }

          return notifications;
        }

        return [];
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing JSON: $e');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getMyUnreadNotifications: $e');
      }
      return [];
    }
  }

  // Compter mes notifications non lues
  Future<int> getMyUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return 0;
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/my/unread/count',
      );
      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        if (kDebugMode) {
          print(
            '⚠️ Erreur comptage notifications non lues: ${response.statusCode}',
          );
        }
        return 0;
      }

      try {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

        // Plusieurs formats possibles
        if (jsonResponse is int) {
          return jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          return (jsonResponse['unreadCount'] as int?) ?? 0;
        } else if (jsonResponse is String) {
          return int.tryParse(jsonResponse) ?? 0;
        }

        return 0;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing unread count: $e');
        }
        return 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getMyUnreadCount: $e');
      }
      return 0;
    }
  }

  // Obtenir mes statistiques de notifications
  Future<NotificationStatistics?> getMyStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return null;
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/my/statistics',
      );
      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        if (kDebugMode) {
          print('⚠️ Erreur statistiques: ${response.statusCode}');
        }
        return null;
      }

      try {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return NotificationStatistics.fromJson(jsonResponse);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing statistiques: $e');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getMyStatistics: $e');
      }
      return null;
    }
  }

  // Rechercher dans mes notifications
  Future<List<NotificationModel>> searchMyNotifications(String keyword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return [];
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/my/search',
      ).replace(queryParameters: {'keyword': keyword});

      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();

      if (kDebugMode) {
        print('🔍 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        if (kDebugMode) {
          print('⚠️ Erreur recherche: ${response.statusCode}');
        }
        return [];
      }

      try {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

        if (jsonResponse is List) {
          final notifications = <NotificationModel>[];
          for (var json in jsonResponse) {
            try {
              final notification = NotificationModel.fromJson(
                json as Map<String, dynamic>,
              );
              notifications.add(notification);
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Erreur parsing notification: $e');
              }
            }
          }
          return notifications;
        }

        return [];
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing recherche: $e');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur searchMyNotifications: $e');
      }
      return [];
    }
  }

  // Marquer une notification comme lue
  Future<NotificationModel?> markAsRead(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return null;
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id/read');
      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 PATCH $url');
      }

      final response = await http.patch(url, headers: headers);

      if (response.statusCode >= 400) {
        if (kDebugMode) {
          print('⚠️ Erreur marquage comme lu: ${response.statusCode}');
        }
        return null;
      }

      try {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        return NotificationModel.fromJson(jsonResponse);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing réponse marquage: $e');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur markAsRead: $e');
      }
      return null;
    }
  }

  // Marquer toutes mes notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return false;
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/my/read-all');
      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 PATCH $url');
      }

      final response = await http.patch(url, headers: headers);

      return response.statusCode < 400;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur markAllAsRead: $e');
      }
      return false;
    }
  }

  // Supprimer une notification
  Future<bool> deleteNotification(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return false;
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');
      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();

      if (kDebugMode) {
        print('🗑️ DELETE $url');
      }

      final response = await http.delete(url, headers: headers);

      return response.statusCode < 400;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur deleteNotification: $e');
      }
      return false;
    }
  }

  // Supprimer toutes mes notifications
  Future<bool> deleteAllMyNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return false;
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/my/all');
      final headers = await _getHeadersWithUserId();
      headers['X-User-Id'] = userId.toString();

      if (kDebugMode) {
        print('🗑️ DELETE $url');
      }

      final response = await http.delete(url, headers: headers);

      return response.statusCode < 400;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur deleteAllMyNotifications: $e');
      }
      return false;
    }
  }

  // ========== MÉTHODES AVEC CACHE ==========

  // Charger les notifications depuis le cache d'abord, puis synchroniser
  Future<List<NotificationModel>> loadNotificationsWithCache({
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    // 1. Charger depuis le cache en priorité
    List<NotificationModel> cached = [];
    if (!forceRefresh) {
      cached = await NotificationCacheService.loadNotifications();
      if (cached.isNotEmpty && kDebugMode) {
        print('📱 Affichage depuis cache (${cached.length} notifications)');
      }
    }

    // 2. Si en ligne, récupérer les dernières données et fusionner
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    if (isOnline) {
      try {
        final fresh = await getMyNotifications(
          page: page,
          size: size,
          sort: 'createdAt,desc',
        );
        if (fresh.isNotEmpty) {
          // Fusion : garder les lectures locales non synchronisées
          final merged = _mergeNotifications(fresh, cached);
          await NotificationCacheService.saveNotifications(merged);
          return merged;
        }
      } catch (e) {
        if (kDebugMode)
          print('⚠️ Échec récupération en ligne, utilisation cache');
      }
    }

    return cached;
  }

  // Fusion intelligente : conserver les lectures locales non synchronisées
  List<NotificationModel> _mergeNotifications(
    List<NotificationModel> fresh,
    List<NotificationModel> cached,
  ) {
    final Map<int, NotificationModel> freshMap = {for (var n in fresh) n.id: n};
    final Map<int, NotificationModel> cachedMap = {
      for (var n in cached) n.id: n,
    };

    // Pour chaque notification dans le cache, si elle est marquée lue localement mais pas dans fresh,
    // on conserve la version locale (avec seen = true)
    for (var entry in cachedMap.entries) {
      final id = entry.key;
      final cachedNotif = entry.value;
      if (cachedNotif.seen && freshMap.containsKey(id) && !freshMap[id]!.seen) {
        // La notif a été lue localement, on garde la version locale
        freshMap[id] = cachedNotif;
      }
    }

    return freshMap.values.toList()..sort(
      (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
        a.createdAt ?? DateTime.now(),
      ),
    );
  }

  // Marquer une notification comme lue avec gestion offline
  Future<NotificationModel?> markAsReadWithCache(int id) async {
    // 1. Mise à jour locale immédiate
    final cachedList = await NotificationCacheService.loadNotifications();
    final index = cachedList.indexWhere((n) => n.id == id);
    NotificationModel? updated;

    if (index != -1) {
      updated = cachedList[index].copyWith(seen: true, readAt: DateTime.now());
      cachedList[index] = updated;
      await NotificationCacheService.saveNotifications(cachedList);
    } else {
      // Si la notification n'est pas en cache, on ne peut pas la marquer localement
      if (kDebugMode) print('⚠️ Notification $id introuvable dans le cache');
      return null;
    }

    // 2. Vérifier la connexion
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;

    if (isOnline) {
      try {
        final result = await markAsRead(id);
        if (result != null) {
          // Mettre à jour le cache avec la version serveur
          final newList = cachedList
              .map((n) => n.id == id ? result : n)
              .toList();
          await NotificationCacheService.saveNotifications(newList);
          // Supprimer des pending si présent
          await NotificationCacheService.removePendingReadId(id);
          return result;
        } else {
          // Échec de l'API, ajouter aux pending
          await NotificationCacheService.addPendingReadId(id);
          return updated;
        }
      } catch (e) {
        await NotificationCacheService.addPendingReadId(id);
        return updated;
      }
    } else {
      // Hors ligne, ajouter aux pending
      await NotificationCacheService.addPendingReadId(id);
      return updated;
    }
  }

  // Synchroniser les lectures en attente
  Future<void> syncPendingReads() async {
    final pendingIds = await NotificationCacheService.getPendingReadIds();
    if (pendingIds.isEmpty) return;

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity != ConnectivityResult.none;
    if (!isOnline) return;

    if (kDebugMode)
      print(
        '🔄 Synchronisation de ${pendingIds.length} lectures en attente...',
      );

    for (var id in pendingIds) {
      try {
        final result = await markAsRead(id);
        if (result != null) {
          await NotificationCacheService.removePendingReadId(id);
          // Mettre à jour le cache local
          final cached = await NotificationCacheService.loadNotifications();
          final index = cached.indexWhere((n) => n.id == id);
          if (index != -1) {
            cached[index] = result;
            await NotificationCacheService.saveNotifications(cached);
          }
          if (kDebugMode) print('✅ Lecture $id synchronisée');
        } else {
          if (kDebugMode) print('⚠️ Échec synchronisation $id (API a échoué)');
        }
      } catch (e) {
        if (kDebugMode) print('❌ Échec synchronisation $id: $e');
      }
    }
  }

  // Vider le cache local
  Future<void> clearCache() async {
    await NotificationCacheService.saveNotifications([]);
    await NotificationCacheService.clearPendingReads();
    if (kDebugMode) print('🧹 Cache des notifications vidé');
  }
}
