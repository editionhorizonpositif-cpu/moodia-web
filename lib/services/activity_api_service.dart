// lib/services/activity_api_service.dart - VERSION COMPLÈTE AVEC completeActivity ET startActivity
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../models/activity_category.dart';
import '../models/activity_dtos.dart';
import '../models/activity_paged_response.dart';
import 'api_service.dart';
import 'media_cache_service.dart';

class ActivityApiService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'v1/activities';

  // Clés pour le cache SharedPreferences
  static const String _categoriesCacheKey = 'cached_activity_categories';
  static const String _activitiesCacheKeyPrefix = 'cached_activities_page_';
  static const String _popularActivitiesCacheKey = 'cached_popular_activities';
  static const String _newActivitiesCacheKey = 'cached_new_activities';
  static const String _recommendedActivitiesCacheKey =
      'cached_recommended_activities';
  static const String _userStatsCacheKey = 'cached_user_stats';
  static const String _activityDetailCacheKeyPrefix = 'cached_activity_detail_';

  // Durée de validité du cache (en millisecondes) - 24 heures
  static const int _cacheValidityDuration = 24 * 60 * 60 * 1000;

  // Service de cache média
  final MediaCacheService _mediaCache = MediaCacheService();

  ActivityApiService() : _apiService = ApiService();

  // ============ INITIALISATION ============

  Future<void> initialize() async {
    await _mediaCache.initialize();
    if (kDebugMode) {
      print('📦 ActivityApiService initialisé avec cache média');
    }
  }

  // ============ MÉTHODES DE CACHE ============

  Future<void> _saveToCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString(key, jsonEncode(cacheData));
      if (kDebugMode) print('✅ Données mises en cache: $key');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sauvegarde cache: $e');
    }
  }

  Future<T?> _loadFromCache<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(key);

      if (cachedJson != null) {
        final Map<String, dynamic> cacheMap = jsonDecode(cachedJson);
        final timestamp = cacheMap['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now - timestamp < _cacheValidityDuration) {
          final data = cacheMap['data'];
          if (data != null) {
            if (kDebugMode) print('✅ Données chargées depuis cache: $key');
            return fromJson(data as Map<String, dynamic>);
          }
        } else {
          if (kDebugMode) print('⏰ Cache expiré: $key');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement cache: $e');
    }
    return null;
  }

  Future<List<T>?> _loadListFromCache<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(key);

      if (cachedJson != null) {
        final Map<String, dynamic> cacheMap = jsonDecode(cachedJson);
        final timestamp = cacheMap['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now - timestamp < _cacheValidityDuration) {
          final dataList = cacheMap['data'] as List?;
          if (dataList != null) {
            final items = dataList
                .map((e) => fromJson(e as Map<String, dynamic>))
                .toList();
            if (kDebugMode) {
              print(
                '✅ Liste chargée depuis cache: $key (${items.length} items)',
              );
            }
            return items;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement liste cache: $e');
    }
    return null;
  }

  // ============ MÉTHODES POUR LES HEADERS ============

  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (kDebugMode) {
        print('👤 ActivityService - Utilisation du userId: $userId');
      }

      if (userId == null) {
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

  // ============ GESTION DES MÉDIAS EN CACHE ============

  Future<void> _precacheActivityMedia(Activity activity) async {
    try {
      final headers = await _getHeadersWithUserId();

      // Précharger l'image de couverture
      if (activity.coverImageAssetId != null) {
        await _cacheMediaIfNeeded(
          assetId: activity.coverImageAssetId!,
          mediaType: 'IMAGE',
          mediaUrl:
              '${ApiService.baseUrl}/media/${activity.coverImageAssetId}/download',
          headers: headers,
        );
      }

      // Précharger l'animation Lottie
      if (activity.lottieAnimationAssetId != null) {
        await _cacheMediaIfNeeded(
          assetId: activity.lottieAnimationAssetId!,
          mediaType: 'LOTTIE',
          mediaUrl:
              '${ApiService.baseUrl}/media/${activity.lottieAnimationAssetId}/lottie',
          headers: headers,
        );
      }

      // Précharger l'audio
      if (activity.audioGuideAssetId != null) {
        await _cacheMediaIfNeeded(
          assetId: activity.audioGuideAssetId!,
          mediaType: 'AUDIO',
          mediaUrl:
              '${ApiService.baseUrl}/media/${activity.audioGuideAssetId}/stream',
          headers: headers,
        );
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur précaching médias: $e');
    }
  }

  Future<void> _cacheMediaIfNeeded({
    required int assetId,
    required String mediaType,
    required String mediaUrl,
    required Map<String, String> headers,
  }) async {
    try {
      final cached = await _mediaCache.getCachedMedia(assetId);
      if (cached != null) {
        if (kDebugMode) print('📦 Média $assetId déjà en cache');
        return;
      }

      if (kDebugMode) {
        print('📥 Téléchargement du média $assetId ($mediaType)...');
        print('   URL: $mediaUrl');
      }

      final request = http.Request('GET', Uri.parse(mediaUrl));
      request.headers.addAll(headers);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final contentLength = streamedResponse.contentLength ?? 0;

        await _mediaCache.cacheMedia(
          assetId: assetId,
          mediaType: mediaType,
          mediaUrl: mediaUrl,
          stream: streamedResponse.stream,
          contentLength: contentLength,
        );

        if (kDebugMode) {
          print('✅ Média $assetId préchargé en cache');
        }
      } else {
        if (kDebugMode) {
          print(
            '❌ Échec téléchargement média $assetId: ${streamedResponse.statusCode}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur cache média $assetId: $e');
    }
  }

  // ============ MÉTHODES PRINCIPALES AVEC CACHE ============

  Future<ActivityPagedResponse<Activity>> getAllActivities({
    int page = 0,
    int size = 20,
    bool includeInactive = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cacheKey = '${_activitiesCacheKeyPrefix}$page\_$size';
      final cached = await _loadFromCache(
        cacheKey,
        (json) => ActivityPagedResponse<Activity>.fromJson(
          json,
          (itemJson) => Activity.fromJson(itemJson),
        ),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint').replace(
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          'includeInactive': includeInactive.toString(),
        },
      );

      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération activités: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      final result = ActivityPagedResponse<Activity>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Activity.fromJson(json),
      );

      final cacheKey = '${_activitiesCacheKeyPrefix}$page\_$size';
      await _saveToCache(cacheKey, jsonResponse);

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getAllActivities: $e');
      }
      rethrow;
    }
  }

  Future<ActivityPagedResponse<Activity>> searchActivities(
    ActivitySearchRequestDTO searchRequest, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateSearchCacheKey(searchRequest);

    if (!forceRefresh) {
      final cached = await _loadFromCache(
        cacheKey,
        (json) => ActivityPagedResponse<Activity>.fromJson(
          json,
          (itemJson) => Activity.fromJson(itemJson),
        ),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint');
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      final queryParams = <String, String>{};

      if (searchRequest.query != null && searchRequest.query!.isNotEmpty) {
        queryParams['query'] = searchRequest.query!;
      }

      if (searchRequest.categoryIds != null &&
          searchRequest.categoryIds!.isNotEmpty) {
        queryParams['categoryIds'] = searchRequest.categoryIds!.join(',');
      }

      if (searchRequest.types != null && searchRequest.types!.isNotEmpty) {
        queryParams['types'] = searchRequest.types!.join(',');
      }

      if (searchRequest.difficultyLevels != null &&
          searchRequest.difficultyLevels!.isNotEmpty) {
        queryParams['difficultyLevels'] = searchRequest.difficultyLevels!.join(
          ',',
        );
      }

      if (searchRequest.minDurationSeconds != null) {
        queryParams['minDuration'] = searchRequest.minDurationSeconds!
            .toString();
      }

      if (searchRequest.maxDurationSeconds != null) {
        queryParams['maxDuration'] = searchRequest.maxDurationSeconds!
            .toString();
      }

      if (searchRequest.completedOnly != null) {
        queryParams['completedOnly'] = searchRequest.completedOnly!.toString();
      }

      if (searchRequest.favoriteOnly != null) {
        queryParams['favoriteOnly'] = searchRequest.favoriteOnly!.toString();
      }

      if (searchRequest.bookmarkedOnly != null) {
        queryParams['bookmarkedOnly'] = searchRequest.bookmarkedOnly!
            .toString();
      }

      if (searchRequest.newOnly != null) {
        queryParams['newOnly'] = searchRequest.newOnly!.toString();
      }

      if (searchRequest.popularOnly != null) {
        queryParams['popularOnly'] = searchRequest.popularOnly!.toString();
      }

      queryParams['page'] = searchRequest.page.toString();
      queryParams['size'] = searchRequest.size.toString();
      queryParams['sortBy'] = searchRequest.sortBy;
      queryParams['sortDirection'] = searchRequest.sortDirection;

      final finalUrl = url.replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('📤 GET $finalUrl');
      }

      final response = await http.get(finalUrl, headers: headers);

      if (response.statusCode >= 400) {
        if (kDebugMode) {
          print('❌ Status code: ${response.statusCode}');
          print('❌ Response body: ${response.body}');
        }
        throw Exception('Erreur recherche activités: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      final result = ActivityPagedResponse<Activity>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Activity.fromJson(json),
      );

      await _saveToCache(cacheKey, jsonResponse);

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur searchActivities: $e');
      }
      rethrow;
    }
  }

  String _generateSearchCacheKey(ActivitySearchRequestDTO request) {
    final parts = <String>[];
    parts.add('page_${request.page}');
    parts.add('size_${request.size}');
    if (request.query != null) parts.add('q_${request.query}');
    if (request.categoryIds != null)
      parts.add('cat_${request.categoryIds!.join('_')}');
    if (request.difficultyLevels != null)
      parts.add('dif_${request.difficultyLevels!.join('_')}');
    if (request.minDurationSeconds != null)
      parts.add('min_${request.minDurationSeconds}');
    if (request.maxDurationSeconds != null)
      parts.add('max_${request.maxDurationSeconds}');
    if (request.completedOnly == true) parts.add('completed');
    if (request.favoriteOnly == true) parts.add('favorite');
    if (request.newOnly == true) parts.add('new');
    if (request.popularOnly == true) parts.add('popular');
    parts.add('sort_${request.sortBy}_${request.sortDirection}');

    return 'search_' + parts.join('_');
  }

  Future<Activity> getActivityById(int id, {bool forceRefresh = false}) async {
    final cacheKey = '${_activityDetailCacheKeyPrefix}$id';

    if (!forceRefresh) {
      final cached = await _loadFromCache(
        cacheKey,
        (json) => Activity.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 404) {
        throw Exception('Activité non trouvée');
      }

      if (response.statusCode >= 400) {
        throw Exception('Erreur récupération activité: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final activity = Activity.fromJson(jsonResponse as Map<String, dynamic>);

      await _saveToCache(cacheKey, jsonResponse);
      _precacheActivityMedia(activity);

      return activity;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getActivityById: $e');
      }
      rethrow;
    }
  }

  Future<List<Activity>> getRecommendedActivities(
    int limit, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _loadListFromCache(
        _recommendedActivitiesCacheKey,
        (json) => Activity.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/recommended?limit=$limit',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération recommandations: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      List<Activity> activities = [];
      if (jsonResponse is List<dynamic>) {
        activities = jsonResponse
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();

        await _saveToCache(
          _recommendedActivitiesCacheKey,
          jsonResponse.map((e) => e).toList(),
        );

        for (var activity in activities) {
          _precacheActivityMedia(activity);
        }
      }

      return activities;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getRecommendedActivities: $e');
      }
      rethrow;
    }
  }

  Future<List<Activity>> getPopularActivities(
    int limit, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _loadListFromCache(
        _popularActivitiesCacheKey,
        (json) => Activity.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/popular?limit=$limit',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération activités populaires: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      List<Activity> activities = [];
      if (jsonResponse is List<dynamic>) {
        activities = jsonResponse
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();

        await _saveToCache(
          _popularActivitiesCacheKey,
          jsonResponse.map((e) => e).toList(),
        );

        for (var activity in activities) {
          _precacheActivityMedia(activity);
        }
      }

      return activities;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getPopularActivities: $e');
      }
      rethrow;
    }
  }

  Future<List<Activity>> getNewActivities(
    int limit, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _loadListFromCache(
        _newActivitiesCacheKey,
        (json) => Activity.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/new?limit=$limit',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération nouvelles activités: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      List<Activity> activities = [];
      if (jsonResponse is List<dynamic>) {
        activities = jsonResponse
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();

        await _saveToCache(
          _newActivitiesCacheKey,
          jsonResponse.map((e) => e).toList(),
        );

        for (var activity in activities) {
          _precacheActivityMedia(activity);
        }
      }

      return activities;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getNewActivities: $e');
      }
      rethrow;
    }
  }

  Future<List<ActivityCategory>> getCategories({
    bool? activeOnly,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _loadListFromCache(
        _categoriesCacheKey,
        (json) => ActivityCategory.fromJson(json),
      );
      if (cached != null) {
        if (activeOnly == true) {
          return cached.where((c) => c.isActive).toList();
        }
        return cached;
      }
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/categories');
      final queryParams = <String, String>{};

      if (activeOnly != null) {
        queryParams['activeOnly'] = activeOnly.toString();
      }

      final finalUrl = url.replace(queryParameters: queryParams);
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $finalUrl');
      }

      final response = await http.get(finalUrl, headers: headers);

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération catégories: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      List<ActivityCategory> categories = [];
      if (jsonResponse is List<dynamic>) {
        for (var json in jsonResponse) {
          try {
            final category = ActivityCategory.fromJson(
              json as Map<String, dynamic>,
            );
            categories.add(category);
          } catch (e) {
            if (kDebugMode) {
              print('❌ Erreur parsing catégorie: $e');
            }
          }
        }

        await _saveToCache(
          _categoriesCacheKey,
          jsonResponse.map((e) => e).toList(),
        );

        return categories;
      }

      throw Exception('Format de réponse invalide pour les catégories');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getCategories: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStats({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _loadFromCache(_userStatsCacheKey, (json) => json);
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/stats');
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération statistiques: ${response.statusCode}',
        );
      }

      final jsonResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      await _saveToCache(_userStatsCacheKey, jsonResponse);

      return jsonResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getUserStats: $e');
      }
      rethrow;
    }
  }

  // ============ MÉTHODES D'ÉCRITURE ============

  // Met à jour une activité dans tous les caches de listes
  Future<void> _updateActivityInListCaches(Activity updatedActivity) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> cacheKeys = [
      // Recherche : toutes les clés commençant par 'cached_activities_page_'
      ...prefs.getKeys().where(
        (key) => key.startsWith(_activitiesCacheKeyPrefix),
      ),
      _recommendedActivitiesCacheKey,
      _popularActivitiesCacheKey,
      _newActivitiesCacheKey,
    ];
    for (final key in cacheKeys) {
      await _updateActivityInCacheList(prefs, key, updatedActivity);
    }
  }

  Future<void> _updateActivityInCacheList(
    SharedPreferences prefs,
    String key,
    Activity updatedActivity,
  ) async {
    final String? jsonString = prefs.getString(key);
    if (jsonString == null) return;
    try {
      final Map<String, dynamic> cacheMap = jsonDecode(jsonString);
      final data = cacheMap['data'];
      if (data is List) {
        bool changed = false;
        final newList = <dynamic>[];
        for (final item in data) {
          if (item is Map<String, dynamic> &&
              item['id'] == updatedActivity.id) {
            newList.add(updatedActivity.toJson());
            changed = true;
          } else {
            newList.add(item);
          }
        }
        if (changed) {
          cacheMap['data'] = newList;
          await prefs.setString(key, jsonEncode(cacheMap));
          if (kDebugMode) print('✅ Cache mis à jour pour $key');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur mise à jour cache $key: $e');
    }
  }

  /// Marquer une activité comme favorite
  Future<Activity> toggleFavorite(int activityId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$activityId/favorite',
      );
      final headers = await _getHeadersWithUserId();
      final response = await http.post(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur toggle favorite: $errorMsg');
      }

      final jsonResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      // Extraction de l'activité (comme pour start/complete)
      final activityJson = jsonResponse['activity'] as Map<String, dynamic>;
      final activity = Activity.fromJson(activityJson);
      await _updateActivityInListCaches(activity);
      await _invalidateListCaches(); // 👈 AJOUTER
      await _invalidateActivityCache(activityId);
      return activity;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur toggleFavorite: $e');
      rethrow;
    }
  }

  Future<Activity> rateActivity(
    int activityId,
    ActivityRatingRequestDTO request,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$activityId/rate',
      );
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur évaluation activité: $errorMsg');
      }

      final jsonResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      // La réponse est un UserActivityResponseDTO, extraire l'activité
      final activityJson = jsonResponse['activity'] as Map<String, dynamic>;
      final activity = Activity.fromJson(activityJson);

      await _invalidateActivityCache(activityId);
      await _invalidateUserStatsCache();
      await _updateActivityInListCaches(activity);
      await _invalidateListCaches();
      if (kDebugMode) {
        print('✅ Activité $activityId évaluée avec succès');
      }

      return activity;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur rateActivity: $e');
      rethrow;
    }
  }

  /// ✅ AJOUTÉ - Marquer une activité comme complétée
  Future<Activity> completeActivity(
    int activityId,
    ActivityProgressRequestDTO? request,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$activityId/complete',
      );
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 POST $url');
        if (request != null) {
          print('📤 Body: ${jsonEncode(request.toJson())}');
        }
      }

      final response = await http.post(
        url,
        headers: headers,
        body: request != null ? jsonEncode(request.toJson()) : '{}',
      );

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur completion activité: $errorMsg');
      }

      final jsonResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      // Extraction de l'objet activity de la réponse (format UserActivityResponseDTO)
      final activityJson = jsonResponse['activity'] as Map<String, dynamic>;
      final activity = Activity.fromJson(activityJson);

      // Invalider les caches
      await _updateActivityInListCaches(activity);
      await _invalidateListCaches(); // 👈 AJOUTER
      await _invalidateActivityCache(activityId);

      if (kDebugMode) {
        print('✅ Activité $activityId marquée comme complétée');
      }

      return activity;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur completeActivity: $e');
      }
      rethrow;
    }
  }

  // Invalide tous les caches liés aux listes d'activités
  Future<void> _invalidateListCaches() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_activitiesCacheKeyPrefix) ||
          key == _recommendedActivitiesCacheKey ||
          key == _popularActivitiesCacheKey ||
          key == _newActivitiesCacheKey ||
          key == _categoriesCacheKey) {
        await prefs.remove(key);
      }
    }
    if (kDebugMode) print('🗑️ Caches des listes d\'activités invalidés');
  }

  /// ✅ AJOUTÉ - Démarrer une activité
  Future<Activity> startActivity(
    int activityId,
    ActivityProgressRequestDTO? request,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$activityId/start',
      );
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      final response = await http.post(
        url,
        headers: headers,
        body: request != null ? jsonEncode(request.toJson()) : '{}',
      );

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur démarrage activité: $errorMsg');
      }

      final jsonResponse =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      // 🔥 Extraire l'activité de la réponse
      final activityJson = jsonResponse['activity'] as Map<String, dynamic>;
      final activity = Activity.fromJson(activityJson);

      await _invalidateActivityCache(activityId);
      await _invalidateUserStatsCache();

      return activity;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur startActivity: $e');
      rethrow;
    }
  }

  // ============ INVALIDATION DE CACHE ============

  Future<void> _invalidateActivityCache(int activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_activityDetailCacheKeyPrefix}$activityId';
      await prefs.remove(cacheKey);
      if (kDebugMode) print('🗑️ Cache activité $activityId invalidé');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur invalidation cache activité: $e');
    }
  }

  Future<void> _invalidateUserStatsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userStatsCacheKey);
      if (kDebugMode) print('🗑️ Cache stats utilisateur invalidé');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur invalidation cache stats: $e');
    }
  }

  Future<void> _invalidateAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_activitiesCacheKeyPrefix) ||
            key == _popularActivitiesCacheKey ||
            key == _newActivitiesCacheKey ||
            key == _recommendedActivitiesCacheKey ||
            key == _categoriesCacheKey) {
          await prefs.remove(key);
        }
      }

      if (kDebugMode) print('🗑️ Tous les caches activités invalidés');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur invalidation tous caches: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith('cached_activity_') ||
            key.startsWith('cached_activities_page_') ||
            key == _popularActivitiesCacheKey ||
            key == _newActivitiesCacheKey ||
            key == _recommendedActivitiesCacheKey ||
            key == _categoriesCacheKey ||
            key == _userStatsCacheKey) {
          await prefs.remove(key);
        }
      }

      await _mediaCache.clearAllCache();

      if (kDebugMode) print('🧹 Cache activités complètement vidé');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur nettoyage cache: $e');
    }
  }

  // ============ UTILITAIRES ============

  String _parseErrorMessage(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return 'Réponse vide du serveur';
      }

      final jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ??
            jsonBody['error'] ??
            jsonBody['detail'] ??
            'Erreur serveur (${response.statusCode})';
      }
      return 'Erreur: ${response.statusCode}';
    } catch (e) {
      if (response.body.length > 200) {
        return 'Erreur: ${response.body.substring(0, 200)}...';
      }
      return 'Erreur: ${response.body}';
    }
  }

  // ============ CRÉATION D'ACTIVITÉ (ADMIN/CONTENT CREATOR) ============

  /// Créer une nouvelle activité (admin/content creator only)
  Future<Activity> createActivity(ActivityRequestDTO request) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint');
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 POST $url');
        print('📤 Body: ${jsonEncode(request.toJson())}');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur création activité: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final activity = Activity.fromJson(jsonResponse as Map<String, dynamic>);

      // Invalider les caches pertinents car une nouvelle activité a été ajoutée
      await _invalidateAllCaches();

      // Précharger les médias de la nouvelle activité
      _precacheActivityMedia(activity);

      if (kDebugMode) {
        print(
          '✅ Activité créée avec succès: ${activity.id} - ${activity.title}',
        );
      }

      return activity;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur createActivity: $e');
      }
      rethrow;
    }
  }

  /// Mettre à jour une activité existante (admin/content creator only)
  Future<Activity> updateActivity(int id, ActivityRequestDTO request) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 PUT $url');
        print('📤 Body: ${jsonEncode(request.toJson())}');
      }

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur mise à jour activité: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final activity = Activity.fromJson(jsonResponse as Map<String, dynamic>);

      // Invalider les caches
      await _invalidateAllCaches();
      await _invalidateActivityCache(id);

      if (kDebugMode) {
        print('✅ Activité mise à jour: $id - ${activity.title}');
      }

      return activity;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur updateActivity: $e');
      }
      rethrow;
    }
  }

  /// Supprimer une activité (soft delete, admin only)
  Future<void> deleteActivity(int id) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$id');
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 DELETE $url');
      }

      final response = await http.delete(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur suppression activité: $errorMsg');
      }

      // Invalider les caches
      await _invalidateAllCaches();
      await _invalidateActivityCache(id);

      if (kDebugMode) {
        print('✅ Activité supprimée: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur deleteActivity: $e');
      }
      rethrow;
    }
  }
}
