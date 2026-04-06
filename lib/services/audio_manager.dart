import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/meditation.dart';

class AudioManager extends ChangeNotifier {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  AudioManager._internal() {
    _initializeListeners();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  Meditation? _currentMeditation;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isBuffering = false;
  bool _showControls = true;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  PlayerState _playerState = PlayerState.stopped;

  // Getters publics
  AudioPlayer get player => _audioPlayer;
  Meditation? get currentMeditation => _currentMeditation;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isBuffering => _isBuffering;
  bool get showControls => _showControls;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  PlayerState get playerState => _playerState;

  // Méthode privée pour initialiser les listeners
  void _initializeListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      _isPlaying = state == PlayerState.playing;
      _isBuffering = state == PlayerState.playing && _duration.inSeconds == 0;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _onPlaybackComplete();
    });

    _audioPlayer.onSeekComplete.listen((_) {
      notifyListeners();
    });

    _audioPlayer.onLog.listen((log) {
      debugPrint('AudioPlayer Log: $log');
    });
  }

  // Jouer une méditation
  Future<void> playMeditation(Meditation meditation) async {
    try {
      // Si déjà en train de jouer la même méditation, toggle play/pause
      if (_currentMeditation?.id == meditation.id) {
        await togglePlayPause();
        return;
      }

      // Arrêter la lecture actuelle si nécessaire
      if (_isPlaying) {
        await stop();
      }

      _currentMeditation = meditation;
      _isLoading = true;
      notifyListeners();

      // Configurer le player
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(_volume);

      // Jouer l'audio
      //await _audioPlayer.play(UrlSource(meditation.mediaUrl));

      _isPlaying = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _currentMeditation = null;
      debugPrint("Erreur de lecture audio : $e");
      notifyListeners();
      rethrow;
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  // Pause
  Future<void> pause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Reprendre
  Future<void> resume() async {
    if (!_isPlaying && _currentMeditation != null) {
      if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await playMeditation(_currentMeditation!);
      }
      _isPlaying = true;
      notifyListeners();
    }
  }

  // Arrêter complètement
  Future<void> stop() async {
    await _audioPlayer.stop();
    _resetState();
    notifyListeners();
  }

  // Seek à une position spécifique
  Future<void> seek(Duration position) async {
    if (_duration.inSeconds > 0) {
      // Limiter la position entre 0 et la durée totale
      final clampedPosition = Duration(
        seconds: position.inSeconds.clamp(0, _duration.inSeconds),
      );

      await _audioPlayer.seek(clampedPosition);
      _position = clampedPosition;
      notifyListeners();
    }
  }

  // Avancer de X secondes
  Future<void> forward(Duration offset) async {
    final newPosition = _position + offset;
    if (newPosition <= _duration) {
      await seek(newPosition);
    } else {
      await seek(_duration);
    }
  }

  // Reculer de X secondes
  Future<void> rewind(Duration offset) async {
    final newPosition = _position - offset;
    if (newPosition.inSeconds >= 0) {
      await seek(newPosition);
    } else {
      await seek(Duration.zero);
    }
  }

  // Régler le volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  // Toggle les contrôles
  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  // Réinitialiser l'état
  void _resetState() {
    _isPlaying = false;
    _isLoading = false;
    _isBuffering = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentMeditation = null;
  }

  // Callback quand la lecture est terminée
  void _onPlaybackComplete() {
    _isPlaying = false;
    _position = _duration;
    notifyListeners();
  }

  // Formatter la durée pour l'affichage
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  // Calculer le pourcentage de progression
  double get progress {
    if (_duration.inSeconds == 0) return 0.0;
    return _position.inSeconds / _duration.inSeconds;
  }

  // Vérifier si une méditation est en cours de lecture
  bool isCurrentMeditation(int meditationId) {
    return _currentMeditation?.id == meditationId;
  }

  // Disposer des ressources
  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
  }

  // Méthode pour debug
  void debugInfo() {
    debugPrint('''
    === AudioManager Debug ===
    Current Meditation: ${_currentMeditation?.title ?? 'None'}
    Is Playing: $_isPlaying
    Is Loading: $_isLoading
    Is Buffering: $_isBuffering
    Position: ${_position.inSeconds}s / ${_duration.inSeconds}s
    Volume: $_volume
    Player State: $_playerState
    ''');
  }
}
