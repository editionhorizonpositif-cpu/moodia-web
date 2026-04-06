// lib/pages/meditation_detail_page.dart - Version finale avec cache images + refresh
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http; // Pour télécharger l'image

import '../models/meditation.dart';
import '../services/meditation_service.dart';
import '../services/api_service.dart';
import '../services/playback_manager.dart';
import '../services/completion_service.dart';
import '../services/media_cache_service.dart';
import '../widgets/playback_controls.dart';
import '../services/media_service.dart';
import '../providers/subscription_provider.dart';

// =============================================================================
// PAGE DE DÉTAIL DE LA MÉDITATION (avec support online/offline, notation, vues)
// =============================================================================
class MeditationDetailPage extends StatefulWidget {
  final Meditation meditation;

  const MeditationDetailPage({super.key, required this.meditation});

  @override
  State<MeditationDetailPage> createState() => _MeditationDetailPageState();
}

class _MeditationDetailPageState extends State<MeditationDetailPage> {
  late final MeditationService _meditationService;
  late final MediaCacheService _cacheService;
  MediaService? _mediaService;
  late ApiService _apiService;
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isCached = false;
  bool _showFullDescription = false;
  late PlaybackManager _playbackManager;
  int? _currentUserId;

  // Données locales actualisables
  Meditation? _currentMeditation; // <-- nouvelle variable locale

  // Type de média (AUDIO / VIDEO)
  String? _mediaType;

  // Contrôleur vidéo (si vidéo)
  VideoPlayerController? _videoController;

  // Éviter les setState après dispose
  bool _isDisposed = false;

  // État de connexion
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Notation
  bool _isRatingDialogVisible = false;
  double _selectedRating = 0.0;
  final TextEditingController _feedbackController = TextEditingController();
  int? _difficultyPerception;
  int? _enjoymentScore;
  int? _userRating;
  bool _hasIncrementedView = false;

  @override
  void initState() {
    super.initState();
    _currentMeditation = widget.meditation; // initialisation

    _initConnectivity();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _meditationService = Provider.of<MeditationService>(context, listen: false);
    _cacheService = MediaCacheService();
    _playbackManager = Provider.of<PlaybackManager>(context, listen: false);
    _mediaService = Provider.of<MediaService>(context, listen: false);
    _loadMediaType();
    _checkIfCached();
    _loadCurrentUserId();
    _playbackManager.addListener(_onPlaybackStateChanged);
    _processPendingIncrements();
  }

  void _onPlaybackStateChanged() {
    if (!_hasIncrementedView && _playbackManager.isPlaying) {
      _hasIncrementedView = true;
      _incrementViewCount();
    }
  }

  @override
  void dispose() {
    _playbackManager.removeListener(_onPlaybackStateChanged);
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    if (_playbackManager.currentMeditation?.id == _currentMeditation?.id) {
      _playbackManager.pause();
    }
    _videoController?.dispose();
    super.dispose();
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
    }
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _updateOnlineStatus(ConnectivityResult result) {
    final hasInternet = result != ConnectivityResult.none;
    if (mounted) {
      setState(() {
        _isOnline = hasInternet;
      });
      if (_isOnline) _processPendingIncrements();
    }
  }

  // ========== INCRÉMENTATION DES VUES (avec file d'attente) ==========
  Future<void> _incrementViewCount() async {
    final assetId = _currentMeditation!.audioVideoAssetId;
    if (assetId == null) return;

    if (_isOnline) {
      try {
        await _mediaService?.incrementViewCount(assetId);
        if (kDebugMode)
          print('👁️ Vue incrémentée pour ${_currentMeditation!.id}');
      } catch (e) {
        if (kDebugMode) print('❌ Erreur incrémentation vue: $e');
      }
    } else {
      await _storePendingIncrement(assetId);
      if (kDebugMode) print('📴 Vue mise en file d\'attente pour $assetId');
    }
  }

