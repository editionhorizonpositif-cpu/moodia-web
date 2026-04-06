import 'package:flutter/foundation.dart';
import '../services/meditation_service.dart';

// services/completion_service.dart
class CompletionService {
  final MeditationService _meditationService;
  final Set<int> _sessionCompletedIds = {};
  final VoidCallback? _onCompletionSuccess;

  // Ajout d'un flag pour éviter les appels concurrents
  bool _isCompleting = false;

  CompletionService({
    required MeditationService meditationService,
    VoidCallback? onCompletionSuccess,
  }) : _meditationService = meditationService,
       _onCompletionSuccess = onCompletionSuccess;

  Future<bool> checkAndComplete({
    required int meditationId,
    required Duration currentPosition,
    required Duration totalDuration,
    required bool isPlaying,
    required int userId,
    double threshold = 0.95,
  }) async {
    if (!isPlaying) return false;
    if (_sessionCompletedIds.contains(meditationId)) return false;
    if (_isCompleting) {
      if (kDebugMode) print('⏳ Déjà en cours de complétion pour $meditationId');
      return false;
    }

    if (totalDuration.inSeconds <= 0) return false;

    final progress = currentPosition.inSeconds / totalDuration.inSeconds;

    if (progress >= threshold) {
      _sessionCompletedIds.add(meditationId);
      _isCompleting = true;

      try {
        if (kDebugMode) {
          print('✅ Seuil atteint pour méditation $meditationId');
        }

        await _meditationService.markAsCompleted(meditationId);

        if (kDebugMode) {
          print('✅ Méditation $meditationId marquée comme complétée');
        }

        _onCompletionSuccess?.call();
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur lors de la complétion: $e');
        }
        _sessionCompletedIds.remove(meditationId);
        return false;
      } finally {
        // Petit délai pour éviter les appels en rafale
        await Future.delayed(const Duration(milliseconds: 500));
        _isCompleting = false;
      }
    }

    return false;
  }

  void resetForNextPlayback() {
    _sessionCompletedIds.clear();
    _isCompleting = false;
    if (kDebugMode) {
      print('🔄 Session reset - prêt pour nouvelle écoute');
    }
  }

  void clearCache() {
    _sessionCompletedIds.clear();
    _isCompleting = false;
    if (kDebugMode) print('🧹 CompletionService cache cleared');
  }
}
