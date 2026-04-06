// lib/services/media_cache_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/audio_integrity_checker.dart'; // Import de la validation audio

class MediaCacheService {
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  final Map<int, CachedMediaInfo> _memoryCache = {};

  static const Duration cacheValidity = Duration(days: 7);
  static const int maxCacheSize = 500 * 1024 * 1024;

  Directory? _cacheDir;

  Future<void> initialize() async {
    _cacheDir = await _getCacheDirectory();
    if (kDebugMode) {
      print('📁 Cache directory: ${_cacheDir?.path}');
    }
  }

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/media_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  String _getFileName(int assetId, String mediaType) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String extension;
    switch (mediaType) {
      case 'VIDEO':
        extension = '.mp4';
        break;
      case 'AUDIO':
        extension = '.mp3';
        break;
      case 'LOTTIE':
        extension = '.json';
        break;
      default:
        extension = '.bin';
    }
    return 'media_${assetId}_$timestamp$extension';
  }

  Future<CachedMediaInfo?> getCachedMedia(int assetId) async {
    // Vérifier en mémoire
    if (_memoryCache.containsKey(assetId)) {
      final cached = _memoryCache[assetId]!;
      if (!_isExpired(cached)) {
        if (kDebugMode) print('✅ Média $assetId trouvé en mémoire cache');
        return cached;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_media_$assetId';
      final cachedInfoJson = prefs.getString(cacheKey);
      if (cachedInfoJson != null) {
        final cachedInfo = CachedMediaInfo.fromJson(
          jsonDecode(cachedInfoJson) as Map<String, dynamic>,
        );
        final file = File(cachedInfo.filePath);
        if (await file.exists()) {
          if (!_isExpired(cachedInfo)) {
            // Validation supplémentaire pour les fichiers audio
            if (cachedInfo.mediaType == 'AUDIO') {
              final isValid = await AudioIntegrityChecker.isAudioFileValid(
                cachedInfo.filePath,
              );
              if (!isValid) {
                if (kDebugMode) {
                  print(
                    '⚠️ Fichier audio corrompu en cache pour assetId $assetId, suppression',
                  );
                }
                await _deleteCachedMedia(assetId, cachedInfo);
                return null;
              }
            }
            _memoryCache[assetId] = cachedInfo;
            if (kDebugMode) print('✅ Média $assetId trouvé sur disque');
            return cachedInfo;
          } else {
            await _deleteCachedMedia(assetId, cachedInfo);
          }
        } else {
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur lecture cache: $e');
    }
    return null;
  }

  bool _isExpired(CachedMediaInfo info) {
    final expiryDate = info.cachedAt.add(cacheValidity);
    return DateTime.now().isAfter(expiryDate);
  }

  Future<CachedMediaInfo> cacheMedia({
    required int assetId,
    required String mediaType,
    required String mediaUrl,
    required Stream<List<int>> stream,
    required int contentLength,
  }) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileName(assetId, mediaType);
      final filePath = '${cacheDir.path}/$fileName';
      final file = File(filePath);

      final sink = file.openWrite();
      await stream.pipe(sink);
      await sink.flush();
      await sink.close();

      if (!await file.exists()) {
        throw Exception('Échec de l\'écriture du fichier');
      }

      final fileStat = await file.stat();
      if (fileStat.size == 0) {
        await file.delete();
        throw Exception('Fichier vide');
      }

      // Validation pour les fichiers audio
      if (mediaType == 'AUDIO') {
        final isValid = await AudioIntegrityChecker.isAudioFileValid(filePath);
        if (!isValid) {
          await file.delete();
          throw Exception(
            'Fichier audio corrompu ou invalide (assetId: $assetId)',
          );
        }
        if (kDebugMode) print('✅ Validation audio réussie pour $assetId');
      }

      final cachedInfo = CachedMediaInfo(
        assetId: assetId,
        mediaType: mediaType,
        filePath: filePath,
        cachedAt: DateTime.now(),
        contentLength: contentLength,
        url: mediaUrl,
      );

      _memoryCache[assetId] = cachedInfo;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_media_$assetId',
        jsonEncode(cachedInfo.toJson()),
      );

      await _manageCacheSize();

      if (kDebugMode) {
        print('✅ Média $assetId mis en cache: $filePath');
        print('📦 Taille: ${_formatFileSize(contentLength)}');
      }

      return cachedInfo;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur cacheMedia: $e');
      rethrow;
    }
  }

  Future<CachedMediaInfo> cacheLottieMedia({
    required int assetId,
    required String content,
    required String mediaUrl,
  }) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileName(assetId, 'LOTTIE');
      final filePath = '${cacheDir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsString(content, encoding: utf8);

      if (!await file.exists()) {
        throw Exception('Échec de l\'écriture du fichier Lottie');
      }

      final contentLength = content.length;

      final cachedInfo = CachedMediaInfo(
        assetId: assetId,
        mediaType: 'LOTTIE',
        filePath: filePath,
        cachedAt: DateTime.now(),
        contentLength: contentLength,
        url: mediaUrl,
      );

      _memoryCache[assetId] = cachedInfo;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_media_$assetId',
        jsonEncode(cachedInfo.toJson()),
      );

      if (kDebugMode) {
        print('✅ Animation Lottie $assetId mise en cache');
      }

      return cachedInfo;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur cacheLottieMedia: $e');
      rethrow;
    }
  }

  Future<void> _manageCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final files = await cacheDir.list().toList();
      if (files.isEmpty) return;

      int totalSize = 0;
      final fileInfos = <FileInfo>[];

      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
          fileInfos.add(
            FileInfo(
              file: entity,
              lastAccessed: stat.accessed,
              size: stat.size,
            ),
          );
        }
      }

      if (totalSize > maxCacheSize) {
        fileInfos.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
        int freedSpace = 0;
        for (final fileInfo in fileInfos) {
          if (totalSize - freedSpace <= maxCacheSize) break;

          final fileName = fileInfo.file.path.split('/').last;
          final assetIdMatch = RegExp(r'media_(\d+)_').firstMatch(fileName);
          if (assetIdMatch != null) {
            final assetId = int.parse(assetIdMatch.group(1)!);
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('cached_media_$assetId');
            _memoryCache.remove(assetId);
          }
          await fileInfo.file.delete();
          freedSpace += fileInfo.size;
          if (kDebugMode) {
            print('🗑️ Suppression ancien cache: ${fileInfo.file.path}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur gestion taille cache: $e');
    }
  }

  Future<void> _deleteCachedMedia(int assetId, CachedMediaInfo info) async {
    try {
      final file = File(info.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_media_$assetId');
      _memoryCache.remove(assetId);
      if (kDebugMode) print('🗑️ Cache supprimé pour média $assetId');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur suppression cache: $e');
    }
  }

  Future<void> deleteMedia(int assetId) async {
    final cached = await getCachedMedia(assetId);
    if (cached != null) {
      await _deleteCachedMedia(assetId, cached);
    }
  }

  Future<void> clearAllCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) => key.startsWith('cached_media_'),
      );
      for (final key in keys) {
        await prefs.remove(key);
      }
      _memoryCache.clear();
      if (kDebugMode) print('🧹 Cache média complètement vidé');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur vidage cache: $e');
    }
  }

  Future<String> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return '0 B';
      int totalSize = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return _formatFileSize(totalSize);
    } catch (e) {
      return 'Erreur';
    }
  }

  Future<int> getCachedCount() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return 0;
      int count = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) count++;
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> isCached(int assetId) async {
    return (await getCachedMedia(assetId)) != null;
  }

  Future<List<int>?> readMediaContent(int assetId) async {
    final cached = await getCachedMedia(assetId);
    if (cached == null) return null;
    try {
      final file = File(cached.filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur lecture fichier cache: $e');
    }
    return null;
  }

  Future<String?> readLottieContent(int assetId) async {
    final cached = await getCachedMedia(assetId);
    if (cached == null || cached.mediaType != 'LOTTIE') return null;
    try {
      final file = File(cached.filePath);
      if (await file.exists()) {
        return await file.readAsString(encoding: utf8);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur lecture Lottie cache: $e');
    }
    return null;
  }

  Future<String?> getMediaPath(int assetId) async {
    final cached = await getCachedMedia(assetId);
    return cached?.filePath;
  }

  Future<String?> getMediaUrl(int assetId) async {
    final path = await getMediaPath(assetId);
    if (path != null) {
      return 'file://$path';
    }
    return null;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void clearMemoryCache() {
    _memoryCache.clear();
  }
}

class CachedMediaInfo {
  final int assetId;
  final String mediaType;
  final String filePath;
  final DateTime cachedAt;
  final int contentLength;
  final String url;

  CachedMediaInfo({
    required this.assetId,
    required this.mediaType,
    required this.filePath,
    required this.cachedAt,
    required this.contentLength,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
    'assetId': assetId,
    'mediaType': mediaType,
    'filePath': filePath,
    'cachedAt': cachedAt.toIso8601String(),
    'contentLength': contentLength,
    'url': url,
  };

  factory CachedMediaInfo.fromJson(Map<String, dynamic> json) {
    return CachedMediaInfo(
      assetId: json['assetId'] as int,
      mediaType: json['mediaType'] as String,
      filePath: json['filePath'] as String,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      contentLength: json['contentLength'] as int,
      url: json['url'] as String,
    );
  }
}

class FileInfo {
  final File file;
  final DateTime lastAccessed;
  final int size;
  FileInfo({
    required this.file,
    required this.lastAccessed,
    required this.size,
  });
}
