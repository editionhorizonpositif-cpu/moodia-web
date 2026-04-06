// lib/services/media_url_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class MediaUrlService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'media';

  MediaUrlService(this._apiService);

  /// Récupère l'URL de streaming pour un media
  Future<String> getMediaStreamUrl(int mediaId) async {
    try {
      if (kDebugMode) {
        print('🎵 DEBUT getMediaStreamUrl: $mediaId');
      }

      // Option 1: Endpoint spécifique pour streaming
      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/$mediaId/stream',
      );

      final headers = await _apiService.getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final bodyString = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(bodyString);

        final streamUrl = jsonResponse['url'] ?? jsonResponse['streamUrl'];

        if (streamUrl != null && streamUrl.isNotEmpty) {
          if (kDebugMode) {
            print('✅ URL streaming: $streamUrl');
          }
          return streamUrl;
        }
      }

      // Option 2: Si pas d'endpoint spécifique, construire l'URL directement
      return _buildDirectMediaUrl(mediaId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getMediaStreamUrl: $e');
      }
      // Retourner une URL de fallback
      return _getFallbackUrl();
    }
  }

  String _buildDirectMediaUrl(int mediaId) {
    // Construire l'URL directe selon votre configuration backend
    return '${ApiService.baseUrl}/$_baseEndpoint/$mediaId/file';
  }

  String _getFallbackUrl() {
    // URLs de test publiques
    return 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
  }
}
