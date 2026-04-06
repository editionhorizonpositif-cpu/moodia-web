// lib/pages/meditation_list_page.dart - Version avec cache persistant des images + métadonnées
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../models/meditation.dart';
import '../services/meditation_service.dart';
import '../services/api_service.dart';
import '../services/media_cache_service.dart';
import '../services/media_service.dart';
import 'meditation_detail_page.dart';
import 'subscription_plan_page.dart';
import 'add_meditation_page.dart';
import '../services/auth_service.dart';

class MeditationListPage extends StatefulWidget {
  const MeditationListPage({super.key});

  @override
  State<MeditationListPage> createState() => _MeditationListPageState();
}

class _MeditationListPageState extends State<MeditationListPage> {
  late MeditationService _meditationService;
  late ApiService _apiService;
  late MediaCacheService _cacheService;
  late MediaService _mediaService;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Meditation> _meditations = [];
  List<Meditation> _cachedMeditations = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 12;
  String _selectedCategory = 'Toutes';
  String _searchQuery = '';
  String? _errorMessage;
  bool _isInitialized = false;
  bool _isAdminOrCreator = false;

  bool _isOnline = true;
  String? _connectionStatus;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final Map<int, String> _mediaTypeCache = {};
  final Map<int, bool> _isCachedCache = {};

  // Cache pour les URLs des images (pré-signées) et les chemins locaux
  final Map<int, String> _posterImageUrls = {};
  final Map<int, String> _posterImagePaths = {};

  int? _userId;

  final List<String> _categories = [
    'Toutes',
    'Méditation',
    'Sommeil',
    'Stress',
    'Concentration',
    'Relaxation',
    'Yoga',
    'Respiration',
    'Pleine Conscience',
  ];

  int get _crossAxisCount {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double get _cardAspectRatio {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) return 0.85;
    if (width > 600) return 0.9;
    return 1.2;
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('🧘‍♀️ INIT MeditationListPage');
    _initializeConnectivity();
    _initializeServices();
    _loadUserId();
  }

