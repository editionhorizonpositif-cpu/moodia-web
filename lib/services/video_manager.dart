import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Gestionnaire de vidéo professionnel avec Chewie 1.7.0
class VideoManager extends ChangeNotifier {
  // ========== PROPRIÉTÉS ==========
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // État
  VideoState _state = VideoState.idle;
  String? _errorMessage;
  bool _isBuffering = false;

  // Lecture
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  bool _isLooping = false;

  // Interface
  bool _isFullScreen = false;
  bool _showControls = true;

  // Playlist
  final List<VideoSource> _playlist = [];
  int _currentIndex = -1;

  // Qualité
  List<VideoQuality> _qualities = [];
  VideoQuality? _selectedQuality;

  // Sous-titres
  List<SubtitleTrack> _subtitles = [];
  SubtitleTrack? _selectedSubtitle;
  bool _showSubtitles = true;

  // Statistiques
  final Map<String, VideoStats> _videoStats = {};
  Timer? _watchTimer;
  DateTime? _startWatchTime;

  // Événements
  final StreamController<VideoEvent> _eventStream =
      StreamController<VideoEvent>.broadcast();

  // ========== GETTERS ==========
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  VideoState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  bool get isMuted => _isMuted;
  bool get isLooping => _isLooping;
  bool get isFullScreen => _isFullScreen;
  bool get showControls => _showControls;
  List<VideoSource> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  VideoSource? get currentVideo =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;
  List<VideoQuality> get qualities => List.unmodifiable(_qualities);
  VideoQuality? get selectedQuality => _selectedQuality;
  List<SubtitleTrack> get subtitles => List.unmodifiable(_subtitles);
  SubtitleTrack? get selectedSubtitle => _selectedSubtitle;
  bool get showSubtitles => _showSubtitles;
  Stream<VideoEvent> get events => _eventStream.stream;

  bool get isPlaying => _state == VideoState.playing;
  bool get isPaused => _state == VideoState.paused;
  bool get isReady => _state == VideoState.ready;
  bool get hasError => _state == VideoState.error;

  double get progress =>
      _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0.0;

  // ========== INITIALISATION ==========
  VideoManager() {
    _initializeDefaultQualities();
    _loadSavedStats();
  }

  // ========== MÉTHODES PUBLIQUES ==========

  /// Charge et initialise une vidéo
  Future<void> initializeVideo({
    required String url,
    String? title,
    String? description,
    String? thumbnail,
    bool autoPlay = false,
    Duration startAt = Duration.zero,
    Map<String, String>? headers,
    VideoSourceType sourceType = VideoSourceType.network,
  }) async {
    try {
      _updateState(VideoState.initializing);
      _errorMessage = null;
      notifyListeners();

      // Nettoyer les ressources précédentes
      await _safeDispose();

      // Créer le contrôleur vidéo selon le type de source
      _videoController = await _createVideoController(
        url: url,
        sourceType: sourceType,
        headers: headers,
      );

      // Initialiser
      await _videoController!.initialize();

      // Configurer les écouteurs
      _setupVideoListeners();

      // Mettre à jour la durée
      _duration = _videoController!.value.duration;

      // Créer le contrôleur Chewie
      await _createChewieController(
        title: title,
        description: description,
        thumbnail: thumbnail,
        autoPlay: autoPlay,
      );

      // Aller à la position de départ
      if (startAt > Duration.zero) {
        await seekTo(startAt);
      }

      // Démarrer les statistiques
      _startWatchStatistics(url);

      _updateState(VideoState.ready);

      if (autoPlay) {
        await play();
      }

      _eventStream.add(
        VideoEvent.initialized(
          videoId: url,
          duration: _duration,
          qualities: _qualities,
        ),
      );
    } catch (error) {
      _handleError('Failed to initialize video: $error');
      rethrow;
    }
  }

  /// Ajoute une vidéo à la playlist
  void addToPlaylist(VideoSource video) {
    if (!_playlist.any((v) => v.id == video.id)) {
      _playlist.add(video);
      notifyListeners();
      _eventStream.add(
        VideoEvent.playlistUpdated(
          playlist: List.from(_playlist),
          addedVideo: video,
        ),
      );
    }
  }

