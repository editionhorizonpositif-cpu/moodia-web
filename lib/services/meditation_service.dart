import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meditation.dart';
import '../models/paged_response.dart';
import 'api_service.dart';
import 'media_cache_service.dart';

class MeditationService {
  final ApiService _apiService;
  final MediaCacheService _cacheService = MediaCacheService();
  static const String _baseEndpoint = 'meditations';

  final Map<int, String> _mediaTypeCache = {};
  final Set<int> _completingMeditations = {};
  final Map<int, List<int>> _downloadingMedia = {};

  MeditationService(this._apiService);

  Future<void> initialize() async {
    await _cacheService.initialize();
  }

  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
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

      if (kDebugMode) {
        print('👤 Utilisation du userId: $userId');
      }
      return await _apiService.getHeadersWithUserId(userId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _getHeadersWithUserId: $e');
      }
      return await _apiService.getHeaders();
    }
  }

  // ============ OBTENTION D'URL PRÉ-SIGNÉES ============

  /// Récupère l'URL pré-signée pour un endpoint donné (stream, download, lottie)
  Future<String> _getPresignedUrl(int assetId, String endpoint) async {
    final url = Uri.parse('${ApiService.baseUrl}/media/$assetId/$endpoint');
    final headers = await _getHeadersWithUserId();

    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Impossible d\'obtenir l\'URL $endpoint (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body);
    return json['url'] as String;
  }

  /// Retourne l'URL de streaming (pour lecture en ligne)
  Future<String> getStreamUrl(int assetId) async {
    try {
      return await _getPresignedUrl(assetId, 'stream');
    } catch (e) {
      if (kDebugMode) print('❌ getStreamUrl error: $e');
      // URL de fallback (exemple)
      return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    }
  }

  /// Retourne l'URL de téléchargement (pour cache)
  Future<String> getDownloadUrl(int assetId) async {
    try {
      return await _getPresignedUrl(assetId, 'download');
    } catch (e) {
      if (kDebugMode) print('❌ getDownloadUrl error: $e');
      return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    }
  }

  // ============ TÉLÉCHARGEMENT POUR CACHE ============

  Future<bool> downloadAndCacheMedia(int assetId, String mediaType) async {
    if (_downloadingMedia.containsKey(assetId)) {
      if (kDebugMode) print('⏳ Téléchargement déjà en cours pour $assetId');
      return false;
    }
    _downloadingMedia[assetId] = [0];

    try {
      final presignedUrl = await getDownloadUrl(assetId);
      final request = http.Request('GET', Uri.parse(presignedUrl));
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        throw Exception('Échec téléchargement: ${streamedResponse.statusCode}');
      }

      final contentLength = streamedResponse.contentLength ?? 0;

      await _cacheService.cacheMedia(
        assetId: assetId,
        mediaType: mediaType,
        mediaUrl: presignedUrl,
        stream: streamedResponse.stream,
        contentLength: contentLength,
      );

      if (kDebugMode) {
        print('✅ Média $assetId téléchargé et mis en cache');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur downloadAndCacheMedia: $e');
      return false;
    } finally {
      _downloadingMedia.remove(assetId);
    }
  }

  // ============ LOTTIE ============

  Future<String?> getLottieContent(int assetId) async {
    final cached = await _cacheService.readLottieContent(assetId);
    if (cached != null) return cached;

    try {
      final presignedUrl = await _getPresignedUrl(assetId, 'lottie');
      final response = await http.get(Uri.parse(presignedUrl));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        await _cacheService.cacheLottieMedia(
          assetId: assetId,
          content: content,
          mediaUrl: presignedUrl,
        );
        return content;
      }
    } catch (e) {
      if (kDebugMode) print('❌ getLottieContent error: $e');
    }
    return null;
  }

  // ============ AUTRES MÉTHODES (inchangées) ============

  Future<String> getMediaType(int assetId) async {
    if (_mediaTypeCache.containsKey(assetId)) {
      return _mediaTypeCache[assetId]!;
    }

    try {
      final url = Uri.parse('${ApiService.baseUrl}/media/$assetId');
      final headers = await _getHeadersWithUserId();

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        String mediaType = 'AUDIO';

        final mediaTypeStr = jsonData['mediaType']?.toString().toUpperCase();
        if (mediaTypeStr == 'AUDIO' || mediaTypeStr == 'VIDEO') {
          mediaType = mediaTypeStr!;
        } else {
          final mimeType = jsonData['mimeType']?.toString().toLowerCase() ?? '';
          if (mimeType.startsWith('audio/')) {
            mediaType = 'AUDIO';
          } else if (mimeType.startsWith('video/')) {
            mediaType = 'VIDEO';
          }
        }

        _mediaTypeCache[assetId] = mediaType;
        return mediaType;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur récupération type média $assetId: $e');
      }
    }

    return 'AUDIO';
  }

  Future<PagedResponse<Meditation>> getMeditationsPaginated({
    int page = 0,
    int size = 20,
    String sort = 'displayOrder,asc',
    int retryCount = 0,
  }) async {
    final maxRetries = 2;

    try {
      final response = await _apiService.safeRequest(
        method: 'GET',
        path: '/$_baseEndpoint?page=$page&size=$size&sort=$sort',
      );

      if (response.statusCode >= 400) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return PagedResponse<Meditation>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => Meditation.fromJson(json),
      );
    } catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        return getMeditationsPaginated(
          page: page,
          size: size,
          sort: sort,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }

  Future<void> markAsCompleted(int meditationId) async {
    if (_completingMeditations.contains(meditationId)) return;

    _completingMeditations.add(meditationId);

    try {
      // Get headers with Authorization and X-User-Id
      final headers = await _getHeadersWithUserId();
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$meditationId/complete',
      );

      final response = await http.post(url, headers: headers);

      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
        print('📡 Response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      if (response.statusCode == 409) return; // Already completed

      throw Exception('Erreur markAsCompleted: ${response.statusCode}');
    } catch (e) {
      rethrow;
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _completingMeditations.remove(meditationId);
      });
    }
  }

  Future<Meditation> getMeditationById(int id) async {
    final response = await _apiService.safeRequest(
      method: 'GET',
      path: '/$_baseEndpoint/$id',
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    return Meditation.fromJson(jsonResponse as Map<String, dynamic>);
  }

  Future<List<Meditation>> getMeditations({
    int page = 0,
    int size = 20,
    String sort = 'displayOrder,asc',
  }) async {
    final pagedResponse = await getMeditationsPaginated(
      page: page,
      size: size,
      sort: sort,
    );
    return pagedResponse.content;
  }

  // Ancienne méthode getMediaUrl supprimée – utiliser getStreamUrl / getDownloadUrl

  Future<void> precacheMeditations(List<Meditation> meditations) async {
    int queued = 0;
    for (final meditation in meditations) {
      if (meditation.audioVideoAssetId != null) {
        final isCached = await _cacheService.isCached(
          meditation.audioVideoAssetId!,
        );

        if (!isCached) {
          final mediaType = await getMediaType(meditation.audioVideoAssetId!);
          downloadAndCacheMedia(meditation.audioVideoAssetId!, mediaType)
              .then((success) {
                if (success && kDebugMode) {
                  print('✅ Préchargement terminé: ${meditation.title}');
                }
              })
              .catchError((e) {
                if (kDebugMode) {
                  print('⚠️ Échec préchargement ${meditation.title}: $e');
                }
              });
          queued++;
        }
      }
    }
    if (kDebugMode && queued > 0) {
      print('📥 $queued médias ajoutés à la file de téléchargement');
    }
  }

  Future<List<int>?> getMediaContent(int assetId) async {
    final cached = await _cacheService.readMediaContent(assetId);
    if (cached != null) return cached;

    try {
      final mediaType = await getMediaType(assetId);
      final success = await downloadAndCacheMedia(assetId, mediaType);
      if (success) {
        return await _cacheService.readMediaContent(assetId);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getMediaContent: $e');
    }
    return null;
  }

  Future<bool> isMediaCached(int assetId) async {
    return await _cacheService.isCached(assetId);
  }

  Future<String?> getCachedMediaPath(int assetId) async {
    return await _cacheService.getMediaPath(assetId);
  }

  Future<void> deleteCachedMedia(int assetId) async {
    await _cacheService.deleteMedia(assetId);
  }

  Future<void> clearCache() async {
    await _cacheService.clearAllCache();
    _mediaTypeCache.clear();
    _completingMeditations.clear();
    _downloadingMedia.clear();
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'size': await _cacheService.getCacheSize(),
      'count': await _cacheService.getCachedCount(),
    };
  }

  Future<Meditation> createMeditation(
    MeditationCreateRequest request,
    int userId,
  ) async {
    final response = await _apiService.safeRequest(
      method: 'POST',
      path: '/$_baseEndpoint',
      body: jsonEncode(request.toJson()),
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    return Meditation.fromJson(jsonResponse as Map<String, dynamic>);
  }

  Future<Meditation> updateMeditation(
    int id,
    MeditationUpdateRequest request,
  ) async {
    final response = await _apiService.safeRequest(
      method: 'PUT',
      path: '/$_baseEndpoint/$id',
      body: jsonEncode(request.toJson()),
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    return Meditation.fromJson(jsonResponse as Map<String, dynamic>);
  }

  Future<void> deleteMeditation(int id) async {
    await _apiService.safeRequest(
      method: 'DELETE',
      path: '/$_baseEndpoint/$id',
    );
  }

  Future<List<Meditation>> searchMeditations(
    String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiService.safeRequest(
      method: 'GET',
      path: '/$_baseEndpoint/search?keyword=$keyword&page=$page&size=$size',
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

    if (jsonResponse is Map<String, dynamic> &&
        jsonResponse.containsKey('content')) {
      final content = jsonResponse['content'] as List<dynamic>;
      return content
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (jsonResponse is List) {
      return jsonResponse
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Meditation>> getMeditationsByCategory(
    String category, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiService.safeRequest(
      method: 'GET',
      path: '/$_baseEndpoint/category/$category?page=$page&size=$size',
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

    if (jsonResponse is Map<String, dynamic> &&
        jsonResponse.containsKey('content')) {
      final content = jsonResponse['content'] as List<dynamic>;
      return content
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (jsonResponse is List) {
      return jsonResponse
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Meditation>> getMeditationsByDifficulty(
    String difficultyLevel, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiService.safeRequest(
      method: 'GET',
      path: '/$_baseEndpoint/difficulty/$difficultyLevel?page=$page&size=$size',
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

    if (jsonResponse is Map<String, dynamic> &&
        jsonResponse.containsKey('content')) {
      final content = jsonResponse['content'] as List<dynamic>;
      return content
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (jsonResponse is List) {
      return jsonResponse
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Meditation>> getPremiumMeditations({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _apiService.safeRequest(
      method: 'GET',
      path: '/$_baseEndpoint/premium?page=$page&size=$size',
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

    if (jsonResponse is Map<String, dynamic> &&
        jsonResponse.containsKey('content')) {
      final content = jsonResponse['content'] as List<dynamic>;
      return content
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (jsonResponse is List) {
      return jsonResponse
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Meditation> rateMeditation(int meditationId, double rating) async {
    final response = await _apiService.safeRequest(
      method: 'POST',
      path: '/$_baseEndpoint/$meditationId/rate?rating=$rating',
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    return Meditation.fromJson(jsonResponse as Map<String, dynamic>);
  }

  Future<Meditation> changeStatus(int meditationId, String status) async {
    final response = await _apiService.safeRequest(
      method: 'PATCH',
      path: '/$_baseEndpoint/$meditationId/status?status=$status',
    );

    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    return Meditation.fromJson(jsonResponse as Map<String, dynamic>);
  }

  Future<int> getCompletedTodayCount(int userId) async {
    try {
      final response = await _apiService.safeRequest(
        method: 'GET',
        path: '/$_baseEndpoint/completed/today?userId=$userId',
      );

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is int) return json;
      if (json is Map && json.containsKey('count')) return json['count'] as int;
      return 0;
    } catch (e) {
      debugPrint('❌ Erreur getCompletedTodayCount: $e');
      return 0;
    }
  }

  void clearMemoryCache() {
    _mediaTypeCache.clear();
    _completingMeditations.clear();
    _downloadingMedia.clear();
    _cacheService.clearMemoryCache();
  }
}
