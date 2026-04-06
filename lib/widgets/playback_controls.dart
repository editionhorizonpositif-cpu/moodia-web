// lib/widgets/playback_controls.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart';
import '../services/playback_manager.dart';

class AudioControls extends StatefulWidget {
  final PlaybackManager playbackManager;
  final bool showTitle;
  final bool showVolumeControls;

  const AudioControls({
    super.key,
    required this.playbackManager,
    this.showTitle = true,
    this.showVolumeControls = true,
  });

  @override
  State<AudioControls> createState() => _AudioControlsState();
}

class _AudioControlsState extends State<AudioControls> {
  @override
  void initState() {
    super.initState();
    // Écouter les changements d'état
    widget.playbackManager.addListener(_onPlaybackManagerChanged);
  }

  @override
  void dispose() {
    // Retirer l'écouteur
    widget.playbackManager.removeListener(_onPlaybackManagerChanged);
    super.dispose();
  }

  void _onPlaybackManagerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre (optionnel)
          if (widget.showTitle &&
              widget.playbackManager.currentMeditation != null)
            _buildTitle(),

          // Barre de progression
          _buildProgressBar(),
          const SizedBox(height: 16),

          // Contrôles principaux
          _buildMainControls(),
          const SizedBox(height: 12),

          // Contrôles secondaires (volume, etc.)
          if (widget.showVolumeControls) _buildSecondaryControls(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final meditation = widget.playbackManager.currentMeditation;
    if (meditation == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            meditation.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (meditation.instructorName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Par ${meditation.instructorName!}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final duration = widget.playbackManager.duration;
    final position = widget.playbackManager.position;
    final progress = widget.playbackManager.progress;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF7DBBC3),
            inactiveTrackColor: Colors.grey.shade600,
            thumbColor: const Color(0xFF7DBBC3),
            overlayColor: const Color(0xFF7DBBC3).withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              if (duration.inSeconds > 0) {
                final newPosition = Duration(
                  seconds: (duration.inSeconds * value).toInt(),
                );
                widget.playbackManager.seek(newPosition);
              }
            },
            onChangeStart: (_) {},
            onChangeEnd: (_) {},
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PlaybackManager.formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                PlaybackManager.formatDuration(duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls() {
    final isPlaying = widget.playbackManager.isPlaying;
    final isLoading = widget.playbackManager.isLoading;
    final hasError = widget.playbackManager.hasError;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Reculer 10s
        IconButton(
          icon: const Icon(Icons.replay_10, size: 28),
          color: Colors.white,
          onPressed: () =>
              widget.playbackManager.rewind(const Duration(seconds: 10)),
        ),

        // Play/Pause
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError ? Colors.red : const Color(0xFF7DBBC3),
          ),
          child: IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    hasError
                        ? Icons.error
                        : (isPlaying ? Icons.pause : Icons.play_arrow),
                    size: 32,
                    color: Colors.white,
                  ),
            onPressed: hasError
                ? () {
                    // Recharger en cas d'erreur
                    if (widget.playbackManager.currentMeditation != null) {
                      widget.playbackManager.loadAndPlayMeditation(
                        widget.playbackManager.currentMeditation!,
                        autoPlay: true,
                      );
                    }
                  }
                : widget.playbackManager.togglePlayPause,
          ),
        ),

        // Avancer 10s
        IconButton(
          icon: const Icon(Icons.forward_10, size: 28),
          color: Colors.white,
          onPressed: () =>
              widget.playbackManager.forward(const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // État
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStateText(),
            style: TextStyle(
              color: _getStateColor(),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Volume
        Row(
          children: [
            IconButton(
              icon: Icon(
                widget.playbackManager.isMuted
                    ? Icons.volume_off
                    : widget.playbackManager.volume > 0.5
                    ? Icons.volume_up
                    : Icons.volume_down,
                size: 20,
                color: Colors.white,
              ),
              onPressed: widget.playbackManager.toggleMute,
            ),
            SizedBox(
              width: 80,
              child: Slider(
                value: widget.playbackManager.volume,
                onChanged: (value) => widget.playbackManager.setVolume(value),
                min: 0.0,
                max: 1.0,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getStateText() {
    switch (widget.playbackManager.state) {
      case PlaybackState.playing:
        return 'Lecture';
      case PlaybackState.paused:
        return 'Pause';
      case PlaybackState.loading:
        return 'Chargement...';
      case PlaybackState.error:
        return 'Erreur';
      case PlaybackState.completed:
        return 'Terminé';
      default:
        return 'Prêt';
    }
  }

  Color _getStateColor() {
    switch (widget.playbackManager.state) {
      case PlaybackState.playing:
        return Colors.green;
      case PlaybackState.error:
        return Colors.red;
      case PlaybackState.loading:
        return Colors.orange;
      case PlaybackState.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Version minimale pour les écrans compacts
class MiniAudioControls extends StatefulWidget {
  final PlaybackManager playbackManager;

  const MiniAudioControls({super.key, required this.playbackManager});

  @override
  State<MiniAudioControls> createState() => _MiniAudioControlsState();
}

class _MiniAudioControlsState extends State<MiniAudioControls> {
  @override
  void initState() {
    super.initState();
    widget.playbackManager.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.playbackManager.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withOpacity(0.9),
      child: Row(
        children: [
          // Bouton play/pause
          IconButton(
            icon: Icon(
              widget.playbackManager.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
            onPressed: widget.playbackManager.togglePlayPause,
          ),

          const SizedBox(width: 12),

          // Titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.playbackManager.currentMeditation != null)
                  Text(
                    widget.playbackManager.currentMeditation!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  '${PlaybackManager.formatDuration(widget.playbackManager.position)} / '
                  '${PlaybackManager.formatDuration(widget.playbackManager.duration)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Volume
          IconButton(
            icon: Icon(
              widget.playbackManager.isMuted
                  ? Icons.volume_off
                  : Icons.volume_up,
              color: Colors.white,
              size: 20,
            ),
            onPressed: widget.playbackManager.toggleMute,
          ),
        ],
      ),
    );
  }
}

// Overlay flottant pour la lecture en arrière-plan
class FloatingAudioControls extends StatefulWidget {
  final PlaybackManager playbackManager;
  final VoidCallback? onTap;

  const FloatingAudioControls({
    super.key,
    required this.playbackManager,
    this.onTap,
  });

  @override
  State<FloatingAudioControls> createState() => _FloatingAudioControlsState();
}

class _FloatingAudioControlsState extends State<FloatingAudioControls> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    widget.playbackManager.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.playbackManager.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isExpanded) {
          setState(() => _isExpanded = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _isExpanded = false);
            }
          });
        }
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isExpanded ? 200 : 60,
        height: 60,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
      ),
    );
  }

  Widget _buildCollapsed() {
    return IconButton(
      icon: Icon(
        widget.playbackManager.isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
      ),
      onPressed: widget.playbackManager.togglePlayPause,
    );
  }

  Widget _buildExpanded() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            widget.playbackManager.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          onPressed: widget.playbackManager.togglePlayPause,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.playbackManager.currentMeditation != null)
                  Text(
                    widget.playbackManager.currentMeditation!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  PlaybackManager.formatDuration(
                    widget.playbackManager.position,
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 18),
          onPressed: () => widget.playbackManager.stop(),
        ),
      ],
    );
  }
}