  /// Joue une vidéo spécifique de la playlist
  Future<void> playFromPlaylist(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      final video = _playlist[index];

      await initializeVideo(
        url: video.url,
        title: video.title,
        description: video.description,
        thumbnail: video.thumbnail,
        autoPlay: true,
      );
    }
  }

  /// Joue la vidéo suivante
  Future<void> playNext() async {
    if (_playlist.length > 1) {
      final nextIndex = (_currentIndex + 1) % _playlist.length;
      await playFromPlaylist(nextIndex);
    }
  }

  /// Joue la vidéo précédente
  Future<void> playPrevious() async {
    if (_playlist.length > 1) {
      final prevIndex =
          (_currentIndex - 1 + _playlist.length) % _playlist.length;
      await playFromPlaylist(prevIndex);
    }
  }

  /// Démarre la lecture
  Future<void> play() async {
    if (_videoController != null && !_videoController!.value.isPlaying) {
      await _videoController!.play();
      _updateState(VideoState.playing);
      _eventStream.add(VideoEvent.playing());
    }
  }

  /// Met en pause
  Future<void> pause() async {
    if (_videoController != null && _videoController!.value.isPlaying) {
      await _videoController!.pause();
      _updateState(VideoState.paused);
      _eventStream.add(VideoEvent.paused());
    }
  }

  /// Alterne entre lecture et pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Se positionne à un moment spécifique
  Future<void> seekTo(Duration position) async {
    if (_videoController != null) {
      await _videoController!.seekTo(position);
      _position = position;
      notifyListeners();
      _eventStream.add(VideoEvent.seeked(position));
    }
  }

  /// Avance
  Future<void> forward(Duration duration) async {
    final newPosition = _position + duration;
    if (newPosition <= _duration) {
      await seekTo(newPosition);
    }
  }

  /// Recule
  Future<void> rewind(Duration duration) async {
    final newPosition = _position - duration;
    if (newPosition >= Duration.zero) {
      await seekTo(newPosition);
    }
  }

  /// Change le volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    _isMuted = _volume == 0;

    if (_videoController != null) {
      await _videoController!.setVolume(_volume);
      notifyListeners();
      _eventStream.add(VideoEvent.volumeChanged(_volume));
    }
  }

  /// Coupe le son
  Future<void> mute() async {
    await setVolume(0.0);
    _eventStream.add(VideoEvent.muted());
  }

  /// Rétablit le son
  Future<void> unmute() async {
    await setVolume(1.0);
    _eventStream.add(VideoEvent.unmuted());
  }

  /// Alterne entre muet/non-muet
  Future<void> toggleMute() async {
    if (_isMuted) {
      await unmute();
    } else {
      await mute();
    }
  }

  /// Change la vitesse de lecture
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.25, 4.0);

    if (_videoController != null) {
      await _videoController!.setPlaybackSpeed(_playbackSpeed);
      notifyListeners();
      _eventStream.add(VideoEvent.playbackSpeedChanged(_playbackSpeed));
    }
  }

  /// Active/désactive la boucle
  void toggleLoop() {
    _isLooping = !_isLooping;

    if (_chewieController != null && _videoController != null) {
      // Recréer le contrôleur avec la nouvelle configuration
      _recreateChewieController();
    }

    notifyListeners();
    _eventStream.add(
      _isLooping ? VideoEvent.loopEnabled() : VideoEvent.loopDisabled(),
    );
  }

  /// Active/désactive les sous-titres
  void toggleSubtitles() {
    _showSubtitles = !_showSubtitles;
    notifyListeners();
    _eventStream.add(
      _showSubtitles
          ? VideoEvent.subtitlesEnabled()
          : VideoEvent.subtitlesDisabled(),
    );
  }

  /// Change la qualité
  Future<void> setQuality(VideoQuality quality) async {
    _selectedQuality = quality;

    // TODO: Implémenter le changement de qualité dynamique
    // Pour l'instant, on recharge la vidéo avec la nouvelle qualité

    notifyListeners();
    _eventStream.add(VideoEvent.qualityChanged(quality));
  }

  /// Entre/sort du mode plein écran
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
    _eventStream.add(
      _isFullScreen
          ? VideoEvent.fullScreenEntered()
          : VideoEvent.fullScreenExited(),
    );
  }

  /// Affiche/masque les contrôles
  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  /// Réessaie en cas d'erreur
  Future<void> retry() async {
    if (currentVideo != null) {
      await initializeVideo(
        url: currentVideo!.url,
        title: currentVideo!.title,
        description: currentVideo!.description,
        thumbnail: currentVideo!.thumbnail,
        autoPlay: true,
      );
    }
  }

  /// Formate une durée en string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ========== MÉTHODES PRIVÉES ==========

  Future<VideoPlayerController> _createVideoController({
    required String url,
    required VideoSourceType sourceType,
    Map<String, String>? headers,
  }) async {
    switch (sourceType) {
      case VideoSourceType.network:
        return VideoPlayerController.networkUrl(
          Uri.parse(url),
          httpHeaders: headers ?? _defaultHeaders(),
        );
      case VideoSourceType.file:
        return VideoPlayerController.file(File(url));
      case VideoSourceType.asset:
        return VideoPlayerController.asset(url);
    }
  }

  Future<void> _createChewieController({
    String? title,
    String? description,
    String? thumbnail,
    bool autoPlay = false,
  }) async {
    // Widget de placeholder
    final placeholder = _buildPlaceholder(
      title: title,
      description: description,
      thumbnail: thumbnail,
    );

    // Widget d'overlay
    final overlay = _buildOverlay(title: title);

    // Créer le contrôleur
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: autoPlay,
      looping: _isLooping,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      allowedScreenSleep: false,
      showControlsOnInitialize: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF7DBBC3),
        handleColor: const Color(0xFF7DBBC3),
        bufferedColor: const Color(0xFF7DBBC3).withOpacity(0.3),
        backgroundColor: Colors.grey.shade300,
      ),
      placeholder: placeholder,
      overlay: overlay,
      // Pour Chewie 1.7.0, on utilise customControls
      customControls: const MaterialControls(),
    );
  }

  void _recreateChewieController() {
    if (_chewieController != null && _videoController != null) {
      final oldController = _chewieController!;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: oldController.autoPlay,
        looping: _isLooping,
        allowFullScreen: oldController.allowFullScreen,
        allowMuting: oldController.allowMuting,
        allowPlaybackSpeedChanging: oldController.allowPlaybackSpeedChanging,
        allowedScreenSleep: oldController.allowedScreenSleep,
        showControlsOnInitialize: oldController.showControlsOnInitialize,
        materialProgressColors: oldController.materialProgressColors,
        placeholder: oldController.placeholder,
        overlay: oldController.overlay,
        customControls: oldController.customControls,
      );

      // Disposer l'ancien contrôleur
      oldController.dispose();
    }
  }

  void _setupVideoListeners() {
    _videoController!.addListener(_videoListener);
  }

  void _videoListener() {
    _updateVideoState();
    _updatePosition();
    _checkForBuffering();
    _checkForEnd();
  }

  void _updateVideoState() {
    if (_videoController == null) return;

    final value = _videoController!.value;

    if (value.hasError) {
      _handleError(value.errorDescription ?? 'Unknown error');
      return;
    }

    if (value.isBuffering) {
      _isBuffering = true;
    } else if (_isBuffering) {
      _isBuffering = false;
    }

    if (value.isPlaying && _state != VideoState.playing) {
      _updateState(VideoState.playing);
    } else if (!value.isPlaying &&
        !value.isBuffering &&
        _state == VideoState.playing) {
      _updateState(VideoState.paused);
    }
  }

  void _updatePosition() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      _position = _videoController!.value.position;
      _duration = _videoController!.value.duration;

      // Événement de progression
      _eventStream.add(
        VideoEvent.progress(
          position: _position,
          duration: _duration,
          buffered: _videoController!.value.buffered,
        ),
      );

      notifyListeners();
    }
  }

  void _checkForBuffering() {
    if (_videoController != null) {
      final wasBuffering = _isBuffering;
      _isBuffering = _videoController!.value.isBuffering;

      if (wasBuffering != _isBuffering) {
        notifyListeners();
        _eventStream.add(
          _isBuffering
              ? VideoEvent.bufferingStarted()
              : VideoEvent.bufferingEnded(),
        );
      }
    }
  }

  void _checkForEnd() {
    if (_videoController != null &&
        _videoController!.value.position >= _videoController!.value.duration &&
        _videoController!.value.duration > Duration.zero) {
      _eventStream.add(VideoEvent.ended());

      if (_isLooping) {
        seekTo(Duration.zero);
        play();
      } else {
        _updateState(VideoState.ended);
      }
    }
  }

  void _updateState(VideoState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
      _eventStream.add(VideoEvent.stateChanged(newState));
    }
  }

  void _handleError(String message) {
    _errorMessage = message;
    _updateState(VideoState.error);
    _eventStream.add(VideoEvent.error(message));
    debugPrint('VideoManager Error: $message');
  }

  Future<void> _safeDispose() async {
    // Arrêter les statistiques
    _stopWatchStatistics();

    // Retirer les écouteurs
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
    }

    // Disposer ChewieController
    if (_chewieController != null) {
      try {
        // Ne pas attendre la disposition du ChewieController
        final chewie = _chewieController;
        _chewieController = null;
        // Appeler dispose sans attendre
        chewie?.dispose();
      } catch (e) {
        debugPrint('Error disposing ChewieController: $e');
      } finally {
        _chewieController = null;
      }
    }

    // Disposer VideoPlayerController
    if (_videoController != null) {
      try {
        await _videoController!.dispose();
      } catch (e) {
        debugPrint('Error disposing VideoPlayerController: $e');
      } finally {
        _videoController = null;
      }
    }

    // Réinitialiser l'état
    _position = Duration.zero;
    _duration = Duration.zero;
    _isBuffering = false;
    _errorMessage = null;
  }

  Widget _buildPlaceholder({
    String? title,
    String? description,
    String? thumbnail,
  }) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnail != null)
            Image.network(
              thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF7DBBC3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildOverlay({String? title}) {
    if (title == null) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2)),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeDefaultQualities() {
    _qualities = [
      VideoQuality(id: 'auto', label: 'Auto', value: null),
      VideoQuality(id: '360', label: '360p', value: '360'),
      VideoQuality(id: '480', label: '480p', value: '480'),
      VideoQuality(id: '720', label: '720p HD', value: '720'),
      VideoQuality(id: '1080', label: '1080p Full HD', value: '1080'),
    ];
    _selectedQuality = _qualities.first;
  }

  Map<String, String> _defaultHeaders() {
    return {
      'User-Agent': 'MoodiaApp/1.0',
      'Accept': 'video/mp4,video/webm',
      'Accept-Language': 'fr-FR,fr;q=0.9',
    };
  }

  void _startWatchStatistics(String videoId) {
    _stopWatchStatistics();
    _startWatchTime = DateTime.now();

    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_videoController != null && _videoController!.value.isPlaying) {
        final stats = _videoStats[videoId] ?? VideoStats(videoId: videoId);
        stats.watchDuration = stats.watchDuration + const Duration(seconds: 1);
        _videoStats[videoId] = stats;
      }
    });
  }

  void _stopWatchStatistics() {
    _watchTimer?.cancel();
    _watchTimer = null;

    if (_startWatchTime != null) {
      final watchTime = DateTime.now().difference(_startWatchTime!);
      _startWatchTime = null;

      // Sauvegarder les statistiques
      _saveStats();
    }
  }

  void _loadSavedStats() {
    // TODO: Implémenter le chargement depuis SharedPreferences
  }

  void _saveStats() {
    // TODO: Implémenter la sauvegarde vers SharedPreferences
  }

  // ========== DISPOSE ==========
  @override
  void dispose() {
    _eventStream.close();
    _safeDispose();
    super.dispose();
  }
}

