import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import 'api_service.dart';

class JournalApiService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'v1/journal';

  // Clés de cache
  static const String _entriesCacheKeyPrefix = 'journal_entries_page_';
  static const String _entryCacheKeyPrefix = 'journal_entry_';
  static const String _statsCacheKeyPrefix = 'journal_stats_';
  static const String _tagsCacheKeyPrefix = 'journal_tags_';
  static const String _streakCacheKeyPrefix = 'journal_streak_';
  static const String _entriesByTagCacheKeyPrefix = 'journal_by_tag_';
  static const String _entriesByTypeCacheKeyPrefix = 'journal_by_type_';
  static const String _entriesByDateRangeCacheKeyPrefix = 'journal_by_date_';

  // Durée de validité du cache (24 heures)
  static const int _cacheValidityDuration = 24 * 60 * 60 * 1000;

  JournalApiService() : _apiService = ApiService();

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
      if (cachedJson == null) return null;

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
      if (cachedJson == null) return null;

      final Map<String, dynamic> cacheMap = jsonDecode(cachedJson);
      final timestamp = cacheMap['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp < _cacheValidityDuration) {
        final dataList = cacheMap['data'] as List?;
        if (dataList != null) {
          final items = dataList
              .map((e) => fromJson(e as Map<String, dynamic>))
              .toList();
          if (kDebugMode)
            print('✅ Liste chargée depuis cache: $key (${items.length} items)');
          return items;
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement liste cache: $e');
    }
    return null;
  }

  Future<JournalEntriesPage?> _loadEntriesPageFromCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) return null;

      final Map<String, dynamic> cacheMap = jsonDecode(cachedJson);
      final timestamp = cacheMap['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp < _cacheValidityDuration) {
        final data = cacheMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          final content = (data['content'] ?? data['data'] ?? []) as List;
          final entries = content
              .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          final page = data['page'] ?? 0;
          final size = data['size'] ?? 20;
          final totalElements = data['totalElements'] ?? entries.length;
          final totalPages = data['totalPages'] ?? 1;
          final isLast = data['last'] ?? true;

          final pageResult = JournalEntriesPage(
            entries: entries,
            page: page,
            size: size,
            totalElements: totalElements,
            totalPages: totalPages,
            isLast: isLast,
          );
          if (kDebugMode) print('✅ Page chargée depuis cache: $cacheKey');
          return pageResult;
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement page cache: $e');
    }
    return null;
  }

  Future<void> _invalidateUserCache(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final toRemove = <String>[];
      for (final key in keys) {
        if (key.startsWith(_entriesCacheKeyPrefix) ||
            key.startsWith(_statsCacheKeyPrefix) ||
            key.startsWith(_tagsCacheKeyPrefix) ||
            key.startsWith(_streakCacheKeyPrefix) ||
            key.startsWith(_entriesByTagCacheKeyPrefix) ||
            key.startsWith(_entriesByTypeCacheKeyPrefix) ||
            key.startsWith(_entriesByDateRangeCacheKeyPrefix)) {
          toRemove.add(key);
        }
      }
      for (final key in toRemove) {
        await prefs.remove(key);
      }
      if (kDebugMode) print('🗑️ Cache utilisateur $userId invalidé');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur invalidation cache: $e');
    }
  }

  Future<void> _invalidateEntryCache(String entryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_entryCacheKeyPrefix$entryId');
      // Invalider aussi les pages
      await _invalidateAllPagesCache();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur invalidation entrée: $e');
    }
  }

  Future<void> _invalidateAllPagesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_entriesCacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
      if (kDebugMode) print('🗑️ Pages de journal invalidées');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur invalidation pages: $e');
    }
  }

  // ============ MÉTHODES POUR LES HEADERS ============

  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ UserId non trouvé dans SharedPreferences');
        }
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
              return await _apiService.getHeadersWithUserId(
                extractedUserId as int,
              );
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

  // ============ MÉTHODES PRINCIPALES AVEC CACHE ============

  /// Créer une nouvelle entrée
  Future<JournalEntry> createEntry(
    CreateJournalEntryRequest request, {
    bool forceRefresh = false,
  }) async {
    try {
      if (kDebugMode) print('📝 DEBUT createEntry');

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID non disponible. Veuillez vous reconnecter.');
      }

      final body = request.toJson();
      body['userId'] = userId;

      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint');
      final headers = await _getHeadersWithUserId();
      headers['Content-Type'] = 'application/json';

      if (kDebugMode) {
        print('📤 POST $url');
        print('📤 Body: ${jsonEncode(body)}');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) print('📥 Status: ${response.statusCode}');

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur création entrée: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final entry = JournalEntry.fromJson(jsonResponse);

      // Invalider les caches après création
      await _invalidateUserCache(userId);

      return entry;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur createEntry: $e');
      rethrow;
    }
  }

  /// Récupérer une entrée par ID
  Future<JournalEntry> getEntryById(
    String id,
    int userId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$_entryCacheKeyPrefix$id';

    if (!forceRefresh) {
      final cached = await _loadFromCache(
        cacheKey,
        (json) => JournalEntry.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$id?userId=$userId',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('📤 GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération entrée: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final entry = JournalEntry.fromJson(jsonResponse);

      // Mettre en cache
      await _saveToCache(cacheKey, jsonResponse);

      return entry;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getEntryById: $e');
      rethrow;
    }
  }

  /// Récupérer les entrées d'un utilisateur (paginated)
  Future<JournalEntriesPage> getUserEntries({
    required int userId,
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '${_entriesCacheKeyPrefix}user_${userId}_page${page}_size${size}_sort${sort.replaceAll(',', '_')}';

    if (!forceRefresh) {
      final cached = await _loadEntriesPageFromCache(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/user/$userId')
          .replace(
            queryParameters: {
              'page': page.toString(),
              'size': size.toString(),
              'sort': sort,
            },
          );

      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('📤 GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération entrées: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      JournalEntriesPage result;
      if (jsonResponse is Map<String, dynamic>) {
        final content =
            (jsonResponse['content'] ?? jsonResponse['data'] ?? [])
                as List<dynamic>;
        final totalElements = jsonResponse['totalElements'] ?? content.length;
        final totalPages = jsonResponse['totalPages'] ?? 1;
        final isLast = jsonResponse['last'] ?? true;

        final entries = content
            .map((json) => JournalEntry.fromJson(json as Map<String, dynamic>))
            .toList();

        result = JournalEntriesPage(
          entries: entries,
          page: page,
          size: size,
          totalElements: totalElements,
          totalPages: totalPages,
          isLast: isLast,
        );

        // Mettre en cache
        await _saveToCache(cacheKey, jsonResponse);
      } else {
        throw Exception('Format de réponse invalide');
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserEntries: $e');
      rethrow;
    }
  }

  /// Rechercher dans les entrées
  Future<JournalEntriesPage> searchEntries({
    required int userId,
    required String keyword,
    int page = 0,
    int size = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '${_entriesCacheKeyPrefix}search_${userId}_${keyword}_page${page}_size${size}';

    if (!forceRefresh) {
      final cached = await _loadEntriesPageFromCache(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final url =
          Uri.parse(
            '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/search',
          ).replace(
            queryParameters: {
              'keyword': keyword,
              'page': page.toString(),
              'size': size.toString(),
            },
          );

      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('🔍 GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur recherche: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      JournalEntriesPage result;
      if (jsonResponse is Map<String, dynamic>) {
        final content =
            (jsonResponse['content'] ?? jsonResponse['data'] ?? [])
                as List<dynamic>;
        final totalElements = jsonResponse['totalElements'] ?? content.length;
        final totalPages = jsonResponse['totalPages'] ?? 1;
        final isLast = jsonResponse['last'] ?? true;

        final entries = content
            .map((json) => JournalEntry.fromJson(json as Map<String, dynamic>))
            .toList();

        result = JournalEntriesPage(
          entries: entries,
          page: page,
          size: size,
          totalElements: totalElements,
          totalPages: totalPages,
          isLast: isLast,
        );

        // Mettre en cache
        await _saveToCache(cacheKey, jsonResponse);
      } else {
        throw Exception('Format de réponse invalide');
      }

      return result;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur searchEntries: $e');
      rethrow;
    }
  }

  /// Mettre à jour une entrée
  Future<JournalEntry> updateEntry({
    required String id,
    required int userId,
    required UpdateJournalEntryRequest request,
    bool forceRefresh = false,
  }) async {
    try {
      if (kDebugMode) print('✏️ DEBUT updateEntry: $id');

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$id?userId=$userId',
      );
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

      if (kDebugMode) print('📥 Status: ${response.statusCode}');

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur mise à jour: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final entry = JournalEntry.fromJson(jsonResponse);

      // Invalider les caches après mise à jour
      await _invalidateEntryCache(id);
      await _invalidateUserCache(userId);

      return entry;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateEntry: $e');
      rethrow;
    }
  }

  /// Supprimer une entrée
  Future<void> deleteEntry(String id, int userId) async {
    try {
      if (kDebugMode) print('🗑️ DEBUT deleteEntry: $id');

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$id?userId=$userId',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('📤 DELETE $url');

      final response = await http.delete(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur suppression: $errorMsg');
      }

      if (kDebugMode) print('✅ Entrée supprimée avec succès');

      // Invalider les caches après suppression
      await _invalidateEntryCache(id);
      await _invalidateUserCache(userId);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur deleteEntry: $e');
      rethrow;
    }
  }

  /// Récupérer les statistiques
  Future<JournalStatistics> getStatistics(
    int userId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${_statsCacheKeyPrefix}$userId';

    if (!forceRefresh) {
      final cached = await _loadFromCache(
        cacheKey,
        (json) => JournalStatistics.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/statistics',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('📊 GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération statistiques: $errorMsg');
      }

      if (kDebugMode) print('📥 JSON Response: ${response.body}');

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final stats = JournalStatistics.fromJson(jsonResponse);

      // Mettre en cache
      await _saveToCache(cacheKey, jsonResponse);

      return stats;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getStatistics: $e');
      rethrow;
    }
  }

  /// Récupérer tous les tags d'un utilisateur
  Future<List<String>> getUserTags(
    int userId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${_tagsCacheKeyPrefix}$userId';

    if (!forceRefresh) {
      final cached = await _loadListFromCache(
        cacheKey,
        (json) => json as String? ?? '',
      );
      if (cached != null) return cached.cast<String>();
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/tags',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('🏷️ GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération tags: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      List<String> tags = [];
      if (jsonResponse is List) {
        tags = jsonResponse.map((e) => e.toString()).toList();
      }

      // Mettre en cache
      await _saveToCache(cacheKey, tags);

      return tags;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserTags: $e');
      return [];
    }
  }

  /// Récupérer les entrées par tag
  Future<List<JournalEntry>> getEntriesByTag(
    int userId,
    String tag, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${_entriesByTagCacheKeyPrefix}${userId}_${tag}';

    if (!forceRefresh) {
      final cached = await _loadListFromCache(
        cacheKey,
        (json) => JournalEntry.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/tag/${Uri.encodeComponent(tag)}',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('🏷️ GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération par tag: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      List<JournalEntry> entries = [];
      if (jsonResponse is List) {
        entries = jsonResponse
            .map((json) => JournalEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Mettre en cache
      await _saveToCache(cacheKey, jsonResponse);

      return entries;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getEntriesByTag: $e');
      return [];
    }
  }

  /// Récupérer les entrées par type
  Future<List<JournalEntry>> getEntriesByType(
    int userId,
    String type, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${_entriesByTypeCacheKeyPrefix}${userId}_${type}';

    if (!forceRefresh) {
      final cached = await _loadListFromCache(
        cacheKey,
        (json) => JournalEntry.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/type/${Uri.encodeComponent(type)}',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('📁 GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération par type: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      List<JournalEntry> entries = [];
      if (jsonResponse is List) {
        entries = jsonResponse
            .map((json) => JournalEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Mettre en cache
      await _saveToCache(cacheKey, jsonResponse);

      return entries;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getEntriesByType: $e');
      return [];
    }
  }

  /// Récupérer la série actuelle
  Future<int> getCurrentStreak(int userId, {bool forceRefresh = false}) async {
    final cacheKey = '${_streakCacheKeyPrefix}$userId';

    if (!forceRefresh) {
      final cached = await _loadFromCache(
        cacheKey,
        (json) => json['streak'] as int? ?? 0,
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/streak',
      );
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('🔥 GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        int streak;
        if (json is int) {
          streak = json;
        } else if (json is Map && json.containsKey('streak')) {
          streak = json['streak'] as int;
        } else {
          streak = 0;
        }

        // Mettre en cache
        await _saveToCache(cacheKey, {'streak': streak});

        return streak;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Erreur getCurrentStreak: $e');
      return 0;
    }
  }

  /// Récupérer les entrées par plage de dates
  Future<List<JournalEntry>> getEntriesByDateRange({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
    bool forceRefresh = false,
  }) async {
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];
    final cacheKey =
        '${_entriesByDateRangeCacheKeyPrefix}${userId}_${start}_${end}';

    if (!forceRefresh) {
      final cached = await _loadListFromCache(
        cacheKey,
        (json) => JournalEntry.fromJson(json),
      );
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/user/$userId/date-range',
      ).replace(queryParameters: {'startDate': start, 'endDate': end});
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) print('📅 GET $url');

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception('Erreur récupération par date: $errorMsg');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      List<JournalEntry> entries = [];
      if (jsonResponse is List) {
        entries = jsonResponse
            .map((json) => JournalEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Mettre en cache
      await _saveToCache(cacheKey, jsonResponse);

      return entries;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getEntriesByDateRange: $e');
      return [];
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

  /// Supprime toutes les données de cache du journal dans SharedPreferences
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final toRemove = <String>[];
      for (final key in keys) {
        if (key.startsWith('journal_')) {
          toRemove.add(key);
        }
      }
      for (final key in toRemove) {
        await prefs.remove(key);
      }
      if (kDebugMode)
        print('🧹 JournalApiService : ${toRemove.length} clés supprimées');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur clearCache JournalApiService: $e');
    }
  }
}

class JournalEntriesPage {
  final List<JournalEntry> entries;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  JournalEntriesPage({
    required this.entries,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  bool get hasMore => !isLast && page < totalPages - 1;
}
