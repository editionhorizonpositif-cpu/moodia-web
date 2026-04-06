// lib/services/playback_manager.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/meditation.dart';
import '../utils/audio_integrity_checker.dart'; // Import de la classe dédiée

enum PlaybackState {
  idle,
  loading,
  ready,
  playing,
  paused,
  buffering,
  completed,
  error,
}

class PlaybackManager extends ChangeNotifier {
  // ========== PROPRIÉTÉS ==========
  PlaybackState _state = PlaybackState.idle;
  Meditation? _currentMeditation;

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;

  // Cache pour fichiers temporaires
  final Map<String, File> _cachedFiles = {};

  // Stream subscriptions
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;

  // ========== GETTERS ==========
  PlaybackState get state => _state;
  Meditation? get currentMeditation => _currentMeditation;
  bool get isPlaying => _state == PlaybackState.playing;
  bool get isPaused => _state == PlaybackState.paused;
  bool get isLoading => _state == PlaybackState.loading;
  bool get hasError => _state == PlaybackState.error;

  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  double get playbackSpeed => _playbackSpeed;

  double get progress {
    if (duration.inSeconds == 0) return 0.0;
    return position.inSeconds / duration.inSeconds;
  }

  String get formattedPosition => _formatDuration(position);
  String get formattedDuration => _formatDuration(duration);

  // ========== CONSTRUCTEUR ==========
  PlaybackManager() {
    _setupListeners();
  }