// ========== CLASSES DE DONNÉES ==========

enum VideoState {
  idle,
  initializing,
  ready,
  playing,
  paused,
  buffering,
  ended,
  error,
}

enum VideoSourceType { network, file, asset }

class VideoSource {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? thumbnail;
  final Duration duration;
  final VideoSourceType type;
  final DateTime? addedAt;

  VideoSource({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.thumbnail,
    required this.duration,
    this.type = VideoSourceType.network,
    this.addedAt,
  });
}

class VideoQuality {
  final String id;
  final String label;
  final String? value;

  VideoQuality({required this.id, required this.label, this.value});
}

class SubtitleTrack {
  final String id;
  final String language;
  final String label;
  final String url;

  SubtitleTrack({
    required this.id,
    required this.language,
    required this.label,
    required this.url,
  });
}

class VideoStats {
  final String videoId;
  Duration watchDuration;
  int playCount;
  DateTime? lastWatched;

  VideoStats({
    required this.videoId,
    this.watchDuration = Duration.zero,
    this.playCount = 0,
    this.lastWatched,
  });
}

// ========== ÉVÉNEMENTS ==========

abstract class VideoEvent {
  final String type;
  final dynamic data;

  VideoEvent(this.type, [this.data]);

  factory VideoEvent.initialized({
    required String videoId,
    required Duration duration,
    required List<VideoQuality> qualities,
  }) = InitializedEvent;

