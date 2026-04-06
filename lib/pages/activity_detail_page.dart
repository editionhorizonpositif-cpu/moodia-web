// lib/pages/activity_detail_page.dart - Version finale avec cache persistant des images et Lottie (corrigé)
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../models/activity.dart';
import '../models/activity_dtos.dart';
import '../models/meditation.dart';
import '../services/activity_api_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/playback_manager.dart';
import '../services/media_cache_service.dart';
import '../services/meditation_service.dart';
import '../services/media_service.dart';
import '../services/completion_service.dart';
import '../widgets/playback_controls.dart';
import '../services/device_info_service.dart';
import 'package:geolocator/geolocator.dart';

class ActivityDetailPage extends StatefulWidget {
  final Activity activity;
  final bool forceRefresh;

  const ActivityDetailPage({
    super.key,
    required this.activity,
    this.forceRefresh = false,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late ActivityApiService _activityService;
  late AuthService _authService;
  late ApiService _apiService;
  late MediaCacheService _mediaCache;
  late MeditationService _meditationService;
  MediaService? _mediaService;

  late Activity _activity;
  bool _isLoadingActivity = false;

  // ========== ÉTATS GÉNÉRAUX ==========
  bool _isLoading = false;
  bool _isFavorite = false;
  bool _isCompleted = false;
  bool _isInProgress = false;
  int _progressPercentage = 0;
  int? _userRating;
  String? _userFeedback;

  // ========== CONNECTIVITÉ ==========
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // ========== ANIMATIONS ==========
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _colorAnimation;
  bool _autoCompleted = false;

  // ========== SECTION EXPANSION ==========
  final Map<String, bool> _expandedSections = {
    'instructions': false,
    'prerequisites': false,
    'benefits': false,
    'configuration': false,
  };

  // ========== CONFIGURATION ==========
  Map<String, dynamic>? _configuration;

  // ========== SCROLL ==========
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;
  bool _showFullAppBar = false;

  // ========== ÉVALUATION ==========
  bool _showRatingDialog = false;
  final TextEditingController _feedbackController = TextEditingController();
  double _selectedRating = 0.0;
  int? _difficultyPerception;
  int? _enjoymentScore;

  // ========== HEADERS AUTH ==========
  int? _userId;

  // ========== COVER IMAGE (avec cache fichier) ==========
  String? _cachedCoverImagePath;
  bool _isLoadingCoverImage = false;

  // ========== LOTTIE ANIMATION (avec cache fichier) ==========
  int? _lottieAssetId;
  String? _cachedLottiePath;
  bool _isLoadingLottie = false;
  bool _showLottieFullscreen = false;

  // ========== AUDIO/VIDEO GUIDE ==========
  int? _mediaAssetId;
  String? _mediaUrl;
  String? _cachedMediaPath;
  bool _hasMedia = false;
  bool _isMediaLoading = false;
  String? _mediaType;
  bool _isCached = false;
  bool _isDownloading = false;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showVideoControls = true;
  Timer? _hideControlsTimer;

  bool _isDisposed = false;
  PlaybackManager? _playbackManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _activity = widget.activity;
    _isFavorite = _activity.isFavorite ?? false;
    _isCompleted = _activity.isCompleted ?? false;
    _isInProgress = _activity.isInProgress ?? false;
    _progressPercentage = _activity.progressPercentage ?? 0;
    _userRating = _activity.userRating;
    _userFeedback = _activity.userFeedback;

    _apiService = ApiService();
    _mediaCache = MediaCacheService();
    _mediaCache.initialize();
    _meditationService = MeditationService(_apiService);
    _mediaService = Provider.of<MediaService>(context, listen: false);

    _initConnectivity();

    _loadUserId()
        .then((_) {
          if (mounted) {
            _preloadCoverImage();
            _preloadLottie();
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _isLoadingCoverImage = false;
              _isLoadingLottie = false;
            });
          }
        });

    _buildMediaIds();
    _loadCachedMedia();
    _loadMediaType();

    if (_activity.configuration != null) {
      _configuration = Map<String, dynamic>.from(_activity.configuration!);
    }

    _initAnimations();

    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final newOpacity = (offset / 100).clamp(0.0, 1.0);
      final newShowFullAppBar = offset > 50;