  void _setupListeners() {
    _disposeSubscriptions();

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      playerState,
    ) {
      _handlePlayerStateChange(playerState);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _onPlaybackComplete();
    });
  }

  void _disposeSubscriptions() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
  }

  // ========== MÉTHODES PUBLIQUES ==========

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      _playbackSpeed = speed.clamp(0.5, 2.0);
      if (kDebugMode) {
        print('🎵 Changement vitesse: ${_playbackSpeed.toStringAsFixed(1)}x');
      }
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur setPlaybackSpeed: $e');
    }
  }

  double getPlaybackSpeed() => _playbackSpeed;

  Future<void> resetPlaybackSpeed() async {
    await setPlaybackSpeed(1.0);
  }

  /// Charge et joue une méditation (avec support optionnel des headers)
  Future<void> loadAndPlayMeditation(
    Meditation meditation, {
    String? audioUrl,
    Map<String, String>? headers,
    bool autoPlay = true,
    Duration startAt = Duration.zero,
  }) async {
    try {
      _updateState(PlaybackState.loading);
      await _audioPlayer.stop();
      await resetPlaybackSpeed();
      _currentMeditation = meditation;

      final url = audioUrl ?? _getTestAudioUrl();
      debugPrint('🎵 Chargement audio depuis: $url');

      if (headers != null && headers.isNotEmpty) {
        debugPrint('🔐 Headers fournis: ${headers.keys.join(', ')}');
        await _loadAudioWithHeaders(url, headers);
      } else {
        await _loadAudio(url);
      }

      if (startAt > Duration.zero) {
        await seek(startAt);
      }

      _updateState(PlaybackState.ready);
      if (autoPlay) {
        await play();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur loadAndPlayMeditation: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _handleError('Impossible de charger la méditation: $e');
    }
  }

  /// Télécharger et jouer avec headers + vérification d'intégrité
  Future<void> _loadAudioWithHeaders(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      debugPrint('🎵 Téléchargement audio avec headers...');

      // Vérifier si on a déjà le fichier en cache
      final cachedFile = _getCachedFile(url);
      if (cachedFile != null && await cachedFile.exists()) {
        debugPrint('📦 Fichier trouvé en cache: ${cachedFile.path}');
        // Vérifier l'intégrité du fichier en cache
        if (await AudioIntegrityChecker.isAudioFileValid(cachedFile.path)) {
          debugPrint('✅ Fichier cache valide, utilisation directe');
          await _audioPlayer.setSourceDeviceFile(cachedFile.path);
          return;
        } else {
          debugPrint(
            '⚠️ Fichier cache invalide, suppression et re-téléchargement',
          );
          await cachedFile.delete();
          _cachedFiles.remove(url);
        }
      }

      // Télécharger le fichier
      debugPrint('📥 Téléchargement depuis: $url');
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Échec du téléchargement: ${response.statusCode}');
      }

      // Sauvegarder dans un fichier temporaire
      final tempFile = await _saveToTempFile(response.bodyBytes, url);

      // Vérifier l'intégrité du fichier téléchargé
      debugPrint('🔍 Vérification de l\'intégrité du fichier audio...');
      final isValid = await AudioIntegrityChecker.isAudioFileValid(
        tempFile.path,
      );

      if (!isValid) {
        await tempFile.delete();
        throw Exception('Fichier audio téléchargé invalide ou corrompu');
      }

      debugPrint('✅ Fichier audio valide, mise en cache');
      _cachedFiles[url] = tempFile;
      await _audioPlayer.setSourceDeviceFile(tempFile.path);
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur _loadAudioWithHeaders: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      // Fallback: essayer sans headers
      debugPrint('🔄 Tentative de fallback sans headers...');
      try {
        await _loadAudio(url);
      } catch (fallbackError) {
        throw Exception('Échec avec headers et fallback: $e');
      }
    }
  }

  /// Sauvegarder dans un fichier temporaire
  Future<File> _saveToTempFile(Uint8List bytes, String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'audio_${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}.mp3';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('❌ Erreur _saveToTempFile: $e');
      rethrow;
    }
  }

  File? _getCachedFile(String url) => _cachedFiles[url];

  Future<void> clearCache() async {
    try {
      for (final file in _cachedFiles.values) {
        if (await file.exists()) await file.delete();
      }
      _cachedFiles.clear();
      debugPrint('✅ Cache audio nettoyé');
    } catch (e) {
      debugPrint('❌ Erreur clearCache: $e');
    }
  }

  Future<void> loadAudioUrl(String url, {bool autoPlay = true}) async {
    try {
      _updateState(PlaybackState.loading);
      await _audioPlayer.stop();
      await resetPlaybackSpeed();
      await _loadAudio(url);
      _updateState(PlaybackState.ready);
      if (autoPlay) await play();
    } catch (e) {
      _handleError('Erreur chargement URL: $e');
    }
  }

  Future<bool> testAudioPlayback() async {
    try {
      const testUrl =
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
      debugPrint('🎵 Test audio avec: $testUrl');
      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(testUrl);
      await Future.delayed(const Duration(seconds: 2));
      if (_duration != Duration.zero) {
        debugPrint('✅ Test audio réussi! Durée: ${_formatDuration(_duration)}');
        return true;
      } else {
        debugPrint('⚠️ Audio chargé mais durée non détectée');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Test audio échoué: $e');
      return false;
    }
  }

  Future<bool> testAudioWithHeaders(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      debugPrint('🎵 Test audio avec headers: $url');
      await _audioPlayer.stop();
      await resetPlaybackSpeed();
      await _loadAudioWithHeaders(url, headers);
      await Future.delayed(const Duration(seconds: 2));
      if (_duration != Duration.zero) {
        debugPrint('✅ Test audio avec headers réussi!');
        return true;
      } else {
        debugPrint('⚠️ Audio avec headers chargé mais durée non détectée');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Test audio avec headers échoué: $e');
      return false;
    }
  }

  // ========== CONTRÔLES DE LECTURE ==========
  Future<void> play() async {
    if (_state == PlaybackState.ready ||
        _state == PlaybackState.paused ||
        _state == PlaybackState.completed) {
      try {
        await _audioPlayer.resume();
        _updateState(PlaybackState.playing);
      } catch (e) {
        _handleError('Erreur lors de la lecture: $e');
      }
    }
  }

  Future<void> pause() async {
    if (_state == PlaybackState.playing) {
      try {
        await _audioPlayer.pause();
        _updateState(PlaybackState.paused);
      } catch (e) {
        _handleError('Erreur lors de la pause: $e');
      }
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _resetAudioState();
      _updateState(PlaybackState.idle);
    } catch (e) {
      _handleError('Erreur lors de l\'arrêt: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      _position = position;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur seek: $e');
    }
  }

  Future<void> forward(Duration offset) async {
    final newPosition = position + offset;
    if (newPosition <= duration) {
      await seek(newPosition);
    } else {
      await seek(duration);
    }
  }

  Future<void> rewind(Duration offset) async {
    final newPosition = position - offset;
    if (newPosition >= Duration.zero) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    _isMuted = _volume == 0;
    try {
      await _audioPlayer.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur setVolume: $e');
    }
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      await setVolume(1.0);
    } else {
      await setVolume(0.0);
    }
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ========== MÉTHODES PRIVÉES ==========

  Future<void> _loadAudio(String url) async {
    try {
      debugPrint('🎵 Tentative de chargement sans headers: $url');

      if (url.isEmpty) {
        throw Exception('URL vide');
      }

      // Si c'est un fichier local, vérifier son intégrité
      if (url.startsWith('file://') ||
          (url.contains(Platform.pathSeparator) && !url.startsWith('http'))) {
        final filePath = url.replaceFirst('file://', '');
        if (await File(filePath).exists()) {
          debugPrint('🔍 Vérification intégrité fichier local: $filePath');
          final isValid = await AudioIntegrityChecker.isAudioFileValid(
            filePath,
          );
          if (!isValid) {
            throw Exception(
              'Fichier audio local invalide ou corrompu: $filePath',
            );
          }
          debugPrint('✅ Fichier local valide');
        }
      }

      // Charger la source
      if (url.startsWith('http')) {
        await _audioPlayer.setSourceUrl(url);
      } else if (url.startsWith('assets/')) {
        final assetPath = url.replaceFirst('assets/', '');
        await _audioPlayer.setSourceAsset(assetPath);
      } else if (url.startsWith('file://')) {
        final filePath = url.replaceFirst('file://', '');
        await _audioPlayer.setSourceDeviceFile(filePath);
      } else {
        await _audioPlayer.setSourceDeviceFile(url);
      }

      debugPrint('✅ Source audio chargée avec succès');
      await Future.delayed(const Duration(milliseconds: 500));

      if (_duration == Duration.zero) {
        debugPrint('⚠️ Durée non détectée après chargement');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur _loadAudio: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      throw Exception('Échec du chargement audio: $e');
    }
  }

  String _getTestAudioUrl() {
    const testUrls = [
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'https://assets.mixkit.co/music/preview/mixkit-relaxation-128.mp3',
      'https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3',
    ];
    return testUrls.first;
  }

  void _handlePlayerStateChange(PlayerState playerState) {
    debugPrint('🎵 PlayerState changé: $playerState');
    switch (playerState) {
      case PlayerState.playing:
        _updateState(PlaybackState.playing);
        break;
      case PlayerState.paused:
        _updateState(PlaybackState.paused);
        break;
      case PlayerState.stopped:
        if (_state != PlaybackState.completed) {
          _updateState(PlaybackState.idle);
        }
        break;
      case PlayerState.completed:
        _onPlaybackComplete();
        break;
      default:
        debugPrint('État PlayerState non géré: $playerState');
    }
  }

  void _updateState(PlaybackState newState) {
    if (_state != newState) {
      _state = newState;
      debugPrint('🔄 État PlaybackManager changé: $newState');
      notifyListeners();
    }
  }

  void _onPlaybackComplete() {
    _updateState(PlaybackState.completed);
    debugPrint('✅ Lecture terminée: ${_currentMeditation?.title}');
  }

  void _handleError(String message) {
    debugPrint('❌ PlaybackManager Error: $message');
    _updateState(PlaybackState.error);
  }

  void _resetAudioState() {
    _position = Duration.zero;
    _duration = Duration.zero;
    _volume = 1.0;
    _isMuted = false;
    _playbackSpeed = 1.0;
  }

  String _formatDuration(Duration duration) => formatDuration(duration);

  // ========== DISPOSE ==========
  @override
  void dispose() {
    _disposeSubscriptions();
    _audioPlayer.dispose();
    clearCache();
    super.dispose();
  }
}
