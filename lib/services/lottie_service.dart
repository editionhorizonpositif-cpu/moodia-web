// lib/services/lottie_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'api_service.dart';

class LottieService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'media';

  LottieService(this._apiService);

  // Méthode pour obtenir les headers avec userId
  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = await _apiService.getToken();

      final headers = <String, String>{};

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      if (userId != null) {
        headers['X-User-Id'] = userId.toString();
      }

      if (kDebugMode) {
        print('🎬 LottieService - Headers: ${headers.keys}');
        if (headers.containsKey('X-User-Id')) {
          print('👤 X-User-Id: ${headers['X-User-Id']}');
        }
      }

      return headers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur _getHeadersWithUserId: $e');
      }
      return await _apiService.getHeaders();
    }
  }

  // Obtenir l'URL de streaming Lottie
  String getLottieStreamUrl(int assetId) {
    return '${ApiService.baseUrl}/$_baseEndpoint/$assetId/stream';
  }

  // Obtenir les headers pour Lottie
  Future<Map<String, String>> getLottieHeaders() async {
    return await _getHeadersWithUserId();
  }

  // Vérifier si l'asset Lottie est accessible
  Future<bool> isLottieAccessible(int assetId) async {
    try {
      final url = getLottieStreamUrl(assetId);
      final headers = await _getHeadersWithUserId();

      final response = await http
          .head(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        print('🎬 Test accessibilité Lottie $assetId: ${response.statusCode}');
      }

      return response.statusCode == 200 || response.statusCode == 206;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Lottie inaccessible: $e');
      }
      return false;
    }
  }

  // Précharger une animation Lottie
  Future<LottieComposition?> preloadLottie(int assetId) async {
    try {
      final url = getLottieStreamUrl(assetId);
      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('🎬 Préchargement Lottie depuis: $url');
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return await LottieComposition.fromBytes(response.bodyBytes);
      } else {
        if (kDebugMode) {
          print('❌ Erreur HTTP ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur préchargement Lottie: $e');
      }
    }
    return null;
  }

  // Obtenir le type de média
  Future<String> getMediaType(int assetId) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/$_baseEndpoint/$assetId');
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));

        // Détection par mediaType
        final mediaTypeStr = jsonData['mediaType']?.toString().toUpperCase();
        if (mediaTypeStr == 'LOTTIE' || mediaTypeStr == 'ANIMATION') {
          return 'LOTTIE';
        }

        // Détection par mimeType
        final mimeType = jsonData['mimeType']?.toString().toLowerCase() ?? '';
        if (mimeType.contains('json') || mimeType.contains('lottie')) {
          return 'LOTTIE';
        }

        // Détection par extension
        final filename =
            jsonData['originalFilename']?.toString().toLowerCase() ?? '';
        if (filename.endsWith('.json') || filename.endsWith('.lottie')) {
          return 'LOTTIE';
        }
      }

      return 'UNKNOWN';
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur récupération type média $assetId: $e');
      }
      return 'UNKNOWN';
    }
  }

  // Méthode utilitaire pour le débogage
  Future<void> debugLottieUrl(int assetId) async {
    if (!kDebugMode) return;

    print('=== DÉBOGAGE LOTTIE ===');
    print('Asset ID: $assetId');

    final url = getLottieStreamUrl(assetId);
    print('URL: $url');

    final headers = await _getHeadersWithUserId();
    print('Headers:');
    headers.forEach((key, value) {
      if (key == 'Authorization') {
        print('  $key: Bearer [TOKEN_CACHÉ]');
      } else {
        print('  $key: $value');
      }
    });

    final isAccessible = await isLottieAccessible(assetId);
    print('Accessible: $isAccessible');
    print('=== FIN DÉBOGAGE ===');
  }
}