      if (newOpacity != _appBarOpacity ||
          newShowFullAppBar != _showFullAppBar) {
        setState(() {
          _appBarOpacity = newOpacity;
          _showFullAppBar = newShowFullAppBar;
        });
      }
    });

    if (widget.forceRefresh) {
      _refreshActivity();
    }
  }

  // ========== CONNECTIVITÉ ==========
  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateOnlineStatus(result);

      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        ConnectivityResult result,
      ) {
        if (mounted) _updateOnlineStatus(result);
      });
    } catch (e) {
      debugPrint('Erreur initialisation connectivité: $e');
      setState(() {
        _isOnline = false;
      });
    }
  }

  void _updateOnlineStatus(ConnectivityResult result) {
    final hasInternet = result != ConnectivityResult.none;
    if (mounted) {
      setState(() {
        _isOnline = hasInternet;
      });
    }
    if (kDebugMode)
      print('État connexion: ${hasInternet ? "En ligne" : "Hors ligne"}');
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    if (mounted) setState(() {});
  }

  Future<Map<String, dynamic>> _buildCompletionMetadata() async {
    final deviceData = await DeviceInfoService.getDeviceMetadata();
    return {
      'appVersion': deviceData['appVersion'],
      'osVersion': deviceData['osVersion'],
      'deviceModel': deviceData['deviceModel'],
      'networkType': deviceData['networkType'],
      'batteryLevel': deviceData['batteryLevel'],
      'locationLat': deviceData['locationLat'],
      'locationLng': deviceData['locationLng'],
      'ambientNoiseLevel': 5,
      'timeOfDay': _getCurrentTimeOfDay(),
      'moodBefore': 'calme',
      'moodAfter': 'détendu',
      'screenBrightness': 15,
      'headphonesConnected': false,
      'appState': 'foreground',
      'interruptions': 0,
      'ambientLightLevel': 'dark',
      'weatherCondition': 'clear',
      'temperature': 19,
      'heartRateBefore': 78,
      'heartRateAfter': 64,
    };
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  Future<String> _getDeviceId() async {
    const String key = 'device_unique_id';
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(key);
    if (id == null) {
      // Générer un UUID simple
      id = 'flutter_${DateTime.now().millisecondsSinceEpoch}_${_userId ?? 0}';
      await prefs.setString(key, id);
    }
    return id;
  }

  String _getCurrentTimeOfDay() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _buildMediaIds() {
    _mediaAssetId = _activity.audioGuideAssetId;
    _hasMedia =
        _mediaAssetId != null ||
        (_activity.audioGuideUrl != null &&
            _activity.audioGuideUrl!.isNotEmpty);

    if (_mediaAssetId != null) {
      _mediaUrl = '${ApiService.baseUrl}/media/$_mediaAssetId/stream';
    } else if (_activity.audioGuideUrl != null &&
        _activity.audioGuideUrl!.isNotEmpty) {
      _mediaUrl = _activity.audioGuideUrl;
    }

    _lottieAssetId = _activity.lottieAnimationAssetId;
  }

  Future<void> _loadMediaType() async {
    if (_mediaAssetId == null) {
      setState(() => _mediaType = 'AUDIO');
      return;
    }

    try {
      final mediaType = await _meditationService.getMediaType(_mediaAssetId!);
      if (!_isDisposed && mounted) {
        setState(() => _mediaType = mediaType);
      } else {
        _mediaType = mediaType;
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur détection type média: $e');
      if (!_isDisposed && mounted) {
        setState(() => _mediaType = 'AUDIO');
      } else {
        _mediaType = 'AUDIO';
      }
    }
  }

  Future<void> _loadCachedMedia() async {
    if (_mediaAssetId != null) {
      final isCached = await _mediaCache.isCached(_mediaAssetId!);
      if (mounted) setState(() => _isCached = isCached);
      if (isCached) {
        _cachedMediaPath = await _mediaCache.getMediaPath(_mediaAssetId!);
        if (kDebugMode && _cachedMediaPath != null) {
          print('📦 Média trouvé en cache: $_cachedMediaPath');
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _checkIfCached() async {
    if (_mediaAssetId == null) return;
    final isCached = await _mediaCache.isCached(_mediaAssetId!);
    if (!_isDisposed && mounted) {
      setState(() => _isCached = isCached);
    }
  }

  // ========== CACHE DES IMAGES ET LOTTIE ==========
  Future<Directory> _getImageCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/image_cache');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  Future<String?> _getCachedCoverImagePath(int assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('cached_cover_image_$assetId');
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  Future<void> _cacheCoverImage(int assetId, String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final imageDir = await _getImageCacheDirectory();
        final fileName = 'cover_$assetId.jpg';
        final file = File('${imageDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_cover_image_$assetId', file.path);
        if (kDebugMode)
          print('🖼️ Image de couverture mise en cache pour $assetId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Échec cache image: $e');
    }
  }

  Future<String?> _getCachedLottiePath(int assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('cached_lottie_$assetId');
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  Future<void> _cacheLottie(int assetId, String lottieUrl) async {
    try {
      final response = await http.get(Uri.parse(lottieUrl));
      if (response.statusCode == 200) {
        final imageDir = await _getImageCacheDirectory();
        final fileName = 'lottie_$assetId.json';
        final file = File('${imageDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_lottie_$assetId', file.path);
        if (kDebugMode) print('🎬 Lottie mise en cache pour $assetId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Échec cache Lottie: $e');
    }
  }

  // ========== PRÉCHARGEMENT ==========
  Future<void> _preloadCoverImage() async {
    if (_activity.coverImageAssetId == null || _userId == null) {
      if (mounted && _isLoadingCoverImage) {
        setState(() => _isLoadingCoverImage = false);
      }
      return;
    }
    if (_cachedCoverImagePath != null) return;
    if (_isLoadingCoverImage) return;

    setState(() => _isLoadingCoverImage = true);

    final cachedPath = await _getCachedCoverImagePath(
      _activity.coverImageAssetId!,
    );
    if (cachedPath != null) {
      if (mounted) {
        setState(() {
          _cachedCoverImagePath = cachedPath;
          _isLoadingCoverImage = false;
        });
      }
      return;
    }

    try {
      final url = await _mediaService?.getStreamUrl(
        _activity.coverImageAssetId!,
        _userId!,
      );
      if (mounted && url != null && url.isNotEmpty) {
        _cacheCoverImage(_activity.coverImageAssetId!, url);
        setState(() {
          _isLoadingCoverImage = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingCoverImage = false);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement cover image: $e');
      if (mounted) setState(() => _isLoadingCoverImage = false);
    }
  }

  Future<void> _preloadLottie() async {
    if (_lottieAssetId == null || _userId == null) {
      if (mounted && _isLoadingLottie) {
        setState(() => _isLoadingLottie = false);
      }
      return;
    }
    if (_cachedLottiePath != null) return;
    if (_isLoadingLottie) return;

    setState(() => _isLoadingLottie = true);

    final cachedPath = await _getCachedLottiePath(_lottieAssetId!);
    if (cachedPath != null) {
      if (mounted) {
        setState(() {
          _cachedLottiePath = cachedPath;
          _isLoadingLottie = false;
        });
      }
      return;
    }

    try {
      final url = await _mediaService?.getLottieUrl(_lottieAssetId!, _userId!);
      if (mounted && url != null && url.isNotEmpty) {
        _cacheLottie(_lottieAssetId!, url);
        setState(() {
          _isLoadingLottie = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingLottie = false);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement Lottie: $e');
      if (mounted) setState(() => _isLoadingLottie = false);
    }
  }

  // ========== TÉLÉCHARGEMENT POUR OFFLINE ==========
  Future<void> _downloadForOffline() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📴 Téléchargement impossible : vous êtes hors ligne'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_mediaAssetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun média associé à cette activité'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final mediaType =
          _mediaType ?? await _meditationService.getMediaType(_mediaAssetId!);

      final success = await _meditationService.downloadAndCacheMedia(
        _mediaAssetId!,
        mediaType,
      );

      if (success && mounted) {
        setState(() => _isCached = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Activité téléchargée pour utilisation hors-ligne'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Échec du téléchargement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _deleteFromCache() async {
    if (_mediaAssetId == null) return;

    try {
      await _mediaCache.deleteMedia(_mediaAssetId!);

      if (mounted) {
        setState(() => _isCached = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Média supprimé du cache'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ========== RAFRAÎCHISSEMENT ==========
  Future<void> _refreshActivity() async {
    if (_isLoadingActivity) return;

    setState(() => _isLoadingActivity = true);

    try {
      final refreshed = await _activityService.getActivityById(
        _activity.id,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _activity = refreshed;
          _isFavorite = refreshed.isFavorite ?? false;
          _isCompleted = refreshed.isCompleted ?? false;
          _isInProgress = refreshed.isInProgress ?? false;
          _progressPercentage = refreshed.progressPercentage ?? 0;
          _userRating = refreshed.userRating;
          _userFeedback = refreshed.userFeedback;
        });

        _buildMediaIds();
        _loadCachedMedia();
        _loadMediaType();
        _preloadCoverImage();
        _preloadLottie();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur rafraîchissement: $e');
      _showErrorMessage('Impossible de rafraîchir les données');
    } finally {
      if (mounted) setState(() => _isLoadingActivity = false);
    }
  }

  // ========== PLAYBACK MANAGER ==========
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_playbackManager == null) {
      try {
        _playbackManager = Provider.of<PlaybackManager>(context, listen: false);
        _playbackManager!.addListener(_onPlaybackStateChanged);
      } catch (e) {
        if (kDebugMode) print('⚠️ PlaybackManager non disponible: $e');
      }
    }
  }

  void _onPlaybackStateChanged() {
    if (_isDisposed || !mounted) return;
    if (_playbackManager!.currentMeditation?.id == _activity.id) {
      setState(() {
        _isMediaLoading = _playbackManager!.isLoading;
      });
      // Vérifier si on doit marquer comme terminé automatiquement
      _checkAutoCompletion();
    } else {
      setState(() {
        _isMediaLoading = false;
      });
    }
  }

  Future<void> _checkAutoCompletion() async {
    if (_autoCompleted) return;
    if (_isCompleted) return; // déjà terminée
    if (!_playbackManager!.isPlaying) return;

    final position = _playbackManager!.position;
    final duration = _playbackManager!.duration;
    if (duration.inSeconds == 0) return;

    final progress = position.inSeconds / duration.inSeconds;
    if (progress >= 0.90) {
      // seuil à 90%
      _autoCompleted = true;
      await _autoCompleteActivity();
    }
  }

  Future<void> _autoCompleteActivity() async {
    try {
      final metadata = await _buildCompletionMetadata();
      final request = ActivityProgressRequestDTO(
        sessionId: DateTime.now().millisecondsSinceEpoch,
        progressPercentage: 100,
        positionSeconds: _activity.durationSeconds ?? 300,
        deviceId: await _getDeviceId(),
        sessionMetadata: SessionMetadataDTO(
          deviceInfo: metadata['deviceModel'],
          appVersion: metadata['appVersion'],
          osVersion: metadata['osVersion'],
          networkType: metadata['networkType'],
          batteryLevel: (metadata['batteryLevel'] as int).toDouble(),
          location: '${metadata['locationLat']},${metadata['locationLng']}',
        ),
      );

      final updatedActivity = await _activityService.completeActivity(
        _activity.id,
        request,
      );

      setState(() {
        _isCompleted = true;
        _isInProgress = false;
        _progressPercentage = 100;
        _activity = updatedActivity;
      });

      _showSuccessMessage(
        title: 'Félicitations !',
        message: 'Vous avez terminé cette activité',
        icon: Icons.check_circle,
      );

      // Afficher la boîte d'évaluation après un délai
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showRatingDialog = true;
            if (_userRating != null) {
              _selectedRating = _userRating!.toDouble();
              _feedbackController.text = _userFeedback ?? '';
            }
          });
        }
      });
    } catch (e) {
      if (kDebugMode) print('❌ Erreur auto-completion: $e');
      _autoCompleted = false; // réessayer plus tard si échec
    }
  }

  // ========== DÉMARRAGE AUDIO/VIDEO ==========
  Future<void> _startActivityMedia() async {
    if (!_isOnline && !_isCached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '📴 Cette activité n\'est pas disponible hors ligne. Connectez-vous pour la télécharger.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isMediaLoading = true);

    try {
      if (_mediaType == 'VIDEO') {
        await _startVideoPlayback();
      } else {
        await _startAudioPlayback();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur démarrage média: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger le média ($_mediaType)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isMediaLoading = false);
    }
  }

  Future<void> _startAudioPlayback() async {
    if (_playbackManager == null) {
      try {
        _playbackManager = Provider.of<PlaybackManager>(context, listen: false);
      } catch (e) {
        _showErrorMessage('Service audio non disponible');
        return;
      }
    }

    String? audioUrl;
    bool useLocalFile = false;

    if (_isCached && _mediaAssetId != null) {
      final cachedUrl = await _mediaCache.getMediaUrl(_mediaAssetId!);
      if (cachedUrl != null) {
        audioUrl = cachedUrl;
        useLocalFile = true;
        if (kDebugMode) print('🎵 Lecture depuis cache: $cachedUrl');
      }
    }

    if (audioUrl == null) {
      if (!_isOnline) {
        throw Exception('Impossible de streamer : pas de connexion');
      }
      audioUrl = await _meditationService.getStreamUrl(_mediaAssetId!);
      useLocalFile = false;
    }

    final durationSeconds = _activity.durationSeconds ?? 300;
    final durationMin = (durationSeconds / 60).round();

    final meditation = Meditation(
      id: _activity.id,
      title: _activity.title,
      description: _activity.description ?? '',
      category: _activity.type,
      difficultyLevel: _activity.difficultyLevel ?? 'DÉBUTANT',
      durationMin: durationMin,
      instructorName: null,
      posterImageAssetId: _activity.coverImageAssetId,
      audioVideoAssetId: _mediaAssetId,
      isPremium: false,
      viewCount: _activity.completionCount,
      completionCount: _activity.completionCount,
      averageRating: _activity.averageRating,
      ratingCount: 0,
      tags: _activity.tags,
      displayOrder: 0,
      status: 'ACTIVE',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _playbackManager!.loadAndPlayMeditation(
      meditation,
      audioUrl: audioUrl,
      headers: null,
      autoPlay: true,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationPlayerPage(
          meditation: meditation,
          playbackManager: _playbackManager!,
          audioHeaders: null,
          mediaType: 'AUDIO',
          useLocalFile: useLocalFile,
        ),
      ),
    );
  }

  Future<void> _startVideoPlayback() async {
    String? videoUrl;
    bool isLocalFile = false;

    if (_isCached && _mediaAssetId != null) {
      final cachedUrl = await _mediaCache.getMediaUrl(_mediaAssetId!);
      if (cachedUrl != null) {
        videoUrl = cachedUrl;
        isLocalFile = true;
        if (kDebugMode) print('🎬 Lecture vidéo depuis cache: $cachedUrl');
      }
    }

    if (videoUrl == null) {
      if (!_isOnline) {
        throw Exception('Impossible de streamer : pas de connexion');
      }
      videoUrl = await _meditationService.getStreamUrl(_mediaAssetId!);
      isLocalFile = false;
    }

    if (kDebugMode) print('🎬 Chargement vidéo depuis: $videoUrl');

    try {
      VideoPlayerController controller;

      if (isLocalFile) {
        final filePath = videoUrl.replaceFirst('file://', '');
        controller = VideoPlayerController.file(File(filePath));
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }

      _videoController = controller;

      await _videoController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw TimeoutException('Initialisation vidéo trop longue'),
      );

      if (_videoController!.value.isInitialized) {
        await _videoController!.play();

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              meditation: Meditation(
                id: _activity.id,
                title: _activity.title,
                description: _activity.description ?? '',
                category: _activity.type,
                difficultyLevel: _activity.difficultyLevel ?? 'DÉBUTANT',
                durationMin: (_activity.durationSeconds ?? 300) ~/ 60,
                instructorName: null,
                posterImageAssetId: _activity.coverImageAssetId,
                audioVideoAssetId: _mediaAssetId,
                isPremium: false,
                viewCount: _activity.completionCount,
                completionCount: _activity.completionCount,
                averageRating: _activity.averageRating,
                ratingCount: 0,
                tags: _activity.tags,
                displayOrder: 0,
                status: 'ACTIVE',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              videoController: _videoController!,
              mediaType: _mediaType!,
              isLocalFile: isLocalFile,
            ),
          ),
        ).then((_) {
          _videoController?.dispose();
          _videoController = null;
        });
      } else {
        throw Exception('Échec d\'initialisation de la vidéo');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement vidéo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lecture vidéo impossible, passage en mode audio'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      await _startAudioPlayback();
    }
  }

  // ========== ACTIONS UTILISATEUR ==========
  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    if (!_authService.isAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedActivity = await _activityService.toggleFavorite(
        _activity.id,
      );

      setState(() {
        _isFavorite = !_isFavorite;
        _activity = updatedActivity;
      });

      _showSuccessMessage(
        title: _isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris',
        message: _isFavorite
            ? 'Cette activité a été ajoutée à vos favoris'
            : 'Cette activité a été retirée de vos favoris',
        icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
      );
    } catch (e) {
      _showErrorMessage('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCompletion() async {
    if (_isLoading) return;

    if (!_authService.isAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isCompleted) {
        // Réinitialiser l'activité (si l'utilisateur veut recommencer)
        setState(() {
          _isCompleted = false;
          _isInProgress = false;
          _progressPercentage = 0;
          _userRating = null;
          _userFeedback = null;
        });

        _showSuccessMessage(
          title: 'Activité réinitialisée',
          message: 'Votre progression a été réinitialisée',
          icon: Icons.refresh,
        );
      } else {
        // 1. Récupérer les métadonnées du device
        final metadata = await _buildCompletionMetadata();

        // 2. Construire la requête avec toutes les informations
        final request = ActivityProgressRequestDTO(
          sessionId: DateTime.now().millisecondsSinceEpoch,
          progressPercentage: 100,
          positionSeconds: _activity.durationSeconds ?? 300,
          deviceId: await _getDeviceId(),
          sessionMetadata: SessionMetadataDTO(
            deviceInfo: metadata['deviceModel'],
            appVersion: metadata['appVersion'],
            osVersion: metadata['osVersion'],
            networkType: metadata['networkType'],
            batteryLevel: (metadata['batteryLevel'] as int).toDouble(),
            location: '${metadata['locationLat']},${metadata['locationLng']}',
          ),
        );

        // 3. Appeler l'API pour marquer comme terminée
        final updatedActivity = await _activityService.completeActivity(
          _activity.id,
          request,
        );

        // 4. Mettre à jour l'état local
        setState(() {
          _isCompleted = true;
          _isInProgress = false;
          _progressPercentage = 100;
          _activity = updatedActivity;
        });

        _showSuccessMessage(
          title: 'Félicitations !',
          message: 'Vous avez terminé cette activité',
          icon: Icons.check_circle,
        );

        // 5. Afficher la boîte de dialogue d'évaluation après un délai
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showRatingDialog = true;
              if (_userRating != null) {
                _selectedRating = _userRating!.toDouble();
                _feedbackController.text = _userFeedback ?? '';
              }
            });
          }
        });
      }
    } catch (e) {
      _showErrorMessage('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      _showErrorMessage('Veuillez donner une note');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = ActivityRatingRequestDTO(
        rating: _selectedRating.toInt(),
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
        difficultyPerception: _difficultyPerception,
        enjoymentScore: _enjoymentScore,
      );

      final updatedActivity = await _activityService.rateActivity(
        _activity.id,
        request,
      );

      setState(() {
        _userRating = _selectedRating.toInt();
        _userFeedback = _feedbackController.text.trim();
        _activity = updatedActivity; // met à jour la note moyenne, etc.
        _showRatingDialog = false;
      });

      _showSuccessMessage(
        title: 'Merci pour votre avis !',
        message: 'Votre évaluation a été enregistrée',
        icon: Icons.star,
      );
    } catch (e) {
      _showErrorMessage('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      // Réinitialiser les champs du formulaire
      _selectedRating = 0.0;
      _feedbackController.clear();
      _difficultyPerception = null;
      _enjoymentScore = null;
    }
  }

  Future<void> _startActivity() async {
    if (_isLoading) return;

    if (!_authService.isAuthenticated) {
      _showAuthRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedActivity = await _activityService.startActivity(
        _activity.id,
        null,
      );

      setState(() {
        _isInProgress = true;
        _isCompleted = false;
        _progressPercentage = _progressPercentage > 0
            ? _progressPercentage
            : 10;
        _activity = updatedActivity;
      });

      _showSuccessMessage(
        title: 'Activité démarrée',
        message: 'Bon courage !',
        icon: Icons.play_arrow,
      );

      if (_hasMedia) {
        _startActivityMedia();
      }
    } catch (e) {
      _showErrorMessage('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateProgress(int percentage) {
    final newPercentage = percentage.clamp(0, 100);

    setState(() {
      _progressPercentage = newPercentage;

      if (_progressPercentage == 100 && !_isCompleted) {
        _isCompleted = true;
        _isInProgress = false;
      } else if (_progressPercentage > 0 && _progressPercentage < 100) {
        _isInProgress = true;
        _isCompleted = false;
      } else if (_progressPercentage == 0) {
        _isInProgress = false;
        _isCompleted = false;
      }
    });

    _saveProgress();
  }

  Future<void> _saveProgress() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Vous devez être connecté pour effectuer cette action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage({
    required String title,
    required String message,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(fontSize: 14)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareActivity() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Partager "${_activity.title}"',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.message, 'Message'),
                _buildShareOption(Icons.email, 'Email'),
                _buildShareOption(Icons.link, 'Copier le lien'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _activity.getColor().withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _activity.getColor(), size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ========== ANIMATIONS ==========
  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _colorAnimation =
        ColorTween(
          begin: _activity.getColor().withOpacity(0),
          end: _activity.getColor(),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.forward();
  }

  // ========== WIDGETS ==========
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      collapsedHeight: 70,
      floating: false,
      pinned: true,
      snap: false,
      elevation: _showFullAppBar ? 4 : 0,
      backgroundColor: _colorAnimation.value,
      flexibleSpace: FlexibleSpaceBar(
        title: _showFullAppBar
            ? Text(
                _activity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        background: _buildHeaderBackground(),
        centerTitle: true,
        titlePadding: _showFullAppBar
            ? const EdgeInsets.only(bottom: 16)
            : EdgeInsets.zero,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isOnline
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isOnline ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.offline_bolt,
                  size: 14,
                  color: _isOnline ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 10,
                    color: _isOnline ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_mediaAssetId != null && _isOnline)
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isCached ? Icons.cloud_done : Icons.cloud_download,
                    color: _isCached ? Colors.greenAccent : Colors.white,
                  ),
            onPressed: _isDownloading
                ? null
                : _isCached
                ? _deleteFromCache
                : _downloadForOffline,
            tooltip: _isCached ? 'Supprimer du cache' : 'Télécharger',
          ),
        if (_authService.isAuthenticated) ...[
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite
                ? 'Retirer des favoris'
                : 'Ajouter aux favoris',
          ),
        ],
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareActivity,
          tooltip: 'Partager',
        ),
        if (_isLoadingActivity)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshActivity,
            tooltip: 'Rafraîchir',
          ),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    final hasImage = _activity.coverImageAssetId != null;
    if (!hasImage) {
      return _buildFallbackCoverImage();
    }

    if (_cachedCoverImagePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(_cachedCoverImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackCoverImage(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  _activity.getColor().withOpacity(0.3),
                ],
              ),
            ),
          ),
          _buildHeaderContent(),
        ],
      );
    }

    if (_isLoadingCoverImage) {
      return Container(
        color: _activity.getColor().withOpacity(0.3),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<String?>(
      future: _mediaService?.getStreamUrl(
        _activity.coverImageAssetId!,
        _userId!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: _activity.getColor().withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final imageUrl = snapshot.data;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _cacheCoverImage(_activity.coverImageAssetId!, imageUrl);
          return Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: _activity.getColor().withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => _buildFallbackCoverImage(),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      _activity.getColor().withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              _buildHeaderContent(),
            ],
          );
        }
        return _buildFallbackCoverImage();
      },
    );
  }

  Widget _buildHeaderContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              _activity.typeDisplayName ?? _activity.type,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _activity.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (_activity.shortDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              _activity.shortDescription!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackCoverImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_activity.getColor(), _activity.getColor().withOpacity(0.8)],
        ),
      ),
      child: Center(
        child: Icon(
          _activity.getIcon(),
          size: 100,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildInfoCard(),
        const SizedBox(height: 20),
        _buildProgressSection(),
        const SizedBox(height: 20),

        if (_hasMedia) ...[_buildMediaPlayerCard(), const SizedBox(height: 20)],

        _buildStatsSection(),
        const SizedBox(height: 20),

        if (_configuration != null && _configuration!.isNotEmpty) ...[
          _buildConfigurationSection(),
          const SizedBox(height: 20),
        ],

        ..._buildExpandableSections(),

        if (_activity.tags.isNotEmpty) ...[
          _buildTagsSection(),
          const SizedBox(height: 20),
        ],

        if (_lottieAssetId != null) _buildLottieCard(),
        const SizedBox(height: 20),

        _buildActionButtons(),
        const SizedBox(height: 40),
        _buildLegalNote(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ========== LOTTIE AVEC CACHE PERSISTANT ==========
  Widget _buildLottieCard() {
    if (_lottieAssetId == null) return const SizedBox.shrink();

    // Si le fichier est déjà en cache
    if (_cachedLottiePath != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: _openLottieFullscreen,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _activity.getColor().withOpacity(0.1),
                  _activity.getColor().withOpacity(0.05),
                  Colors.white,
                ],
              ),
              border: Border.all(
                color: _activity.getColor().withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _activity.getColor().withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Lottie.file(
                      File(_cachedLottiePath!),
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) {
                        if (kDebugMode)
                          print('⚠️ Erreur Lottie (fichier): $error');
                        return Lottie.asset(
                          'assets/lotties/activity.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        );
                      },
                    ),
                  ),
                ),
                _buildLottieOverlay(),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingLottie) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade200,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Pas encore de cache : récupérer l'URL pré-signée et la mettre en cache
    return FutureBuilder<String?>(
      future: _mediaService?.getLottieUrl(_lottieAssetId!, _userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade200,
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final lottieUrl = snapshot.data;
        if (lottieUrl != null && lottieUrl.isNotEmpty) {
          _cacheLottie(_lottieAssetId!, lottieUrl);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _openLottieFullscreen,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _activity.getColor().withOpacity(0.1),
                      _activity.getColor().withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                  border: Border.all(
                    color: _activity.getColor().withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _activity.getColor().withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Lottie.network(
                          lottieUrl,
                          fit: BoxFit.contain,
                          repeat: true,
                          errorBuilder: (context, error, stackTrace) {
                            if (kDebugMode)
                              print('⚠️ Erreur Lottie (réseau): $error');
                            return Lottie.asset(
                              'assets/lotties/activity.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            );
                          },
                        ),
                      ),
                    ),
                    _buildLottieOverlay(),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLottieOverlay() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _activity.getColor(),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.animation, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Animation exclusive',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Cliquez pour agrandir',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _activity.getColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fullscreen,
                color: _activity.getColor(),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLottieFullscreen() {
    setState(() => _showLottieFullscreen = true);
  }

  Widget _buildLottieFullscreenDialog() {
    if (!_showLottieFullscreen) return const SizedBox.shrink();

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black.withOpacity(0.95),
      child: Stack(
        children: [
          Center(
            child: _cachedLottiePath != null
                ? Lottie.file(
                    File(_cachedLottiePath!),
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Lottie.asset(
                        'assets/lotties/activity.json',
                        fit: BoxFit.contain,
                        repeat: true,
                      );
                    },
                  )
                : Lottie.asset(
                    'assets/lotties/activity.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showLottieFullscreen = false;
                  });
                },
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    _activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activity.typeDisplayName ?? _activity.type,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== AUTRES WIDGETS (inchangés) ==========
  // Les widgets suivants sont identiques à votre version précédente.
  // Je les inclue pour que le fichier soit complet.

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaItem(
                    Icons.timer,
                    _activity.getFormattedDuration(),
                    'Durée',
                  ),
                  _buildMetaItem(
                    Icons.speed,
                    _activity.getDifficultyLabel(),
                    'Difficulté',
                  ),
                  _buildMetaItem(
                    Icons.people,
                    '${_activity.completionCount}',
                    'Participants',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300),
              if (_activity.description?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'À propos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _activity.description!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ],
              if (_activity.averageRating > 0) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: _activity.averageRating,
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 20,
                      direction: Axis.horizontal,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_activity.averageRating.toStringAsFixed(1)}/5.0',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_activity.completionCount} avis)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              if (_userRating != null) ...[
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Votre évaluation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: _userRating!.toDouble(),
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 18,
                      direction: Axis.horizontal,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$_userRating!/5',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_userFeedback?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    _userFeedback!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _activity.getColor().withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _activity.getColor(), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Votre progression',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getProgressColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getProgressColor()),
                    ),
                    child: Text(
                      '$_progressPercentage%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _getProgressColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: 10,
                    width:
                        (MediaQuery.of(context).size.width - 88) *
                        (_progressPercentage / 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getProgressColor(),
                          _getProgressColor().withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getProgressStatus(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getProgressColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_activity.updatedAt != null)
                    Text(
                      'Dernière mise à jour: ${_formatDate(_activity.updatedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateProgress(0),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Réinitialiser'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateProgress(_progressPercentage + 25),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Avancer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activity.getColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor() {
    if (_progressPercentage == 100) return Colors.green;
    if (_progressPercentage >= 75) return Colors.lightGreen;
    if (_progressPercentage >= 50) return Colors.orange;
    if (_progressPercentage >= 25) return Colors.amber;
    return Colors.grey;
  }

  String _getProgressStatus() {
    if (_isCompleted) return 'Terminé';
    if (_isInProgress) return 'En cours';
    if (_progressPercentage > 0) return 'Commencé';
    return 'Non commencé';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return "Aujourd'hui";
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} jours';
    if (difference.inDays < 30)
      return 'Il y a ${difference.inDays ~/ 7} semaines';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMediaPlayerCard() {
    final isAudio = _mediaType == 'AUDIO';
    final isVideo = _mediaType == 'VIDEO';

    final playbackManager = _playbackManager;
    final isCurrentActivity =
        playbackManager != null &&
        playbackManager.currentMeditation?.id == _activity.id;
    final isPlaying = isAudio && isCurrentActivity && playbackManager.isPlaying;
    final isPaused = isAudio && isCurrentActivity && playbackManager.isPaused;
    final isLoading =
        (isAudio && isCurrentActivity && playbackManager.isLoading) ||
        _isMediaLoading;

    final position = isAudio && isCurrentActivity
        ? playbackManager.position
        : Duration.zero;
    final duration = isAudio && isCurrentActivity
        ? playbackManager.duration
        : Duration.zero;
    final progress = duration.inSeconds > 0
        ? position.inSeconds / duration.inSeconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _activity.getColor().withOpacity(0.1),
              _activity.getColor().withOpacity(0.05),
              Colors.white,
            ],
          ),
          border: Border.all(
            color: _hasMedia
                ? _activity.getColor().withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hasMedia
                  ? _activity.getColor().withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _hasMedia
                          ? _activity.getColor()
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVideo ? Icons.videocam : Icons.headphones,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasMedia
                              ? (isVideo ? 'Vidéo Guide' : 'Audio Guide')
                              : 'Média non disponible',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _hasMedia
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !_hasMedia
                              ? 'Aucun média pour cette activité'
                              : isVideo
                              ? (isPlaying
                                    ? 'Lecture en cours...'
                                    : isLoading
                                    ? 'Chargement...'
                                    : 'Prêt à visionner')
                              : (isPlaying
                                    ? 'Lecture en cours...'
                                    : isPaused
                                    ? 'En pause'
                                    : isLoading
                                    ? 'Chargement...'
                                    : 'Prêt à écouter'),
                          style: TextStyle(
                            fontSize: 13,
                            color: isPlaying || isPaused
                                ? _activity.getColor()
                                : _hasMedia
                                ? Colors.grey.shade600
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _activity.getColor(),
                        ),
                      ),
                    ),
                ],
              ),

              // Barre de progression (audio uniquement)
              if (isAudio &&
                  (isPlaying || isPaused || position.inSeconds > 0)) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _activity.getColor(),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  color: _activity.getColor(),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],

              // Lecteur vidéo
              if (isVideo) ...[const SizedBox(height: 16), _buildVideoPlayer()],

              // Contrôles audio
              if (isAudio) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPlaying || isPaused)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.stop, color: Colors.red),
                          onPressed: _stopAudio,
                          iconSize: 28,
                        ),
                      ),

                    Container(
                      decoration: BoxDecoration(
                        color: _hasMedia
                            ? _activity.getColor()
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _hasMedia
                                ? _activity.getColor().withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          !_hasMedia
                              ? (isVideo
                                    ? Icons.videocam
                                    : Icons.headphones_outlined)
                              : isPlaying
                              ? Icons.pause
                              : isPaused
                              ? Icons.play_arrow
                              : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: !_hasMedia
                            ? null
                            : isPlaying
                            ? _pauseAudio
                            : isPaused
                            ? _resumeAudio
                            : _startActivityMedia,
                        iconSize: 32,
                      ),
                    ),
                  ],
                ),

                if (isPlaying || isPaused)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _rewindAudio,
                          icon: const Icon(Icons.replay_10, size: 20),
                          label: const Text('10s'),
                          style: TextButton.styleFrom(
                            foregroundColor: _activity.getColor(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: _forwardAudio,
                          icon: const Icon(Icons.forward_10, size: 20),
                          label: const Text('10s'),
                          style: TextButton.styleFrom(
                            foregroundColor: _activity.getColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_hasMedia || _mediaType != 'VIDEO') return const SizedBox.shrink();

    if (_isMediaLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_videoController == null) {
      return GestureDetector(
        onTap: _startActivityMedia,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  size: 60,
                  color: _activity.getColor(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lire la vidéo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_isOnline && !_isCached)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ Hors ligne - vidéo non disponible en cache',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isVideoInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleVideoControls,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
            if (_showVideoControls)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 60,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    onPressed: _toggleVideoPlayPause,
                  ),
                ),
              ),
            if (_showVideoControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      VideoProgressBar(
                        controller: _videoController!,
                        onSeek: (position) {
                          _videoController!.seekTo(position);
                          _startHideControlsTimer();
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_videoController!.value.position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_videoController!.value.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onVideoUpdate() {
    if (_isDisposed || !mounted) return;
    if (_showVideoControls) {
      setState(() {});
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted &&
          _videoController != null &&
          _videoController!.value.isPlaying) {
        setState(() => _showVideoControls = false);
      }
    });
  }

  void _toggleVideoControls() {
    if (!mounted) return;
    setState(() => _showVideoControls = !_showVideoControls);
    if (_showVideoControls) _startHideControlsTimer();
  }

  void _toggleVideoPlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized)
      return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
      _startHideControlsTimer();
    }
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _pauseAudio() async {
    if (_playbackManager != null) {
      await _playbackManager!.pause();
    }
  }

  Future<void> _resumeAudio() async {
    if (_playbackManager != null) {
      await _playbackManager!.play();
    }
  }

  Future<void> _stopAudio() async {
    if (_playbackManager != null) {
      await _playbackManager!.stop();
    }
  }

  Future<void> _rewindAudio() async {
    if (_playbackManager != null) {
      await _playbackManager!.rewind(const Duration(seconds: 10));
    }
  }

  Future<void> _forwardAudio() async {
    if (_playbackManager != null) {
      await _playbackManager!.forward(const Duration(seconds: 10));
    }
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistiques',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final stats = [
                    {
                      'label': 'Popularité',
                      'value': '${(_activity.popularityScore).toInt()}%',
                      'icon': Icons.trending_up,
                      'color': Colors.pink,
                    },
                    {
                      'label': 'Taux de succès',
                      'value': '${(_activity.successRate ?? 85).toInt()}%',
                      'icon': Icons.check_circle,
                      'color': Colors.green,
                    },
                    {
                      'label': 'Évaluation',
                      'value': _activity.averageRating.toStringAsFixed(1),
                      'icon': Icons.star,
                      'color': Colors.amber,
                    },
                    {
                      'label': 'Statut',
                      'value': _activity.getStatusLabel(),
                      'icon': Icons.info,
                      'color': _activity.getStatusColor(),
                    },
                  ][index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (stats['color'] as Color).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (stats['color'] as Color).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: stats['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                stats['icon'] as IconData,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              stats['value'] as String,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stats['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    final config = _configuration!;
    final items = <Map<String, dynamic>>[];

    if (config['requiresPreparation'] == true) {
      items.add({
        'icon': Icons.schedule,
        'label': 'Préparation',
        'value': '${config['preparationTimeSeconds'] ?? 5} min',
      });
    }
    if (config['isGuided'] == true) {
      items.add({
        'icon': Icons.record_voice_over,
        'label': 'Guidé',
        'value': 'Audio disponible',
      });
    }
    if (config['hasBackgroundMusic'] == true) {
      items.add({
        'icon': Icons.music_note,
        'label': 'Musique',
        'value': 'Ambiance sonore',
      });
    }
    if (config['recommendedTimeOfDay'] != null) {
      items.add({
        'icon': Icons.access_time,
        'label': 'Moment idéal',
        'value': config['recommendedTimeOfDay'],
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: _activity.getColor(),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              item['value'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandableSections() {
    final sections = [
      {
        'key': 'instructions',
        'title': 'Instructions détaillées',
        'content': _activity.instructions,
        'icon': Icons.list_alt,
      },
      {
        'key': 'prerequisites',
        'title': 'Prérequis',
        'content': _activity.prerequisites,
        'icon': Icons.check_circle,
      },
      {
        'key': 'benefits',
        'title': 'Bénéfices',
        'content': _activity.benefits,
        'icon': Icons.emoji_events,
      },
    ];

    return sections
        .where((section) {
          final content = section['content'] as String?;
          return content != null && content.isNotEmpty;
        })
        .map((section) {
          final key = section['key'] as String;
          final isExpanded = _expandedSections[key] ?? false;

          return Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedSections[key] = !isExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _activity.getColor().withOpacity(
                                      0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    section['icon'] as IconData,
                                    color: _activity.getColor(),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    section['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.expand_more,
                                    color: _activity.getColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 16),
                          Text(
                            section['content'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        })
        .toList();
  }

  Widget _buildTagsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tags',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activity.tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _activity.getColor(),
                      ),
                    ),
                    backgroundColor: _activity.getColor().withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _activity.getColor().withOpacity(0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleCompletion,
                  icon: Icon(
                    _isCompleted ? Icons.check_circle : Icons.check,
                    size: 24,
                  ),
                  label: Text(
                    _isCompleted ? 'Activité terminée' : 'Terminer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCompleted
                        ? Colors.green
                        : _activity.getColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isInProgress && !_isCompleted)
            OutlinedButton(
              onPressed: _startActivity,
              child: const Text('Reprendre la session'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          if (_authService.isAuthenticated)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showRatingDialog = true;
                  if (_userRating != null) {
                    _selectedRating = _userRating!.toDouble();
                    _feedbackController.text = _userFeedback ?? '';
                  }
                });
              },
              icon: Icon(
                _userRating != null ? Icons.star : Icons.star_border,
                color: _userRating != null ? Colors.amber : null,
              ),
              label: Text(
                _userRating != null
                    ? 'Modifier mon évaluation'
                    : 'Évaluer cette activité',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegalNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        'Cette activité est fournie à des fins éducatives et de bien-être. '
        'Consultez un professionnel de la santé si nécessaire.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildRatingDialog() {
    if (!_showRatingDialog) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Évaluez cette activité',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Votre avis nous aide à améliorer nos contenus',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: RatingBar.builder(
                          initialRating: _selectedRating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 40,
                          itemBuilder: (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _selectedRating = rating;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_difficultyPerception == null) ...[
                        const Text(
                          'Cette activité était-elle difficile ?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [1, 2, 3, 4, 5].map((level) {
                            return ChoiceChip(
                              label: Text('$level'),
                              selected: _difficultyPerception == level,
                              onSelected: (selected) {
                                setState(() {
                                  _difficultyPerception = selected
                                      ? level
                                      : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_enjoymentScore == null) ...[
                        const Text(
                          'Avez-vous apprécié cette activité ?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [1, 2, 3, 4, 5].map((score) {
                            return ChoiceChip(
                              label: Text('$score'),
                              selected: _enjoymentScore == score,
                              onSelected: (selected) {
                                setState(() {
                                  _enjoymentScore = selected ? score : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _feedbackController,
                        decoration: const InputDecoration(
                          labelText: 'Vos commentaires (optionnel)',
                          border: OutlineInputBorder(),
                          hintText: 'Qu\'avez-vous pensé de cette activité ?',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showRatingDialog = false;
                                _selectedRating = 0.0;
                                _feedbackController.clear();
                                _difficultyPerception = null;
                                _enjoymentScore = null;
                              });
                            },
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _submitRating,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _activity.getColor(),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Envoyer l\'évaluation'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    _activityService = Provider.of<ActivityApiService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildAnimatedContent()),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _activity.getColor(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Traitement en cours...',
                          style: TextStyle(
                            color: _activity.getColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          _buildRatingDialog(),
          _buildLottieFullscreenDialog(),
        ],
      ),
    );
  }
}

// =============================================================================
// PAGE DE LECTURE AUDIO (copiée depuis meditation_detail_page)
// =============================================================================
class MeditationPlayerPage extends StatefulWidget {
  final Meditation meditation;
  final PlaybackManager playbackManager;
  final Map<String, String>? audioHeaders;
  final String mediaType;
  final bool useLocalFile;

  const MeditationPlayerPage({
    super.key,
    required this.meditation,
    required this.playbackManager,
    this.audioHeaders,
    this.mediaType = 'AUDIO',
    this.useLocalFile = false,
  });

  @override
  State<MeditationPlayerPage> createState() => _MeditationPlayerPageState();
}

class _MeditationPlayerPageState extends State<MeditationPlayerPage> {
  late CompletionService _completionService;
  Timer? _completionTimer;
  bool _isDisposed = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    final meditationService = Provider.of<MeditationService>(
      context,
      listen: false,
    );

    _completionService = CompletionService(
      meditationService: meditationService,
      onCompletionSuccess: _showCompletionFeedback,
    );

    _completionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkCompletion(),
    );
  }

  void _showCompletionFeedback() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bravo ! Méditation terminée 🧘'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _checkCompletion() async {
    if (_isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;

    if (!widget.playbackManager.isPlaying) return;

    await _completionService.checkAndComplete(
      meditationId: widget.meditation.id!,
      currentPosition: widget.playbackManager.position,
      totalDuration: widget.playbackManager.duration,
      isPlaying: widget.playbackManager.isPlaying,
      userId: userId,
    );
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    widget.playbackManager.setPlaybackSpeed(speed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vitesse de lecture: ${speed.toStringAsFixed(1)}x'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF7DBBC3),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _completionTimer?.cancel();
    _completionService.resetForNextPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    return Scaffold(
      body: isDesktop ? _buildDesktopPlayer() : _buildMobilePlayer(),
    );
  }

  Widget _buildDesktopPlayer() {
    return Row(
      children: [
        // Partie gauche : informations
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Meditation.getCategoryColor(widget.meditation.category),
                  Meditation.getCategoryColor(
                    widget.meditation.category,
                  ).withOpacity(0.8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Icon(
                    Meditation.getCategoryIcon(widget.meditation.category),
                    size: 100,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.meditation.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.meditation.instructorName != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Par ${widget.meditation.instructorName!}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 20,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Chip(
                        label: Text(
                          widget.meditation.formattedDuration,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      Chip(
                        label: Text(
                          widget.meditation.category,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      Chip(
                        label: Text(
                          widget.mediaType,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: widget.mediaType == 'VIDEO'
                            ? Colors.red.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                      ),
                      if (widget.useLocalFile)
                        Chip(
                          label: const Text(
                            'HORS-LIGNE',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green.withOpacity(0.4),
                          avatar: const Icon(
                            Icons.offline_bolt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      Chip(
                        label: Text(
                          '${_playbackSpeed.toStringAsFixed(1)}x',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(
                          0xFF7DBBC3,
                        ).withOpacity(0.4),
                        avatar: const Icon(
                          Icons.speed,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.playbackManager.isPlaying
                              ? Icons.play_arrow
                              : Icons.pause,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.playbackManager.isPlaying
                                ? 'En cours de lecture'
                                : 'En pause',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '${PlaybackManager.formatDuration(widget.playbackManager.position)} / ${PlaybackManager.formatDuration(widget.playbackManager.duration)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Partie droite : contrôles
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AudioControls(
                      playbackManager: widget.playbackManager,
                      showTitle: true,
                      showVolumeControls: true,
                    ),
                    const SizedBox(height: 24),
                    // Contrôle de vitesse
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vitesse de lecture',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _playbackSpeed,
                                  min: 0.5,
                                  max: 2.0,
                                  divisions: 6,
                                  label:
                                      '${_playbackSpeed.toStringAsFixed(1)}x',
                                  onChanged: (value) {
                                    setState(() => _playbackSpeed = value);
                                  },
                                  onChangeEnd: (value) {
                                    _changePlaybackSpeed(value);
                                  },
                                  activeColor: const Color(0xFF7DBBC3),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF7DBBC3,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_playbackSpeed.toStringAsFixed(1)}x',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7DBBC3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobilePlayer() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Meditation.getCategoryColor(widget.meditation.category),
                Meditation.getCategoryColor(
                  widget.meditation.category,
                ).withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      if (widget.useLocalFile)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.offline_bolt,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Hors-ligne',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        widget.mediaType == 'VIDEO' ? 'Visionnage' : 'Écoute',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.speed, color: Colors.white),
                    color: Colors.white,
                    onSelected: _changePlaybackSpeed,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 0.5,
                        child: Row(
                          children: [
                            Text('0.5x'),
                            SizedBox(width: 8),
                            Text(
                              'Ralenti',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 0.75,
                        child: Row(
                          children: [
                            Text('0.75x'),
                            SizedBox(width: 8),
                            Text(
                              'Léger ralentissement',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 1.0,
                        child: Row(
                          children: [
                            Text(
                              '1.0x',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Normal',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 1.25,
                        child: Row(
                          children: [
                            Text('1.25x'),
                            SizedBox(width: 8),
                            Text(
                              'Léger accéléré',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 1.5,
                        child: Row(
                          children: [
                            Text('1.5x'),
                            SizedBox(width: 8),
                            Text(
                              'Accéléré',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 2.0,
                        child: Row(
                          children: [
                            Text('2.0x'),
                            SizedBox(width: 8),
                            Text(
                              'Rapide',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Icon(
                Meditation.getCategoryIcon(widget.meditation.category),
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                widget.meditation.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.meditation.instructorName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Par ${widget.meditation.instructorName!}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Vitesse: ${_playbackSpeed.toStringAsFixed(1)}x',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AudioControls(
                      playbackManager: widget.playbackManager,
                      showTitle: false,
                      showVolumeControls: true,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          '0.5x',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Expanded(
                          child: Slider(
                            value: _playbackSpeed,
                            min: 0.5,
                            max: 2.0,
                            divisions: 6,
                            onChanged: (value) {
                              setState(() => _playbackSpeed = value);
                            },
                            onChangeEnd: _changePlaybackSpeed,
                            activeColor: const Color(0xFF7DBBC3),
                          ),
                        ),
                        const Text(
                          '2.0x',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PAGE DE LECTURE VIDÉO (copiée depuis meditation_detail_page)
// =============================================================================
class VideoPlayerPage extends StatefulWidget {
  final Meditation meditation;
  final VideoPlayerController videoController;
  final String mediaType;
  final bool isLocalFile;

  const VideoPlayerPage({
    super.key,
    required this.meditation,
    required this.videoController,
    required this.mediaType,
    this.isLocalFile = false,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isFullScreen = false;
  double _playbackSpeed = 1.0;
  bool _isDisposed = false;

  late CompletionService _completionService;
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();
    final meditationService = Provider.of<MeditationService>(
      context,
      listen: false,
    );

    _completionService = CompletionService(
      meditationService: meditationService,
      onCompletionSuccess: _showCompletionFeedback,
    );

    widget.videoController.addListener(_onVideoUpdate);
    _startHideControlsTimer();

    _completionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkCompletion(),
    );
  }

  void _showCompletionFeedback() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bravo ! Méditation terminée 🧘'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _checkCompletion() async {
    if (_isDisposed) return;
    if (!widget.videoController.value.isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;

    await _completionService.checkAndComplete(
      meditationId: widget.meditation.id!,
      currentPosition: widget.videoController.value.position,
      totalDuration: widget.videoController.value.duration,
      isPlaying: widget.videoController.value.isPlaying,
      userId: userId,
    );
  }

  void _onVideoUpdate() {
    if (!_isDisposed && mounted && _showControls) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hideControlsTimer?.cancel();
    _completionTimer?.cancel();
    _completionService.resetForNextPlayback();
    widget.videoController.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!_isDisposed && mounted && widget.videoController.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (!mounted) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideControlsTimer();
  }

  void _togglePlayPause() {
    if (widget.videoController.value.isPlaying) {
      widget.videoController.pause();
    } else {
      widget.videoController.play();
      _startHideControlsTimer();
    }
    if (mounted) setState(() {});
  }

  void _toggleFullScreen() {
    if (mounted) setState(() => _isFullScreen = !_isFullScreen);
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    widget.videoController.setPlaybackSpeed(speed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vitesse: ${speed.toStringAsFixed(1)}x'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    if (_isFullScreen) {
      return _buildFullScreenPlayer();
    }
    return Scaffold(
      body: isDesktop ? _buildDesktopVideoPlayer() : _buildMobileVideoPlayer(),
    );
  }

  Widget _buildDesktopVideoPlayer() {
    final size = MediaQuery.of(context).size;
    final videoWidth = size.width * 0.7;

    return Column(
      children: [
        // Barre de titre
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.meditation.title,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isLocalFile)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.offline_bolt, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Hors-ligne',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DBBC3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_playbackSpeed.toStringAsFixed(1)}x',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ),
        // Lecteur vidéo
        Expanded(
          child: Center(
            child: Container(
              width: videoWidth,
              height: videoWidth * 9 / 16,
              color: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: widget.videoController.value.aspectRatio,
                      child: VideoPlayer(widget.videoController),
                    ),
                  ),
                  if (_showControls) _buildVideoControlsOverlay(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileVideoPlayer() {
    return Stack(
      children: [
        // Vidéo en plein écran (relative)
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggleControls,
            child: VideoPlayer(widget.videoController),
          ),
        ),
        // Header (contrôles)
        if (_showControls)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.meditation.title,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isLocalFile)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Offline',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7DBBC3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_playbackSpeed.toStringAsFixed(1)}x',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _toggleFullScreen,
                  ),
                ],
              ),
            ),
          ),
        // Bouton lecture/pause central
        if (_showControls)
          Positioned.fill(
            child: Center(
              child: IconButton(
                icon: Icon(
                  widget.videoController.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ),
                onPressed: _togglePlayPause,
              ),
            ),
          ),
        // Barre de progression inférieure
        if (_showControls)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  VideoProgressBar(
                    controller: widget.videoController,
                    onSeek: (position) {
                      widget.videoController.seekTo(position);
                      _startHideControlsTimer();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              widget.videoController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${_formatDuration(widget.videoController.value.position)} / ${_formatDuration(widget.videoController.value.duration)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          PopupMenuButton<double>(
                            icon: const Icon(Icons.speed, color: Colors.white),
                            color: Colors.white,
                            onSelected: _changePlaybackSpeed,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 0.5,
                                child: Row(
                                  children: [
                                    Text('0.5x'),
                                    SizedBox(width: 8),
                                    Text(
                                      'Ralenti',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 0.75,
                                child: Row(
                                  children: [
                                    Text('0.75x'),
                                    SizedBox(width: 8),
                                    Text(
                                      'Léger ralentissement',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 1.0,
                                child: Row(
                                  children: [
                                    Text(
                                      '1.0x',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Normal',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 1.25,
                                child: Row(
                                  children: [
                                    Text('1.25x'),
                                    SizedBox(width: 8),
                                    Text(
                                      'Léger accéléré',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 1.5,
                                child: Row(
                                  children: [
                                    Text('1.5x'),
                                    SizedBox(width: 8),
                                    Text(
                                      'Accéléré',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 2.0,
                                child: Row(
                                  children: [
                                    Text('2.0x'),
                                    SizedBox(width: 8),
                                    Text(
                                      'Rapide',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullScreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              child: VideoPlayer(widget.videoController),
            ),
          ),
          if (_showControls) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _toggleFullScreen,
                    ),
                    Expanded(
                      child: Text(
                        widget.meditation.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isLocalFile)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Hors-ligne',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7DBBC3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_playbackSpeed.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    PopupMenuButton<double>(
                      icon: const Icon(Icons.speed, color: Colors.white),
                      color: Colors.white,
                      onSelected: _changePlaybackSpeed,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 0.5,
                          child: Text('0.5x - Ralenti'),
                        ),
                        const PopupMenuItem(
                          value: 0.75,
                          child: Text('0.75x - Léger ralentissement'),
                        ),
                        const PopupMenuItem(
                          value: 1.0,
                          child: Text('1.0x - Normal'),
                        ),
                        const PopupMenuItem(
                          value: 1.25,
                          child: Text('1.25x - Léger accéléré'),
                        ),
                        const PopupMenuItem(
                          value: 1.5,
                          child: Text('1.5x - Accéléré'),
                        ),
                        const PopupMenuItem(
                          value: 2.0,
                          child: Text('2.0x - Rapide'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: VideoProgressBar(
                  controller: widget.videoController,
                  onSeek: (position) {
                    widget.videoController.seekTo(position);
                    _startHideControlsTimer();
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: IconButton(
                  icon: Icon(
                    widget.videoController.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoControlsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: IconButton(
          icon: Icon(
            widget.videoController.value.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            size: 64,
            color: Colors.white.withOpacity(0.8),
          ),
          onPressed: _togglePlayPause,
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET BARRE DE PROGRESSION VIDÉO
// =============================================================================
class VideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final Function(Duration) onSeek;

  const VideoProgressBar({
    super.key,
    required this.controller,
    required this.onSeek,
  });

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  double _dragValue = 0.0;
  bool _isDragging = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onVideoUpdate);
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.controller.removeListener(_onVideoUpdate);
    super.dispose();
  }

  void _onVideoUpdate() {
    if (!_isDragging && !_isDisposed && mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    final value = duration.inSeconds > 0
        ? (_isDragging ? _dragValue : position.inSeconds / duration.inSeconds)
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.grey.shade600,
            thumbColor: Colors.red,
            overlayColor: Colors.red.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: (newValue) {
              if (!mounted) return;
              setState(() {
                _isDragging = true;
                _dragValue = newValue;
              });
            },
            onChangeStart: (_) => _isDragging = true,
            onChangeEnd: (newValue) {
              _isDragging = false;
              final newPosition = Duration(
                seconds: (duration.inSeconds * newValue).toInt(),
              );
              widget.onSeek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