  factory VideoEvent.playing() = PlayingEvent;
  factory VideoEvent.paused() = PausedEvent;
  factory VideoEvent.ended() = EndedEvent;
  factory VideoEvent.seeked(Duration position) = SeekedEvent;
  factory VideoEvent.volumeChanged(double volume) = VolumeChangedEvent;
  factory VideoEvent.muted() = MutedEvent;
  factory VideoEvent.unmuted() = UnmutedEvent;
  factory VideoEvent.playbackSpeedChanged(double speed) =
      PlaybackSpeedChangedEvent;
  factory VideoEvent.loopEnabled() = LoopEnabledEvent;
  factory VideoEvent.loopDisabled() = LoopDisabledEvent;
  factory VideoEvent.subtitlesEnabled() = SubtitlesEnabledEvent;
  factory VideoEvent.subtitlesDisabled() = SubtitlesDisabledEvent;
  factory VideoEvent.qualityChanged(VideoQuality quality) = QualityChangedEvent;
  factory VideoEvent.fullScreenEntered() = FullScreenEnteredEvent;
  factory VideoEvent.fullScreenExited() = FullScreenExitedEvent;
  factory VideoEvent.bufferingStarted() = BufferingStartedEvent;
  factory VideoEvent.bufferingEnded() = BufferingEndedEvent;
  factory VideoEvent.stateChanged(VideoState state) = StateChangedEvent;
  factory VideoEvent.playlistUpdated({
    required List<VideoSource> playlist,
    VideoSource? addedVideo,
    VideoSource? removedVideo,
  }) = PlaylistUpdatedEvent;
  factory VideoEvent.progress({
    required Duration position,
    required Duration duration,
    required List<DurationRange> buffered,
  }) = ProgressEvent;
  factory VideoEvent.error(String message) = ErrorEvent;
}