  // ========== CONNECTIVITÉ ==========
  Future<void> _initializeConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateOnlineStatus(result);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        ConnectivityResult result,
      ) {
        if (mounted) _updateOnlineStatus(result);
      });
    } catch (e) {
      debugPrint('Erreur initialisation connectivité: $e');
      setState(() {
        _isOnline = false;
        _connectionStatus = '📴 Hors ligne (par défaut)';
      });
    }
  }

  void _updateOnlineStatus(ConnectivityResult result) {
    final hasInternet = result != ConnectivityResult.none;
    if (mounted) {
      setState(() {
        _isOnline = hasInternet;
        _connectionStatus = hasInternet ? '📶 En ligne' : '📴 Hors ligne';
      });
    }
    debugPrint('État connexion: $_connectionStatus');
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
  }

  // ========== SERVICES ==========
  Future<void> _initializeServices() async {
    if (kDebugMode)
      print('🔧 Initialisation des services MeditationListPage...');

    try {
      _apiService = Provider.of<ApiService>(context, listen: false);
      await _apiService.initialize();
      _meditationService = MeditationService(_apiService);
      await _meditationService.initialize();
      _cacheService = MediaCacheService();
      _mediaService = Provider.of<MediaService>(context, listen: false);

      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      setState(() {
        _isAdminOrCreator =
            (user?.isAdmin == true) || (user?.isContentCreator == true);
        _isInitialized = true; // ← Correction
      });

      if (kDebugMode) print('✅ Services initialisés avec succès');

      await _loadMeditations();
      _scrollController.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _precacheMediaIfNeeded();
      });
    } catch (e) {
      if (kDebugMode) print('❌ Erreur initialisation services: $e');
      setState(() {
        _errorMessage = 'Erreur d\'initialisation: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ========== GESTION DU CACHE DES IMAGES ==========

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_image_$assetId', file.path);
        if (kDebugMode)
          print('🖼️ Image de couverture mise en cache pour $assetId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Échec cache image: $e');
    }
  }

  Future<String?> _getCachedImagePath(int assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('cached_image_$assetId');
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  Future<String?> _getPresignedImageUrl(int assetId) async {
    if (_posterImageUrls.containsKey(assetId)) return _posterImageUrls[assetId];
    if (_userId == null) return null;
    try {
      final url = await _mediaService.getStreamUrl(assetId, _userId!);
      if (url.isNotEmpty) _posterImageUrls[assetId] = url;
      return url;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur obtention URL image: $e');
      return null;
    }
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // ========== CACHE DES MÉTADONNÉES ==========
  Map<String, dynamic> _meditationToJson(Meditation m) {
    return {
      'id': m.id,
      'title': m.title,
      'description': m.description,
      'duration': m.durationMin,
      'category': m.category,
      'instructorName': m.instructorName,
      'audioVideoAssetId': m.audioVideoAssetId,
      'posterImageAssetId': m.posterImageAssetId,
      'isPremium': m.isPremium,
      'viewCount': m.viewCount,
      'completionCount': m.completionCount,
      'averageRating': m.averageRating,
      'ratingCount': m.ratingCount,
      'tags': m.tags,
    };
  }

  Future<void> _saveMeditationsToCache(List<Meditation> meditations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final meditationsJson = meditations.map(_meditationToJson).toList();
      await prefs.setString('cached_meditations', jsonEncode(meditationsJson));
      if (kDebugMode)
        print('💾 Méditations sauvegardées en cache (${meditations.length})');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sauvegarde cache méditations: $e');
    }
  }

  Future<List<Meditation>> _loadMeditationsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_meditations');
      if (jsonString == null) return [];
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final meditations = jsonList
          .map((json) => Meditation.fromJson(json as Map<String, dynamic>))
          .toList();
      if (kDebugMode)
        print(
          '📦 Méditations chargées depuis le cache (${meditations.length})',
        );
      return meditations;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement cache méditations: $e');
      return [];
    }
  }

  // ========== CHARGEMENT DES MÉDITATIONS ==========
  Future<void> _loadMeditations({bool reset = false}) async {
    if (!_isInitialized) return;

    if (reset) {
      setState(() {
        _currentPage = 0;
        _meditations = [];
        _hasMore = true;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    if (kDebugMode)
      print(
        '📥 Chargement méditations (online: $_isOnline, page: $_currentPage)...',
      );

    try {
      if (_isOnline) {
        final response = await _meditationService.getMeditationsPaginated(
          page: _currentPage,
          size: _pageSize,
          sort: 'displayOrder,asc',
        );

        if (kDebugMode) {
          print('✅ Méditations reçues: ${response.content.length}');
          print('✅ Page: ${response.page + 1}/${response.totalPages}');
        }

        if (reset) {
          _cachedMeditations = response.content;
        } else {
          _cachedMeditations.addAll(response.content);
        }

        // Persist the entire cached list after each successful load
        await _saveMeditationsToCache(_cachedMeditations);

        _updateMediaCaches(response.content);

        setState(() {
          if (reset) {
            _meditations = response.content;
          } else {
            _meditations.addAll(response.content);
          }
          _hasMore = !response.last;
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
          if (!response.last) _currentPage++;
        });
      } else {
        // Offline: load from persisted cache
        final cachedList = await _loadMeditationsFromCache();
        if (cachedList.isNotEmpty) {
          setState(() {
            _meditations = cachedList;
            _cachedMeditations = cachedList; // also keep in memory
            _isLoading = false;
            _hasMore = false; // no pagination offline
            _errorMessage = null;
          });
          if (kDebugMode)
            print(
              '📦 ${cachedList.length} méditations chargées depuis le cache permanent',
            );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Aucune donnée en cache. Connectez-vous pour télécharger des méditations.';
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement méditations: $e');

      if (_isOnline && _cachedMeditations.isNotEmpty) {
        if (kDebugMode) print('⚠️ Utilisation du cache suite à une erreur');
        setState(() {
          _meditations = _cachedMeditations;
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = false;
          _errorMessage = 'Données en cache affichées (serveur indisponible)';
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }

      if (e.toString().contains('Session expirée') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        _showSessionExpiredDialog();
      }
    }
  }

  void _updateMediaCaches(List<Meditation> meditations) {
    for (final meditation in meditations) {
      if (meditation.audioVideoAssetId != null) {
        _meditationService.getMediaType(meditation.audioVideoAssetId!).then((
          type,
        ) {
          _mediaTypeCache[meditation.audioVideoAssetId!] = type;
          _cacheService.isCached(meditation.audioVideoAssetId!).then((
            isCached,
          ) {
            _isCachedCache[meditation.audioVideoAssetId!] = isCached;
            if (mounted) setState(() {});
          });
        });
      }
    }
  }

  Future<void> _precacheMediaIfNeeded() async {
    if (_meditations.isEmpty) return;
    final meditationsToPrecache = _meditations.take(5).toList();
    for (final meditation in meditationsToPrecache) {
      if (meditation.audioVideoAssetId != null) {
        final isCached = await _cacheService.isCached(
          meditation.audioVideoAssetId!,
        );
        if (!isCached && _isOnline) {
          final mediaType =
              _mediaTypeCache[meditation.audioVideoAssetId] ??
              await _meditationService.getMediaType(
                meditation.audioVideoAssetId!,
              );
          _meditationService
              .downloadAndCacheMedia(meditation.audioVideoAssetId!, mediaType)
              .then((success) {
                if (success && mounted) {
                  setState(() {
                    _isCachedCache[meditation.audioVideoAssetId!] = true;
                  });
                }
              });
        }
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading &&
        _isOnline) {
      _loadMoreMeditations();
    }
  }

  Future<void> _loadMoreMeditations() async {
    if (_isLoadingMore || !_hasMore || !_isOnline) return;
    setState(() => _isLoadingMore = true);
    await _loadMeditations(reset: false);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == value) _performSearch();
    });
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _resetFilters();
    } else {
      setState(() {
        _currentPage = 0;
        _meditations = [];
        _hasMore = true;
        _isLoading = true;
      });
      _loadMeditations(reset: true);
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _currentPage = 0;
      _meditations = [];
      _hasMore = true;
      _isLoading = true;
    });
    _loadMeditations(reset: true);
  }

  Future<void> _resetFilters() async {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'Toutes';
      _currentPage = 0;
      _meditations = [];
      _hasMore = true;
      _isLoading = true;
    });
    await _loadMeditations(reset: true);
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session expirée'),
        content: const Text(
          'Votre session a expiré. Veuillez vous reconnecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ========== WIDGETS ==========
  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        backgroundColor: Colors.white,
        selectedColor: Meditation.getCategoryColor(category),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        onSelected: (_) => _onCategorySelected(category),
      ),
    );
  }

  Widget _buildMediaTypeIcon(int? assetId) {
    if (assetId == null) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.audiotrack, color: Colors.white, size: 16),
      );
    }

    return FutureBuilder<bool>(
      future: _cacheService.isCached(assetId),
      builder: (context, snapshot) {
        final isCached = snapshot.data ?? false;
        return FutureBuilder<String>(
          future: _meditationService.getMediaType(assetId),
          builder: (context, typeSnapshot) {
            final mediaType = typeSnapshot.data ?? 'AUDIO';
            final isAudio = mediaType == 'AUDIO';
            return Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCached
                    ? Colors.green.withOpacity(0.8)
                    : Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAudio ? Icons.audiotrack : Icons.videocam,
                    color: Colors.white,
                    size: 12,
                  ),
                  if (isCached) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 10,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ========== IMAGE AVEC CACHE PERSISTANT ==========
  Widget _buildMeditationImage(Meditation meditation) {
    final assetId = meditation.posterImageAssetId;
    if (assetId == null) return _buildFallbackImage(meditation);

    // Vérifier d'abord si le fichier existe en cache local
    return FutureBuilder<String?>(
      future: _getCachedImagePath(assetId),
      builder: (context, cacheSnapshot) {
        // Si déjà en cache, on affiche directement Image.file
        if (cacheSnapshot.connectionState == ConnectionState.done &&
            cacheSnapshot.hasData &&
            cacheSnapshot.data != null) {
          final filePath = cacheSnapshot.data!;
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(filePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _buildFallbackImage(meditation),
            ),
          );
        }

        // Sinon, charger l'URL signée et mettre en cache
        return FutureBuilder<String?>(
          future: _getPresignedImageUrl(assetId),
          builder: (context, urlSnapshot) {
            if (urlSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingPlaceholder();
            }
            final imageUrl = urlSnapshot.data;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              // Lancer le cache en arrière-plan
              _cachePosterImage(assetId, imageUrl);
              // Afficher avec CachedNetworkImage (temporaire)
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) => _buildLoadingPlaceholder(),
                  errorWidget: (_, __, ___) => _buildFallbackImage(meditation),
                ),
              );
            } else {
              return _buildFallbackImage(meditation);
            }
          },
        );
      },
    );
  }

  Widget _buildFallbackImage(Meditation meditation) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Meditation.getCategoryColor(meditation.category),
            Meditation.getCategoryColor(meditation.category).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Meditation.getCategoryIcon(meditation.category),
          size: 60,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  // ========== CARTE DE MÉDITATION ==========
  Widget _buildMeditationCard(Meditation meditation) {
    final isPremium = meditation.isPremium;
    final isCached = _isCachedCache[meditation.audioVideoAssetId] ?? false;
    final mediaType = _mediaTypeCache[meditation.audioVideoAssetId] ?? 'AUDIO';
    final isVideo = mediaType == 'VIDEO';

    return Card(
      margin: EdgeInsets.all(_crossAxisCount > 1 ? 8 : 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToMeditationDetail(meditation),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Image de fond (pleine carte)
            Positioned.fill(child: _buildMeditationImage(meditation)),
            // Overlay sombre pour lisibilité
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isCached)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.offline_bolt,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Hors-ligne',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isPremium && !isCached)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meditation.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (meditation.description != null)
                        Text(
                          meditation.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isVideo ? Icons.videocam : Icons.audiotrack,
                                  size: 10,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isVideo ? 'VIDÉO' : 'AUDIO',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 10,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  meditation.formattedDuration,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: meditation.averageRating ?? 0.0,
                            itemBuilder: (context, _) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 12,
                            unratedColor: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${meditation.ratingCount})',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${meditation.viewCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _buildPlayButton(meditation),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(Meditation meditation) {
    final isCached = _isCachedCache[meditation.audioVideoAssetId] ?? false;
    final mediaType = _mediaTypeCache[meditation.audioVideoAssetId] ?? 'AUDIO';
    final isVideo = mediaType == 'VIDEO';

    if (meditation.isPremium) {
      return ElevatedButton(
        onPressed: () => _navigateToSubscription(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 32),
        ),
        child: const Text(
          'DÉBLOQUER',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (meditation.audioVideoAssetId == null) {
      return ElevatedButton(
        onPressed: () => _navigateToMeditationDetail(meditation),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7DBBC3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(double.infinity, 32),
        ),
        child: Text(
          isVideo ? 'REGARDER' : 'ÉCOUTER',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _navigateToMeditationDetail(meditation),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCached
            ? Colors.green.shade600
            : const Color(0xFF7DBBC3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isCached) ...[
            const Icon(Icons.offline_bolt, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            isVideo ? 'REGARDER' : 'ÉCOUTER',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: _cardAspectRatio,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: const Color(0xFF7DBBC3).withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune méditation trouvée',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Essayez une autre catégorie'
                : 'Essayez avec d\'autres critères de recherche',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          if (_searchQuery.isNotEmpty || _selectedCategory != 'Toutes')
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7DBBC3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Réinitialiser les filtres',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: const Color(0xFFE55039)),
          const SizedBox(height: 20),
          Text(
            'Erreur de chargement',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DBBC3),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF7DBBC3)),
        ),
      ),
    );
  }

  void _navigateToMeditationDetail(Meditation meditation) {
    if (meditation.isPremium) {
      _navigateToSubscription();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeditationDetailPage(meditation: meditation),
      ),
    );
  }

  void _navigateToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPlanPage()),
    );
  }

  void _navigateToAddMeditation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMeditationPage()),
    );
  }

  Future<void> _showCacheStats() async {
    final stats = await _meditationService.getCacheStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache média'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📦 Taille: ${stats['size']}'),
            Text('📁 Fichiers: ${stats['count']}'),
            const SizedBox(height: 16),
            const Text(
              'Les médias en cache sont disponibles hors-ligne.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () async {
              await _meditationService.clearCache();
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cache vidé')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DBBC3),
        elevation: 0,
        title: const Text(
          'Méditations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
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
          IconButton(
            icon: const Icon(Icons.storage, color: Colors.white),
            onPressed: _showCacheStats,
            tooltip: 'Statistiques du cache',
          ),
          if (_isAdminOrCreator)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _navigateToAddMeditation,
              tooltip: 'Ajouter une méditation',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetFilters,
            tooltip: 'Actualiser',
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7DBBC3), Color(0xFF5CA8B0)],
            ),
          ),
        ),
      ),
      body: _isInitialized
          ? Column(
              children: [
                // Search header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Rechercher une méditation...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catégories',
                            style: TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _categories
                                  .map(_buildCategoryChip)
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _isLoading
                      ? _buildShimmerGrid()
                      : _errorMessage != null
                      ? _buildErrorState()
                      : _meditations.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _resetFilters,
                          color: const Color(0xFF7DBBC3),
                          child: CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _crossAxisCount,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: _cardAspectRatio,
                                      ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildMeditationCard(
                                      _meditations[index],
                                    ),
                                    childCount: _meditations.length,
                                  ),
                                ),
                              ),
                              if (_hasMore && _isOnline)
                                SliverToBoxAdapter(
                                  child: _buildLoadingMoreIndicator(),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF7DBBC3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Initialisation...',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Chargement des services',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isInitialized && _isAdminOrCreator
          ? FloatingActionButton(
              onPressed: _navigateToAddMeditation,
              backgroundColor: const Color(0xFF7DBBC3),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              tooltip: 'Ajouter une méditation',
            )
          : null,
    );
  }
}
