import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:flutter/foundation.dart';
import '../models/media.dart';
import '../models/paged_response.dart';
import 'api_service.dart';
import 'media_cache_service.dart';

class MediaService {
  final ApiService _apiService;
  final MediaCacheService _cacheService = MediaCacheService();
  static const String _baseEndpoint = 'media';

  MediaService(this._apiService);

  // ============ UPLOAD MÉTHODES ============

  Future<MediaUploadResponse> uploadMediaSimple(
    int userId,
    File file, {
    String? category,
    bool isPublic = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint');
      final request = http.MultipartRequest('POST', uri);

      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('Token non disponible. Veuillez vous reconnecter.');
      }

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-User-Id'] = userId.toString();

      final mimeTypeInfo = await _detectMimeTypeWithContent(file);
      final filename = file.path.split(Platform.pathSeparator).last;

      if (kDebugMode) {
        print('📤 Upload de: $filename');
        print('📤 Type: ${mimeTypeInfo.mediaType.mimeType}');
      }

      final filePart = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: filename,
        contentType: mimeTypeInfo.mediaType,
      );

      request.files.add(filePart);

      if (category != null && category.isNotEmpty) {
        request.fields['category'] = category;
      }
      request.fields['isPublic'] = isPublic.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur upload (${response.statusCode}): ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return MediaUploadResponse.fromJson(jsonResponse);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Erreur upload média: $e');
      }
      rethrow;
    }
  }

  Future<MediaUploadResponse> uploadLottieFile(
    int userId,
    File file, {
    String? category,
    bool isPublic = true,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.path.split(Platform.pathSeparator).last;

      return await uploadMediaBytes(
        userId,
        bytes,
        filename,
        category: category ?? 'ACTIVITY_LOTTIE',
        isPublic: isPublic,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur upload Lottie: $e');
      rethrow;
    }
  }

  Future<MediaUploadResponse> uploadMediaBytes(
    int userId,
    List<int> bytes,
    String filename, {
    required String category,
    bool isPublic = true,
  }) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint');
      final request = http.MultipartRequest('POST', uri);

      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-User-Id'] = userId.toString();

      final mimeTypeInfo = _detectMimeTypeFromBytes(bytes, filename);

      final filePart = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: mimeTypeInfo.mediaType,
      );

      request.files.add(filePart);

      if (category.isNotEmpty) {
        request.fields['category'] = category;
      }
      request.fields['isPublic'] = isPublic.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur upload (${response.statusCode}): ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return MediaUploadResponse.fromJson(jsonResponse);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur upload bytes: $e');
      rethrow;
    }
  }

  // ============ DÉTECTION MIME ============

  Future<MimeTypeInfo> _detectMimeTypeWithContent(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return _detectMimeTypeFromBytes(bytes, file.path);
    } catch (e) {
      return _detectMimeTypeFromPath(file.path);
    }
  }

  MimeTypeInfo _detectMimeTypeFromBytes(List<int> bytes, String path) {
    // Signatures de fichiers
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return MimeTypeInfo(http_parser.MediaType('image', 'png'), 'image');
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return MimeTypeInfo(http_parser.MediaType('image', 'jpeg'), 'image');
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return MimeTypeInfo(http_parser.MediaType('audio', 'mpeg'), 'audio');
    }

    // Détection JSON/Lottie
    final isJsonFile =
        path.toLowerCase().endsWith('.json') ||
        (bytes.length > 0 && (bytes[0] == 0x7B || bytes[0] == 0x5B));

    if (isJsonFile) {
      try {
        final content = utf8.decode(bytes);
        if (content.contains('"v"') &&
            content.contains('"fr"') &&
            content.contains('"layers"')) {
          return MimeTypeInfo(
            http_parser.MediaType('application', 'json'),
            'lottie',
          );
        }
        return MimeTypeInfo(
          http_parser.MediaType('application', 'json'),
          'document',
        );
      } catch (_) {}
    }

    return _detectMimeTypeFromPath(path);
  }

  MimeTypeInfo _detectMimeTypeFromPath(String path) {
    final lower = path.toLowerCase();

    // Images
    if (lower.endsWith('.png')) {
      return MimeTypeInfo(http_parser.MediaType('image', 'png'), 'image');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MimeTypeInfo(http_parser.MediaType('image', 'jpeg'), 'image');
    }
    if (lower.endsWith('.gif')) {
      return MimeTypeInfo(http_parser.MediaType('image', 'gif'), 'image');
    }
    if (lower.endsWith('.webp')) {
      return MimeTypeInfo(http_parser.MediaType('image', 'webp'), 'image');
    }

    // Audio
    if (lower.endsWith('.mp3')) {
      return MimeTypeInfo(http_parser.MediaType('audio', 'mpeg'), 'audio');
    }
    if (lower.endsWith('.wav')) {
      return MimeTypeInfo(http_parser.MediaType('audio', 'wav'), 'audio');
    }
    if (lower.endsWith('.ogg')) {
      return MimeTypeInfo(http_parser.MediaType('audio', 'ogg'), 'audio');
    }
    if (lower.endsWith('.m4a')) {
      return MimeTypeInfo(http_parser.MediaType('audio', 'mp4'), 'audio');
    }
    if (lower.endsWith('.flac')) {
      return MimeTypeInfo(http_parser.MediaType('audio', 'flac'), 'audio');
    }

    // Vidéo
    if (lower.endsWith('.mp4')) {
      return MimeTypeInfo(http_parser.MediaType('video', 'mp4'), 'video');
    }
    if (lower.endsWith('.webm')) {
      return MimeTypeInfo(http_parser.MediaType('video', 'webm'), 'video');
    }
    if (lower.endsWith('.mov')) {
      return MimeTypeInfo(http_parser.MediaType('video', 'quicktime'), 'video');
    }
    if (lower.endsWith('.avi')) {
      return MimeTypeInfo(http_parser.MediaType('video', 'avi'), 'video');
    }

    // Lottie
    if (lower.endsWith('.json') || lower.endsWith('.lottie')) {
      return MimeTypeInfo(
        http_parser.MediaType('application', 'json'),
        'lottie',
      );
    }

    return MimeTypeInfo(
      http_parser.MediaType('application', 'octet-stream'),
      'other',
    );
  }

  // ============ OBTENTION D'URL PRÉ-SIGNÉES ============

  /// Appelle l'endpoint /download et retourne l'URL pré-signée (pour téléchargement)
  Future<String> getDownloadUrl(int mediaId, int userId) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$mediaId/download',
      );
      final headers = await _getHeaders(userId);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur obtention URL download (${response.statusCode}): ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['url'] as String;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getDownloadUrl: $e');
      rethrow;
    }
  }

  /// Appelle l'endpoint /stream et retourne l'URL pré-signée (pour lecture)
  Future<String> getStreamUrl(int mediaId, int userId) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$mediaId/stream',
      );
      final headers = await _getHeaders(userId);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur obtention URL stream (${response.statusCode}): ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['url'] as String;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getStreamUrl: $e');
      rethrow;
    }
  }

  /// Appelle l'endpoint /lottie et retourne l'URL pré-signée (pour fichier Lottie)
  Future<String> getLottieUrl(int mediaId, int userId) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$mediaId/lottie',
      );
      final headers = await _getHeaders(userId);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur obtention URL Lottie (${response.statusCode}): ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['url'] as String;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getLottieUrl: $e');
      rethrow;
    }
  }

  // ============ TÉLÉCHARGEMENT ET CACHE ============

  /// Télécharge un fichier à partir d'une URL (généralement pré-signée) et le met en cache
  Future<CachedMediaInfo> downloadAndCacheMedia({
    required int assetId,
    required String mediaType,
    required String url,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode >= 400) {
        throw Exception(
          'Erreur téléchargement (${streamedResponse.statusCode})',
        );
      }

      final contentLength = streamedResponse.contentLength ?? 0;

      return await _cacheService.cacheMedia(
        assetId: assetId,
        mediaType: mediaType,
        mediaUrl: url,
        stream: streamedResponse.stream,
        contentLength: contentLength,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur downloadAndCacheMedia: $e');
      rethrow;
    }
  }

  /// Récupère le contenu Lottie (JSON) : soit depuis le cache, soit via l'URL pré-signée
  Future<String> getLottieContent(int mediaId, int userId) async {
    // Vérifier le cache
    final cached = await _cacheService.getCachedMedia(mediaId);
    if (cached != null && cached.mediaType == 'LOTTIE') {
      final content = await _cacheService.readLottieContent(mediaId);
      if (content != null) return content;
    }

    // Sinon, obtenir l'URL et télécharger
    final url = await getLottieUrl(mediaId, userId);
    final request = http.Request('GET', Uri.parse(url));
    final streamedResponse = await request.send();

    if (streamedResponse.statusCode >= 400) {
      throw Exception(
        'Erreur téléchargement Lottie (${streamedResponse.statusCode})',
      );
    }

    final bytes = await streamedResponse.stream.toBytes();
    final content = utf8.decode(bytes);

    // Mettre en cache
    await _cacheService.cacheLottieMedia(
      assetId: mediaId,
      content: content,
      mediaUrl: url,
    );

    return content;
  }

  /// Récupère le chemin local d'un média (image, audio, vidéo) : depuis le cache ou télécharge
  Future<String?> getMediaLocalPath(
    int mediaId,
    int userId, {
    bool forStreaming = false,
  }) async {
    // Vérifier le cache
    final cached = await _cacheService.getCachedMedia(mediaId);
    if (cached != null) {
      return cached.filePath;
    }

    // Pas en cache : obtenir l'URL appropriée
    final url = forStreaming
        ? await getStreamUrl(mediaId, userId)
        : await getDownloadUrl(mediaId, userId);

    // Obtenir le type de média (nécessite de récupérer les infos du média)
    final mediaInfo = await getMediaById(mediaId, userId);
    final mediaType = _mediaTypeToString(mediaInfo.mediaType);

    // Télécharger et mettre en cache
    final cachedInfo = await downloadAndCacheMedia(
      assetId: mediaId,
      mediaType: mediaType,
      url: url,
    );

    return cachedInfo.filePath;
  }

  String _mediaTypeToString(MediaType type) {
    switch (type) {
      case MediaType.IMAGE:
        return 'IMAGE';
      case MediaType.AUDIO:
        return 'AUDIO';
      case MediaType.VIDEO:
        return 'VIDEO';
      case MediaType.DOCUMENT:
        return 'DOCUMENT';
      default:
        return 'OTHER';
    }
  }

  // ============ OPÉRATIONS CRUD ============

  Future<MediaDTO> getMediaById(int mediaId, int userId) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$mediaId');
      final headers = await _getHeaders(userId);

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 404) {
        throw Exception('Média non trouvé');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération média (${response.statusCode}): ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return MediaDTO.fromJson(jsonResponse);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération média $mediaId: $e');
      }
      rethrow;
    }
  }

  // Ancienne méthode getMediaContent supprimée : plus utilisée

  Future<PagedResponse<MediaDTO>> getUserMediaPaginated(
    int userId, {
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/user')
          .replace(
            queryParameters: {
              'page': page.toString(),
              'size': size.toString(),
              'sort': sort,
            },
          );

      final headers = await _getHeaders(userId);
      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur récupération médias: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);

      return PagedResponse<MediaDTO>.fromJson(
        jsonResponse as Map<String, dynamic>,
        (json) => MediaDTO.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur récupération médias utilisateur: $e');
      rethrow;
    }
  }

  Future<List<MediaDTO>> getUserMedia(
    int userId, {
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    try {
      final paginated = await getUserMediaPaginated(
        userId,
        page: page,
        size: size,
        sort: sort,
      );
      return paginated.content;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MediaDTO>> getPublicMedia({int page = 0, int size = 20}) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/public')
          .replace(
            queryParameters: {'page': page.toString(), 'size': size.toString()},
          );

      final headers = await _apiService.getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération médias publics: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse.containsKey('content')) {
        final content = jsonResponse['content'] as List<dynamic>;
        return content
            .map((json) => MediaDTO.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur récupération médias publics: $e');
      rethrow;
    }
  }

  Future<List<MediaDTO>> searchMedia(
    String query, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/search')
          .replace(
            queryParameters: {
              'q': query,
              'page': page.toString(),
              'size': size.toString(),
            },
          );

      final headers = await _apiService.getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur recherche médias: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse.containsKey('content')) {
        final content = jsonResponse['content'] as List<dynamic>;
        return content
            .map((json) => MediaDTO.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur recherche médias: $e');
      rethrow;
    }
  }

  Future<MediaDTO> updateMedia(
    int mediaId,
    int userId,
    UpdateMediaRequest request,
  ) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$mediaId');
      final headers = await _getHeaders(userId);
      headers['Content-Type'] = 'application/json';

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 404) {
        throw Exception('Média non trouvé');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur mise à jour média (${response.statusCode}): ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return MediaDTO.fromJson(jsonResponse);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour média $mediaId: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteMedia(int mediaId, int userId) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$mediaId');
      final headers = await _getHeaders(userId);

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 404) {
        throw Exception('Média non trouvé');
      }
      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur suppression média (${response.statusCode}): ${response.body}',
        );
      }

      // Supprimer du cache
      await _cacheService.deleteMedia(mediaId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression média $mediaId: $e');
      }
      rethrow;
    }
  }

  Future<void> incrementViewCount(int mediaId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$mediaId/view',
      );
      final headers = await _apiService.getHeaders();

      final response = await http.post(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception('Erreur incrémentation vues: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur incrémentation vues: $e');
      }
      rethrow;
    }
  }

  Future<bool> isMediaOwner(int mediaId, int userId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$mediaId/owner',
      );
      final headers = await _getHeaders(userId);

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur vérification propriété: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse is bool ? jsonResponse : false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur vérification propriété: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMediaStats(int userId) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/stats');
      final headers = await _getHeaders(userId);

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        throw Exception(
          'Erreur récupération statistiques: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération statistiques: $e');
      }
      rethrow;
    }
  }

  // ============ MÉTHODES DE CACHE ============

  Future<bool> isMediaCached(int assetId) async {
    return await _cacheService.isCached(assetId);
  }

  Future<String?> getCachedMediaPath(int assetId) async {
    return await _cacheService.getMediaPath(assetId);
  }

  Future<String?> getCachedMediaUrl(int assetId) async {
    return await _cacheService.getMediaUrl(assetId);
  }

  Future<void> deleteCachedMedia(int assetId) async {
    await _cacheService.deleteMedia(assetId);
  }

  Future<void> clearCache() async {
    await _cacheService.clearAllCache();
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'size': await _cacheService.getCacheSize(),
      'count': await _cacheService.getCachedCount(),
    };
  }

  // ============ MÉTHODES UTILITAIRES ============

  Future<Map<String, String>> _getHeaders(int userId) async {
    final headers = await _apiService.getHeaders();
    headers['X-User-Id'] = userId.toString();
    return headers;
  }

  Future<MediaUploadResponse> uploadMedia(
    int userId,
    File file, {
    String? title,
    String? description,
    String? category,
    String? tags,
    bool isPublic = true,
    int? durationSeconds,
  }) async {
    final lowerPath = file.path.toLowerCase();
    if (lowerPath.endsWith('.json') || lowerPath.endsWith('.lottie')) {
      return uploadLottieFile(
        userId,
        file,
        category: category,
        isPublic: isPublic,
      );
    }

    return uploadMediaSimple(
      userId,
      file,
      category: category,
      isPublic: isPublic,
    );
  }
}

class MimeTypeInfo {
  final http_parser.MediaType mediaType;
  final String type;

  MimeTypeInfo(this.mediaType, this.type);
}