  Future<void> _storePendingIncrement(int assetId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList('pending_views') ?? [];
    pending.add(assetId.toString());
    await prefs.setStringList('pending_views', pending);
  }

  Future<void> _processPendingIncrements() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_views');
    if (pending == null || pending.isEmpty) return;

    final newPending = <String>[];
    for (final idStr in pending) {
      final assetId = int.tryParse(idStr);
      if (assetId == null) continue;
      try {
        await _mediaService?.incrementViewCount(assetId);
        if (kDebugMode) print('✅ Vue envoyée depuis la file: $assetId');
      } catch (e) {
        newPending.add(idStr);
      }
    }
    await prefs.setStringList('pending_views', newPending);
  }

  // ========== RAFRAÎCHISSEMENT DES DONNÉES ==========
  Future<void> _refreshMeditation() async {
    if (_currentMeditation?.id == null) return;
    try {
      print('🔄 Rafraîchissement de la méditation ${_currentMeditation!.id}');
      final updated = await _meditationService.getMeditationById(
        _currentMeditation!.id!,
      );
      if (mounted) {
        setState(() {
          _currentMeditation = updated;
          print(
            '✅ Données actualisées : vues=${updated.viewCount}, completions=${updated.completionCount}',
          );
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur refresh méditation: $e');
    }
  }

  // ========== CHARGEMENT DES INFORMATIONS ==========
  Future<void> _loadMediaType() async {
    try {
      if (_currentMeditation!.audioVideoAssetId != null) {
        final mediaType = await _meditationService.getMediaType(
          _currentMeditation!.audioVideoAssetId!,
        );
        if (!_isDisposed && mounted)
          setState(() => _mediaType = mediaType);
        else
          _mediaType = mediaType;
      } else {
        if (!_isDisposed && mounted)
          setState(() => _mediaType = 'AUDIO');
        else
          _mediaType = 'AUDIO';
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur détection type média: $e');
      if (!_isDisposed && mounted)
        setState(() => _mediaType = 'AUDIO');
      else
        _mediaType = 'AUDIO';
    }
  }

  Future<void> _checkIfCached() async {
    if (_currentMeditation!.audioVideoAssetId == null) return;

    final isCached = await _cacheService.isCached(
      _currentMeditation!.audioVideoAssetId!,
    );
    if (!_isDisposed && mounted) setState(() => _isCached = isCached);
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
    if (_currentMeditation!.audioVideoAssetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun média associé'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier l'abonnement pour les méditations premium
    if (_currentMeditation!.isPremium) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      // Rafraîchir en ligne
      await subscriptionProvider.refreshSubscription();
      if (!subscriptionProvider.isPremium) {
        _showPremiumDialog();
        return;
      }
    }

    setState(() => _isDownloading = true);

    try {
      final mediaType =
          _mediaType ??
          await _meditationService.getMediaType(
            _currentMeditation!.audioVideoAssetId!,
          );
      final success = await _meditationService.downloadAndCacheMedia(
        _currentMeditation!.audioVideoAssetId!,
        mediaType,
      );
      if (success && mounted) {
        setState(() => _isCached = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Méditation téléchargée'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else
        throw Exception('Échec téléchargement');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _deleteFromCache() async {
    if (_currentMeditation!.audioVideoAssetId == null) return;
    try {
      await _cacheService.deleteMedia(_currentMeditation!.audioVideoAssetId!);
      if (mounted) setState(() => _isCached = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Média supprimé du cache'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
    }
  }

  // ========== DÉMARRAGE DE LA MÉDITATION ==========
  Future<void> _startMeditation() async {
    _incrementViewCount();

    if (_currentMeditation!.isPremium) {
      // Récupérer le provider d'abonnement
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      // Rafraîchir en ligne si possible, sinon utiliser le cache
      if (_isOnline) {
        await subscriptionProvider.refreshSubscription();
      }
      // Si l'utilisateur n'est pas premium, afficher la popup et arrêter
      if (!subscriptionProvider.isPremium) {
        _showPremiumDialog();
        return;
      }
    }

    if (!_isOnline && !_isCached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '📴 Indisponible hors ligne. Téléchargez-la pour y accéder.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (_mediaType == 'VIDEO')
        await _startVideoPlayback();
      else
        await _startAudioPlayback();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur démarrage: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger le média'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startAudioPlayback() async {
    String? audioUrl;
    bool useLocalFile = false;

    if (_isCached && _currentMeditation!.audioVideoAssetId != null) {
      final cachedUrl = await _cacheService.getMediaUrl(
        _currentMeditation!.audioVideoAssetId!,
      );
      if (cachedUrl != null) {
        audioUrl = cachedUrl;
        useLocalFile = true;
        if (kDebugMode) print('🎵 Lecture depuis cache: $cachedUrl');
      }
    }

    if (audioUrl == null) {
      if (!_isOnline) throw Exception('Pas de connexion');
      audioUrl = await _meditationService.getStreamUrl(
        _currentMeditation!.audioVideoAssetId!,
      );
      useLocalFile = false;
    }

    await _playbackManager.loadAndPlayMeditation(
      _currentMeditation!,
      audioUrl: audioUrl,
      headers: null,
      autoPlay: true,
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationPlayerPage(
          meditation: _currentMeditation!,
          playbackManager: _playbackManager,
          audioHeaders: null,
          mediaType: _mediaType ?? 'AUDIO',
          useLocalFile: useLocalFile,
        ),
      ),
    );
    // Après le retour du lecteur, on rafraîchit les données
    await Future.delayed(const Duration(milliseconds: 800));
    _refreshMeditation();
  }

  Future<void> _startVideoPlayback() async {
    String? videoUrl;
    bool isLocalFile = false;

    if (_isCached && _currentMeditation!.audioVideoAssetId != null) {
      final cachedUrl = await _cacheService.getMediaUrl(
        _currentMeditation!.audioVideoAssetId!,
      );
      if (cachedUrl != null) {
        videoUrl = cachedUrl;
        isLocalFile = true;
        if (kDebugMode) print('🎬 Vidéo depuis cache: $cachedUrl');
      }
    }

    if (videoUrl == null) {
      if (!_isOnline) throw Exception('Pas de connexion');
      videoUrl = await _meditationService.getStreamUrl(
        _currentMeditation!.audioVideoAssetId!,
      );
      isLocalFile = false;
    }

    try {
      VideoPlayerController controller;
      if (isLocalFile) {
        final filePath = videoUrl.replaceFirst('file://', '');
        controller = VideoPlayerController.file(File(filePath));
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      _videoController = controller;
      await _videoController!.initialize().timeout(const Duration(seconds: 15));
      if (_videoController!.value.isInitialized) {
        await _videoController!.play();
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              meditation: _currentMeditation!,
              videoController: _videoController!,
              mediaType: _mediaType!,
              isLocalFile: isLocalFile,
            ),
          ),
        ).then((_) {
          _videoController?.dispose();
          _videoController = null;
        });
        await Future.delayed(const Duration(milliseconds: 800));
        _refreshMeditation(); // rafraîchissement après la vidéo
      } else
        throw Exception('Échec init vidéo');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur vidéo: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lecture vidéo impossible, passage audio'),
            backgroundColor: Colors.orange,
          ),
        );
      await _startAudioPlayback();
    }
  }

  // ========== NOTATION (inchangée) ==========
  void _showRatingDialog() {
    setState(() {
      _isRatingDialogVisible = true;
      _selectedRating = _userRating?.toDouble() ?? 0.0;
      _feedbackController.clear();
      _difficultyPerception = null;
      _enjoymentScore = null;
    });
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      _showErrorMessage('Veuillez donner une note');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final updatedMeditation = await _meditationService.rateMeditation(
        _currentMeditation!.id!,
        _selectedRating,
      );
      setState(() {
        _userRating = _selectedRating.toInt();
        _isRatingDialogVisible = false;
        _currentMeditation = updatedMeditation; // mise à jour locale
      });
      _showSuccessMessage(
        title: 'Merci !',
        message: 'Votre note a été enregistrée',
        icon: Icons.star,
      );
    } catch (e) {
      _showErrorMessage('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Contenu Premium'),
          ],
        ),
        content: const Text(
          'Cette méditation est réservée aux membres Premium. Abonnez-vous pour débloquer tout le contenu exclusif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Voir les offres'),
          ),
        ],
      ),
    );
  }

  // ========== CACHE DES IMAGES ==========
  Future<Directory> _getImageCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/image_cache');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  Future<void> _cachePosterImage(int assetId, String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final imageDir = await _getImageCacheDirectory();
        final fileName = 'poster_$assetId.jpg';
        final file = File('${imageDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Store metadata in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_image_$assetId', file.path);
        if (kDebugMode)
          print('🖼️ Image de couverture mise en cache pour $assetId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Échec cache image: $e');
    }
  }

  Widget _buildMeditationImage() {
    final assetId = _currentMeditation!.posterImageAssetId;
    if (assetId == null) return _buildFallbackImage();
    if (_currentUserId == null) return _buildFallbackImage();

    return FutureBuilder<String?>(
      future: _getCachedImagePath(assetId),
      builder: (context, cacheSnapshot) {
        // Si déjà en cache, afficher directement
        if (cacheSnapshot.connectionState == ConnectionState.done &&
            cacheSnapshot.hasData &&
            cacheSnapshot.data != null) {
          final filePath = cacheSnapshot.data!;
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(filePath),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackImage(),
            ),
          );
        }

        // Sinon, charger l'URL signée et mettre en cache
        return FutureBuilder<String?>(
          future: _mediaService?.getStreamUrl(assetId, _currentUserId!),
          builder: (context, urlSnapshot) {
            if (urlSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingPlaceholder();
            }
            if (urlSnapshot.hasData && urlSnapshot.data != null) {
              final imageUrl = urlSnapshot.data!;
              // Lancer le cache en arrière-plan
              _cachePosterImage(assetId, imageUrl);
              // Afficher avec CachedNetworkImage pendant le téléchargement
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _buildLoadingPlaceholder(),
                  errorWidget: (_, __, ___) => _buildFallbackImage(),
                ),
              );
            }
            return _buildFallbackImage();
          },
        );
      },
    );
  }

  Future<String?> _getCachedImagePath(int assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('cached_image_$assetId');
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: 200,
      color: Colors.grey.shade200,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Meditation.getCategoryColor(_currentMeditation!.category),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Meditation.getCategoryColor(_currentMeditation!.category),
            Meditation.getCategoryColor(
              _currentMeditation!.category,
            ).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Meditation.getCategoryIcon(_currentMeditation!.category),
          size: 80,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  // ========== WIDGETS (réécrits avec _currentMeditation) ==========
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderDesktop(),
                const SizedBox(height: 24),
                _buildMeditationImage(),
                const SizedBox(height: 24),
                _buildMediaTypeIndicator(),
                const SizedBox(height: 16),
                _buildInfoChips(),
                const SizedBox(height: 32),
                _buildDescriptionSection(),
                const SizedBox(height: 32),
                _buildStatsGrid(),
                const SizedBox(height: 32),
                _buildRatingButton(),
              ],
            ),
          ),
        ),
        Container(width: 1, color: Colors.grey.shade300),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey.shade50,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _mediaType == 'VIDEO'
                                ? 'Lecteur Vidéo'
                                : 'Lecteur Audio',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const Spacer(),
                          if (_isCached) _buildOfflineBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentMeditation!.title,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 400,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Meditation.getCategoryIcon(
                              _currentMeditation!.category,
                            ),
                            size: 100,
                            color: Meditation.getCategoryColor(
                              _currentMeditation!.category,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMediaTypeIndicator(),
                          const SizedBox(height: 32),
                          if (_mediaType == 'AUDIO')
                            AudioControls(
                              playbackManager: _playbackManager,
                              showTitle: false,
                              showVolumeControls: true,
                            ),
                          const SizedBox(height: 32),
                          _buildPlayButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeaderMobile(),
            title: Text(
              _currentMeditation!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMediaTypeIndicator(),
              ),
              const SizedBox(height: 16),
              _buildDescriptionSection(),
              _buildStats(),
              _buildTags(),
              _buildRatingButton(),
              _buildPlayButton(),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildHeaderDesktop() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            _currentMeditation!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderMobile() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Meditation.getCategoryColor(_currentMeditation!.category),
            Meditation.getCategoryColor(
              _currentMeditation!.category,
            ).withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (_currentMeditation!.posterImageAssetId != null)
            FutureBuilder<String?>(
              future: _mediaService?.getStreamUrl(
                _currentMeditation!.posterImageAssetId!,
                _currentUserId!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const SizedBox.shrink();
                if (snapshot.hasData && snapshot.data != null) {
                  return Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: snapshot.data!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(),
                      errorWidget: (context, url, error) => Container(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Meditation.getCategoryIcon(_currentMeditation!.category),
                  size: 80,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _currentMeditation!.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (_isCached)
            Positioned(top: 16, right: 16, child: _buildOfflineBadge()),
        ],
      ),
    );
  }

  Widget _buildMediaTypeIndicator() {
    if (_mediaType == null) return const SizedBox();
    final isVideo = _mediaType == 'VIDEO';
    final icon = isVideo ? Icons.videocam : Icons.audiotrack;
    final label = isVideo ? 'VIDÉO' : 'AUDIO';
    final color = isVideo ? Colors.red : const Color(0xFF7DBBC3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (_isCached) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.offline_bolt, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Disponible hors-ligne',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        Chip(
          label: Text(_currentMeditation!.formattedDuration),
          avatar: const Icon(Icons.access_time, size: 16),
        ),
        Chip(
          label: Text(_currentMeditation!.category),
          backgroundColor: Meditation.getCategoryColor(
            _currentMeditation!.category,
          ).withOpacity(0.1),
        ),
        if (_currentMeditation!.instructorName != null)
          Chip(
            label: Text('Par ${_currentMeditation!.instructorName!}'),
            avatar: const Icon(Icons.person, size: 16),
          ),
        if (_currentMeditation!.isPremium)
          Chip(
            label: const Text('PREMIUM'),
            backgroundColor: Colors.amber.withOpacity(0.2),
            avatar: const Icon(
              Icons.workspace_premium,
              size: 16,
              color: Colors.amber,
            ),
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    if (_currentMeditation!.description == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentMeditation!.description!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
            maxLines: _showFullDescription ? null : 3,
            overflow: _showFullDescription ? null : TextOverflow.ellipsis,
          ),
          if (!_showFullDescription &&
              _currentMeditation!.description!.length > 100)
            TextButton(
              onPressed: () => setState(() => _showFullDescription = true),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              child: const Text(
                'Voir plus',
                style: TextStyle(
                  color: Color(0xFF7DBBC3),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2,
      children: [
        _buildStatCard(
          'Vues',
          '${_currentMeditation!.viewCount}',
          Icons.remove_red_eye,
        ),
        _buildStatCard(
          'Complétions',
          '${_currentMeditation!.completionCount}',
          Icons.check_circle,
        ),
        _buildStatCard(
          'Note',
          _currentMeditation!.formattedRating ?? '0.0',
          Icons.star,
        ),
        _buildStatCard(
          'Durée',
          _currentMeditation!.formattedDuration,
          Icons.timer,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7DBBC3), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.remove_red_eye,
            '${_currentMeditation!.viewCount}',
            'Vues',
          ),
          _buildStatItem(
            Icons.check_circle,
            '${_currentMeditation!.completionCount}',
            'Complétions',
          ),
          _buildStatItem(
            Icons.star,
            _currentMeditation!.formattedRating ?? '0.0',
            'Note',
          ),
          _buildStatItem(
            Icons.timer,
            _currentMeditation!.formattedDuration,
            'Durée',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF7DBBC3).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF7DBBC3), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTags() {
    if (_currentMeditation!.tags == null || _currentMeditation!.tags!.isEmpty)
      return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentMeditation!.tags!.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DBBC3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF7DBBC3).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton() {
    if (_currentMeditation!.isPremium) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _showRatingDialog,
        icon: const Icon(Icons.star_border, color: Color(0xFF7DBBC3)),
        label: const Text('Évaluer cette méditation'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    if (_currentMeditation!.isPremium) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _startMeditation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: _isLoading
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Débloquer Premium',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    Color buttonColor = _mediaType == 'VIDEO'
        ? Colors.red
        : const Color(0xFF7DBBC3);
    if (_isCached) buttonColor = Colors.green;

    final bool canPlay = _isOnline || _isCached;
    final String buttonText;
    if (!canPlay)
      buttonText = 'Indisponible hors-ligne';
    else if (_isCached)
      buttonText = _mediaType == 'VIDEO'
          ? 'Regarder (hors-ligne)'
          : 'Écouter (hors-ligne)';
    else
      buttonText = _mediaType == 'VIDEO'
          ? 'Regarder maintenant'
          : 'Écouter maintenant';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ElevatedButton(
        onPressed: canPlay ? (_isLoading ? null : _startMeditation) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canPlay ? buttonColor : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canPlay ? 4 : 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isCached) ...[
                    const Icon(Icons.offline_bolt, size: 24),
                    const SizedBox(width: 12),
                  ] else if (!canPlay) ...[
                    const Icon(Icons.wifi_off, size: 24),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    _mediaType == 'VIDEO' ? Icons.videocam : Icons.play_arrow,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ========== DIALOGUE DE NOTATION ==========
  Widget _buildRatingDialog() {
    if (!_isRatingDialogVisible) return const SizedBox.shrink();

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
                        'Évaluez cette méditation',
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
                          onRatingUpdate: (rating) =>
                              setState(() => _selectedRating = rating),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_difficultyPerception == null) ...[
                        const Text(
                          'Cette méditation était-elle difficile ?',
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
                              onSelected: (selected) => setState(
                                () => _difficultyPerception = selected
                                    ? level
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_enjoymentScore == null) ...[
                        const Text(
                          'Avez-vous apprécié cette méditation ?',
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
                              onSelected: (selected) => setState(
                                () => _enjoymentScore = selected ? score : null,
                              ),
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
                          hintText: 'Qu\'avez-vous pensé de cette méditation ?',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _isRatingDialogVisible = false;
                              _selectedRating = 0.0;
                              _feedbackController.clear();
                              _difficultyPerception = null;
                              _enjoymentScore = null;
                            }),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _submitRating,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7DBBC3),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          MediaQuery.of(context).size.width >= 600
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
          _buildRatingDialog(),
        ],
      ),
    );
  }
}

// =============================================================================
// Les classes suivantes (MeditationPlayerPage, VideoPlayerPage, VideoProgressBar)
// restent strictement identiques à la version précédente – aucun changement.
// =============================================================================
// (Ces classes sont inchangées, je les ai donc laissées dans votre code original)
// PAGE DE LECTURE AUDIO (avec support cache)
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

    // Vérification périodique pour la complétion
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

    // Ne vérifier que si la lecture est en cours
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
                  // Menu de vitesse
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
              // Indicateur de vitesse
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
                    // Slider de vitesse pour mobile
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
// PAGE DE LECTURE VIDÉO (avec support cache et vitesse)
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

    // Vérification périodique pour la complétion
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
              // Indicateur de vitesse
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
                  // Indicateur de vitesse
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
                          // Menu de vitesse
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
                    // Indicateur de vitesse
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
                    // Menu de vitesse
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
