import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/video_manager.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? description;
  final String? thumbnail;
  final bool autoPlay;
  final Duration startAt;
  final Map<String, String>? headers;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.title,
    this.description,
    this.thumbnail,
    this.autoPlay = false,
    this.startAt = Duration.zero,
    this.headers,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoManager _videoManager;
  StreamSubscription<VideoEvent>? _eventSubscription;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _videoManager = VideoManager();
    _initializeVideo();
    _setupEventListeners();
  }

  Future<void> _initializeVideo() async {
    try {
      if (mounted) {
        setState(() => _isInitializing = true);
      }

      await _videoManager.initializeVideo(
        url: widget.videoUrl,
        title: widget.title,
        description: widget.description,
        thumbnail: widget.thumbnail,
        autoPlay: widget.autoPlay,
        startAt: widget.startAt,
        headers: widget.headers,
      );

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      debugPrint('Failed to initialize video: $error');
    }
  }

  void _setupEventListeners() {
    _eventSubscription = _videoManager.events.listen((event) {
      switch (event.type) {
        case 'error':
          _showErrorSnackbar(event.data['message']);
          break;
        case 'ended':
          if (!_videoManager.isLooping) {
            _showInfoSnackbar('Video ended');
          }
          break;
        case 'bufferingStarted':
          debugPrint('Buffering started');
          break;
        case 'bufferingEnded':
          debugPrint('Buffering ended');
          break;
      }
    });
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $message'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _initializeVideo(),
          ),
        ),
      );
    }
  }

  void _showInfoSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si l'URL a changé, recharger la vidéo
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.startAt != widget.startAt) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _videoManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _videoManager,
      child: Consumer<VideoManager>(
        builder: (context, manager, child) {
          return _buildVideoPlayer(context, manager);
        },
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context, VideoManager manager) {
    // État d'erreur
    if (manager.hasError) {
      return _buildErrorView(manager);
    }

    // État d'initialisation
    if (_isInitializing || manager.state == VideoState.initializing) {
      return _buildLoadingView();
    }

    // Pas encore initialisé
    if (manager.chewieController == null || !manager.isReady) {
      return _buildLoadingView();
    }

    // Vidéo prête
    return Stack(
      fit: StackFit.expand,
      children: [
        // Lecteur Chewie principal
        Chewie(controller: manager.chewieController!),

        // Overlay avec contrôles personnalisés
        if (manager.showControls)
          Positioned.fill(child: _buildCustomControlsOverlay(context, manager)),
      ],
    );
  }

  Widget _buildCustomControlsOverlay(
    BuildContext context,
    VideoManager manager,
  ) {
    return GestureDetector(
      onTap: () => manager.toggleControls(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            // En-tête avec titre et bouton plein écran
            _buildHeader(context, manager),

            // Espace central pour les contrôles de lecture
            Expanded(child: Center(child: _buildPlayPauseOverlay(manager))),

            // Pied avec barre de progression et contrôles
            _buildFooter(context, manager),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VideoManager manager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Titre de la vidéo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.description != null)
                  Text(
                    widget.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Bouton plein écran
          IconButton(
            icon: Icon(
              manager.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 24,
            ),
            onPressed: manager.toggleFullScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseOverlay(VideoManager manager) {
    return AnimatedOpacity(
      opacity: manager.isPlaying ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: manager.togglePlayPause,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            manager.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, VideoManager manager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Barre de progression
          _buildProgressBar(context, manager),

          const SizedBox(height: 12),

          // Contrôles principaux
          Row(
            children: [
              // Play/Pause
              IconButton(
                icon: Icon(
                  manager.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: manager.togglePlayPause,
              ),

              // Volume
              IconButton(
                icon: Icon(
                  manager.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: manager.toggleMute,
              ),

              // Temps écoulé
              Text(
                VideoManager.formatDuration(manager.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),

              const Spacer(),

              // Temps total
              Text(
                VideoManager.formatDuration(manager.duration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),

              const SizedBox(width: 16),

              // Boucle
              IconButton(
                icon: Icon(
                  Icons.loop,
                  color: manager.isLooping
                      ? const Color(0xFF7DBBC3)
                      : Colors.white,
                  size: 20,
                ),
                onPressed: manager.toggleLoop,
              ),

              // Menu d'options
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
                onSelected: (value) => _handleOptionSelected(value, manager),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'speed',
                    child: Row(
                      children: [
                        const Icon(Icons.speed, size: 20),
                        const SizedBox(width: 8),
                        const Text('Speed'),
                        const Spacer(),
                        Text('${manager.playbackSpeed}x'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'quality',
                    child: Row(
                      children: [
                        const Icon(Icons.hd, size: 20),
                        const SizedBox(width: 8),
                        const Text('Quality'),
                        const Spacer(),
                        Text(manager.selectedQuality?.label ?? 'Auto'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'subtitles',
                    child: Row(
                      children: [
                        const Icon(Icons.subtitles, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          manager.showSubtitles
                              ? 'Hide Subtitles'
                              : 'Show Subtitles',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, VideoManager manager) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFF7DBBC3),
        inactiveTrackColor: Colors.white.withOpacity(0.3),
        thumbColor: const Color(0xFF7DBBC3),
        overlayColor: const Color(0xFF7DBBC3).withOpacity(0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      ),
      child: Slider(
        value: manager.position.inSeconds.toDouble(),
        min: 0,
        max: manager.duration.inSeconds > 0
            ? manager.duration.inSeconds.toDouble()
            : 1,
        onChangeStart: (_) {
          // Optionnel: Mettre en pause pendant le drag
        },
        onChanged: (value) {
          // Mettre à jour la position pendant le drag
          manager.seekTo(Duration(seconds: value.toInt()));
        },
        onChangeEnd: (value) {
          // Optionnel: Reprendre la lecture après le drag
        },
      ),
    );
  }

  void _handleOptionSelected(String value, VideoManager manager) {
    switch (value) {
      case 'speed':
        _showPlaybackSpeedDialog(context, manager);
        break;
      case 'quality':
        _showQualityDialog(context, manager);
        break;
      case 'subtitles':
        manager.toggleSubtitles();
        break;
    }
  }

  void _showPlaybackSpeedDialog(BuildContext context, VideoManager manager) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: speeds.length,
            itemBuilder: (context, index) {
              final speed = speeds[index];
              return ListTile(
                leading: Radio<double>(
                  value: speed,
                  groupValue: manager.playbackSpeed,
                  onChanged: (value) {
                    if (value != null) {
                      manager.setPlaybackSpeed(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                title: Text('${speed}x'),
                onTap: () {
                  manager.setPlaybackSpeed(speed);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showQualityDialog(BuildContext context, VideoManager manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Quality'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: manager.qualities.length,
            itemBuilder: (context, index) {
              final quality = manager.qualities[index];
              return ListTile(
                leading: Radio<VideoQuality>(
                  value: quality,
                  groupValue: manager.selectedQuality,
                  onChanged: (value) {
                    if (value != null) {
                      manager.setQuality(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                title: Text(quality.label),
                onTap: () {
                  manager.setQuality(quality);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7DBBC3)),
            ),
            const SizedBox(height: 20),
            if (widget.title != null)
              Text(
                widget.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            if (_isInitializing) const SizedBox(height: 10),
            if (_isInitializing)
              const Text(
                'Loading video...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(VideoManager manager) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Failed to load video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (manager.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  manager.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _initializeVideo(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7DBBC3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget de connexion rapide (si vous utilisez Provider globalement)
class ConnectedVideoPlayerWidget extends StatelessWidget {
  final String videoUrl;
  final String? title;
  final String? description;
  final String? thumbnail;
  final bool autoPlay;
  final Duration startAt;
  final Map<String, String>? headers;

  const ConnectedVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.title,
    this.description,
    this.thumbnail,
    this.autoPlay = false,
    this.startAt = Duration.zero,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return VideoPlayerWidget(
      videoUrl: videoUrl,
      title: title,
      description: description,
      thumbnail: thumbnail,
      autoPlay: autoPlay,
      startAt: startAt,
      headers: headers,
    );
  }
}