class InitializedEvent extends VideoEvent {
  InitializedEvent({
    required String videoId,
    required Duration duration,
    required List<VideoQuality> qualities,
  }) : super('initialized', {
         'videoId': videoId,
         'duration': duration,
         'qualities': qualities,
       });
}

class PlayingEvent extends VideoEvent {
  PlayingEvent() : super('playing');
}

class PausedEvent extends VideoEvent {
  PausedEvent() : super('paused');
}

class EndedEvent extends VideoEvent {
  EndedEvent() : super('ended');
}

class SeekedEvent extends VideoEvent {
  SeekedEvent(Duration position) : super('seeked', {'position': position});
}

class VolumeChangedEvent extends VideoEvent {
  VolumeChangedEvent(double volume)
    : super('volumeChanged', {'volume': volume});
}

class MutedEvent extends VideoEvent {
  MutedEvent() : super('muted');
}

class UnmutedEvent extends VideoEvent {
  UnmutedEvent() : super('unmuted');
}

class PlaybackSpeedChangedEvent extends VideoEvent {
  PlaybackSpeedChangedEvent(double speed)
    : super('playbackSpeedChanged', {'speed': speed});
}

class LoopEnabledEvent extends VideoEvent {
  LoopEnabledEvent() : super('loopEnabled');
}

class LoopDisabledEvent extends VideoEvent {
  LoopDisabledEvent() : super('loopDisabled');
}

class SubtitlesEnabledEvent extends VideoEvent {
  SubtitlesEnabledEvent() : super('subtitlesEnabled');
}

class SubtitlesDisabledEvent extends VideoEvent {
  SubtitlesDisabledEvent() : super('subtitlesDisabled');
}

class QualityChangedEvent extends VideoEvent {
  QualityChangedEvent(VideoQuality quality)
    : super('qualityChanged', {'quality': quality});
}

class FullScreenEnteredEvent extends VideoEvent {
  FullScreenEnteredEvent() : super('fullScreenEntered');
}

class FullScreenExitedEvent extends VideoEvent {
  FullScreenExitedEvent() : super('fullScreenExited');
}

class BufferingStartedEvent extends VideoEvent {
  BufferingStartedEvent() : super('bufferingStarted');
}

class BufferingEndedEvent extends VideoEvent {
  BufferingEndedEvent() : super('bufferingEnded');
}

class StateChangedEvent extends VideoEvent {
  StateChangedEvent(VideoState state) : super('stateChanged', {'state': state});
}

class PlaylistUpdatedEvent extends VideoEvent {
  PlaylistUpdatedEvent({
    required List<VideoSource> playlist,
    VideoSource? addedVideo,
    VideoSource? removedVideo,
  }) : super('playlistUpdated', {
         'playlist': playlist,
         'addedVideo': addedVideo,
         'removedVideo': removedVideo,
       });
}

class ProgressEvent extends VideoEvent {
  ProgressEvent({
    required Duration position,
    required Duration duration,
    required List<DurationRange> buffered,
  }) : super('progress', {
         'position': position,
         'duration': duration,
         'buffered': buffered,
       });
}

class ErrorEvent extends VideoEvent {
  ErrorEvent(String message) : super('error', {'message': message});
}