// Version simple pour intégration rapide
class SimpleAudioControls extends StatefulWidget {
  final PlaybackManager playbackManager;

  const SimpleAudioControls({super.key, required this.playbackManager});

  @override
  State<SimpleAudioControls> createState() => _SimpleAudioControlsState();
}

class _SimpleAudioControlsState extends State<SimpleAudioControls> {
  @override
  void initState() {
    super.initState();
    widget.playbackManager.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.playbackManager.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.playbackManager.progress.clamp(0.0, 1.0);
    final duration = widget.playbackManager.duration;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de progression
          Slider(
            value: progress,
            onChanged: (value) {
              final position = Duration(
                seconds: (duration.inSeconds * value).toInt(),
              );
              widget.playbackManager.seek(position);
            },
            activeColor: const Color(0xFF7DBBC3),
            inactiveColor: Colors.grey.shade300,
          ),

          // Temps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  PlaybackManager.formatDuration(
                    widget.playbackManager.position,
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  PlaybackManager.formatDuration(duration),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Boutons de contrôle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () =>
                    widget.playbackManager.rewind(const Duration(seconds: 10)),
                tooltip: 'Reculer 10 secondes',
              ),

              IconButton(
                icon: Icon(
                  widget.playbackManager.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 40,
                  color: const Color(0xFF7DBBC3),
                ),
                onPressed: widget.playbackManager.togglePlayPause,
                tooltip: widget.playbackManager.isPlaying ? 'Pause' : 'Play',
              ),

              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () =>
                    widget.playbackManager.forward(const Duration(seconds: 10)),
                tooltip: 'Avancer 10 secondes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
