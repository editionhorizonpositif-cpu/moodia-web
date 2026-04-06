// lib/pages/activities_page.dart - Version avec vues, rating et favoris
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/activity.dart';
import '../models/activity_category.dart';
import '../services/activity_api_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/media_cache_service.dart';
import '../services/media_service.dart';
import 'activity_detail_page.dart';
import 'add_activity_page.dart';
import '../models/activity_dtos.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Services
  late ActivityApiService _activityService;
  late AuthService _authService;
  late ApiService _apiService;
  late MediaCacheService _cacheService;
  late MediaService _mediaService;

  // Collections de données
  final List<Activity> _activities = [];
  final List<ActivityCategory> _categories = [];
  final List<Activity> _recommendedActivities = [];
  final List<Activity> _popularActivities = [];
  final List<Activity> _newActivities = [];

  // Cache local
  List<Activity> _cachedActivities = [];
  List<ActivityCategory> _cachedCategories = [];
  List<Activity> _cachedRecommendedActivities = [];
  List<Activity> _cachedPopularActivities = [];
  List<Activity> _cachedNewActivities = [];

  final Map<int, String> _coverImageUrls = {};

  bool _isLoading = true;
  bool _isLoadingCategories = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isInitialized = false;

  bool _isLoadingRecommended = false;
  bool _isLoadingPopular = false;
  bool _isLoadingNew = false;

  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _showCompletedOnly = false;
  String _selectedDuration = 'all';
  String _selectedDifficulty = 'all';

  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool _isGridView = true;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  Set<int> _startingActivities = {};

  Map<String, dynamic>? _userStats;

  bool _isOnline = true;
  String? _connectionStatus;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  int? _userId;
  late AnimationController _animationController;

  int get _crossAxisCount {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 4;
    if (width > 1100) return 3;
    if (width > 800) return 2;
    return 2;
  }

  double get _cardAspectRatio {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 0.72;
    if (width > 1100) return 0.75;
    if (width > 800) return 0.78;
    return 0.8;
  }

  double get _featuredCardWidth {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 380;
    if (width > 1100) return 340;
    if (width > 800) return 300;
    return width * 0.75;
  }

  EdgeInsets get _contentPadding {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400)
      return const EdgeInsets.symmetric(horizontal: 64, vertical: 24);
    if (width > 1100)
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 20);
    if (width > 800)
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    return const EdgeInsets.all(16);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _initListeners();
    _initializeConnectivity();
    _initializeServices();
    _loadUserId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _initListeners() {
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreActivities();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
      _debounceSearch();
    }
  }

  Timer? _searchDebounceTimer;
  void _debounceSearch() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _applyFilters();
    });
  }

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
    if (kDebugMode) print('État connexion: $_connectionStatus');
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
  }

  Future<void> _initializeServices() async {
    if (kDebugMode) print('🚀 Initialisation des services...');
    try {
      _apiService = Provider.of<ApiService>(context, listen: false);
      await _apiService.initialize();
      _activityService = Provider.of<ActivityApiService>(
        context,
        listen: false,
      );
      _authService = Provider.of<AuthService>(context, listen: false);
      _cacheService = MediaCacheService();
      _mediaService = Provider.of<MediaService>(context, listen: false);
      setState(() => _isInitialized = true);
      if (kDebugMode) print('✅ Services initialisés');
      await _loadInitialData();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur initialisation: $e');
      _handleError('Erreur d\'initialisation: ${e.toString()}');
    }
  }

  // ============ GESTION DU CACHE DES IMAGES ==========
  Future<Directory> _getImageCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/image_cache');
    if (!await imageDir.exists()) await imageDir.create(recursive: true);
    return imageDir;
  }

  Future<String?> _getCachedCoverImagePath(int assetId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('cached_cover_image_$assetId');
    if (path != null && await File(path).exists()) return path;
    return null;
  }

  Future<void> _cacheCoverImage(int assetId, String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final imageDir = await _getImageCacheDirectory();
        final file = File('${imageDir.path}/cover_$assetId.jpg');
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

  Future<String?> _getPresignedImageUrl(int assetId) async {
    if (_coverImageUrls.containsKey(assetId)) return _coverImageUrls[assetId];
    if (_userId == null) return null;
    try {
      final url = await _mediaService.getStreamUrl(assetId, _userId!);
      if (url.isNotEmpty) _coverImageUrls[assetId] = url;
      return url;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur obtention URL image: $e');
      return null;
    }
  }

  Future<void> _preloadCoverImages(List<Activity> activities) async {
    for (final activity in activities) {
      if (activity.coverImageAssetId != null &&
          !_coverImageUrls.containsKey(activity.coverImageAssetId)) {
        _getPresignedImageUrl(activity.coverImageAssetId!);
      }
    }
  }

  Widget _buildActivityImage({
    required int? assetId,
    required Color fallbackColor,
    required IconData fallbackIcon,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 16,
  }) {
    if (assetId == null) {
      return _buildFallbackImage(
        color: fallbackColor,
        icon: fallbackIcon,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }
    return FutureBuilder<String?>(
      future: _getCachedCoverImagePath(assetId),
      builder: (context, cacheSnapshot) {
        if (cacheSnapshot.connectionState == ConnectionState.done &&
            cacheSnapshot.hasData &&
            cacheSnapshot.data != null) {
          final filePath = cacheSnapshot.data!;
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              File(filePath),
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => _buildFallbackImage(
                color: fallbackColor,
                icon: fallbackIcon,
                width: width,
                height: height,
                borderRadius: borderRadius,
              ),
            ),
          );
        }
        return FutureBuilder<String?>(
          future: _getPresignedImageUrl(assetId),
          builder: (context, urlSnapshot) {
            if (urlSnapshot.connectionState == ConnectionState.waiting) {
              return _buildImagePlaceholder(
                color: fallbackColor,
                icon: fallbackIcon,
                width: width,
                height: height,
              );
            }
            final imageUrl = urlSnapshot.data;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              _cacheCoverImage(assetId, imageUrl);
              return ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: width,
                  height: height,
                  fit: fit,
                  placeholder: (context, url) => _buildImagePlaceholder(
                    color: fallbackColor,
                    icon: fallbackIcon,
                    width: width,
                    height: height,
                  ),
                  errorWidget: (context, url, error) => _buildFallbackImage(
                    color: fallbackColor,
                    icon: fallbackIcon,
                    width: width,
                    height: height,
                    borderRadius: borderRadius,
                  ),
                ),
              );
            } else {
              return _buildFallbackImage(
                color: fallbackColor,
                icon: fallbackIcon,
                width: width,
                height: height,
                borderRadius: borderRadius,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildImagePlaceholder({
    required Color color,
    required IconData icon,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage({
    required Color color,
    required IconData icon,
    double? width,
    double? height,
    double borderRadius = 16,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: height != null ? height * 0.35 : 40,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  // ============ SAUVEGARDE ET CHARGEMENT DU CACHE ==========
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_activities',
        jsonEncode(_activities.map((a) => a.toJson()).toList()),
      );
      await prefs.setString(
        'cached_categories',
        jsonEncode(_categories.map((c) => c.toJson()).toList()),
      );
      await prefs.setString(
        'cached_recommended',
        jsonEncode(_recommendedActivities.map((a) => a.toJson()).toList()),
      );
      await prefs.setString(
        'cached_popular',
        jsonEncode(_popularActivities.map((a) => a.toJson()).toList()),
      );
      await prefs.setString(
        'cached_new',
        jsonEncode(_newActivities.map((a) => a.toJson()).toList()),
      );
      if (kDebugMode) print('✅ Données sauvegardées en cache');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde cache: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesStr = prefs.getString('cached_activities');
      if (activitiesStr != null) {
        final List<dynamic> activitiesJson = jsonDecode(activitiesStr);
        _cachedActivities = activitiesJson
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      final categoriesStr = prefs.getString('cached_categories');
      if (categoriesStr != null) {
        final List<dynamic> categoriesJson = jsonDecode(categoriesStr);
        _cachedCategories = categoriesJson
            .map(
              (json) => ActivityCategory.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      final recommendedStr = prefs.getString('cached_recommended');
      if (recommendedStr != null) {
        final List<dynamic> recommendedJson = jsonDecode(recommendedStr);
        _cachedRecommendedActivities = recommendedJson
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      final popularStr = prefs.getString('cached_popular');
      if (popularStr != null) {
        final List<dynamic> popularJson = jsonDecode(popularStr);
        _cachedPopularActivities = popularJson
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      final newStr = prefs.getString('cached_new');
      if (newStr != null) {
        final List<dynamic> newJson = jsonDecode(newStr);
        _cachedNewActivities = newJson
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      if (kDebugMode)
        print(
          '📦 Données chargées depuis le cache (${_cachedActivities.length} activités)',
        );
    } catch (e) {
      debugPrint('❌ Erreur chargement cache: $e');
    }
  }

  // ============ CHARGEMENT DES DONNÉES ==========
  Future<void> _loadInitialData() async {
    if (!mounted || !_isInitialized) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    try {
      if (kDebugMode)
        print('🚀 Début du chargement initial (online: $_isOnline)');
      if (_isOnline) {
        await Future.wait([_loadCategories(), _loadUserStats()]);
        await _loadActivities(reset: true);
        await Future.wait([
          _loadRecommendedActivities(),
          _loadPopularActivities(),
          _loadNewActivities(),
        ]);
        await _preloadCoverImages(_activities);
        await _preloadCoverImages(_recommendedActivities);
        await _preloadCoverImages(_popularActivities);
        await _preloadCoverImages(_newActivities);
        await _saveToCache();
      } else {
        await _loadFromCache();
        setState(() {
          if (_cachedCategories.isNotEmpty)
            _categories.addAll(_cachedCategories);
          if (_cachedActivities.isNotEmpty)
            _activities.addAll(_cachedActivities);
          if (_cachedRecommendedActivities.isNotEmpty)
            _recommendedActivities.addAll(_cachedRecommendedActivities);
          if (_cachedPopularActivities.isNotEmpty)
            _popularActivities.addAll(_cachedPopularActivities);
          if (_cachedNewActivities.isNotEmpty)
            _newActivities.addAll(_cachedNewActivities);
          _isLoadingCategories = false;
          _hasMore = false;
        });
      }
      _animationController.forward();
      if (kDebugMode) print('✅ Toutes les données chargées');
    } catch (e) {
      if (kDebugMode) print('❌ ERREUR chargement: $e');
      if (_isOnline && _cachedActivities.isNotEmpty) {
        if (kDebugMode) print('⚠️ Utilisation du cache suite à une erreur');
        setState(() {
          _activities.addAll(_cachedActivities);
          _categories.addAll(_cachedCategories);
          _recommendedActivities.addAll(_cachedRecommendedActivities);
          _popularActivities.addAll(_cachedPopularActivities);
          _newActivities.addAll(_cachedNewActivities);
          _errorMessage = 'Données en cache affichées (serveur indisponible)';
          _isLoading = false;
        });
      } else {
        _handleError('Erreur de chargement: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _activityService.getCategories(activeOnly: true);
      if (mounted)
        setState(() {
          _categories.addAll(categories);
          _cachedCategories = List.from(categories);
          _isLoadingCategories = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
      rethrow;
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _activityService.getUserStats();
      if (mounted) setState(() => _userStats = stats);
    } catch (e) {
      /* ignorer */
    }
  }

  Future<void> _loadRecommendedActivities() async {
    setState(() => _isLoadingRecommended = true);
    try {
      final recommended = await _activityService.getRecommendedActivities(3);
      if (mounted)
        setState(() {
          _recommendedActivities.addAll(recommended);
          _cachedRecommendedActivities = List.from(recommended);
          _isLoadingRecommended = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecommended = false);
      rethrow;
    }
  }

  Future<void> _loadPopularActivities() async {
    setState(() => _isLoadingPopular = true);
    try {
      final popular = await _activityService.getPopularActivities(3);
      if (mounted)
        setState(() {
          _popularActivities.addAll(popular);
          _cachedPopularActivities = List.from(popular);
          _isLoadingPopular = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoadingPopular = false);
      rethrow;
    }
  }

  Future<void> _loadNewActivities() async {
    setState(() => _isLoadingNew = true);
    try {
      final newActivities = await _activityService.getNewActivities(3);
      if (mounted)
        setState(() {
          _newActivities.addAll(newActivities);
          _cachedNewActivities = List.from(newActivities);
          _isLoadingNew = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoadingNew = false);
      rethrow;
    }
  }

  Future<void> _loadActivities({bool reset = false}) async {
    if (_isLoadingMore || !_isOnline) return;
    if (reset) {
      _currentPage = 0;
      _hasMore = true;
    }
    if (!_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final searchRequest = ActivitySearchRequestDTO(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryIds: _getSelectedCategoryId(),
        difficultyLevels: _getSelectedDifficulty(),
        minDurationSeconds: _getMinDuration(),
        maxDurationSeconds: _getMaxDuration(),
        completedOnly: _showCompletedOnly,
        popularOnly: _selectedCategory == 'popular',
        newOnly: _selectedCategory == 'new',
        page: _currentPage,
        size: _pageSize,
        sortBy: _getSortBy(),
        sortDirection: 'DESC',
      );
      final response = await _activityService.searchActivities(searchRequest);
      if (mounted) {
        setState(() {
          if (reset) {
            _activities.clear();
            _cachedActivities.clear();
          }
          _activities.addAll(response.content);
          _cachedActivities.addAll(response.content);
          _hasMore = !response.last;
          _currentPage++;
          _isLoadingMore = false;
        });
        await _preloadCoverImages(response.content);
        await _saveToCache();
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoadingMore = false;
          _hasError = true;
          _errorMessage = 'Erreur chargement: $e';
        });
    }
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasMore || !_isOnline) return;
    await _loadActivities();
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 0;
      _hasMore = true;
    });
    _loadActivities(reset: true);
  }

  List<int>? _getSelectedCategoryId() {
    if (_selectedCategory == 'all' ||
        _selectedCategory == 'popular' ||
        _selectedCategory == 'new')
      return null;
    final category = _categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => _categories.first,
    );
    return [category.id];
  }

  List<String>? _getSelectedDifficulty() {
    if (_selectedDifficulty == 'all') return null;
    return [_selectedDifficulty.toUpperCase()];
  }

  int? _getMinDuration() {
    switch (_selectedDuration) {
      case 'short':
        return 0;
      case 'medium':
        return 300;
      case 'long':
        return 900;
      default:
        return null;
    }
  }

  int? _getMaxDuration() {
    switch (_selectedDuration) {
      case 'short':
        return 299;
      case 'medium':
        return 899;
      case 'long':
        return null;
      default:
        return null;
    }
  }

  String _getSortBy() {
    if (_selectedCategory == 'popular') return 'popularity';
    if (_selectedCategory == 'new') return 'createdAt';
    return 'popularity';
  }

  void _handleError(String message) {
    debugPrint(message);
    if (mounted)
      setState(() {
        _hasError = true;
        _errorMessage = message;
        _isLoading = false;
      });
  }

  Future<void> _navigateToActivity(Activity activity) async {
    if (_startingActivities.contains(activity.id)) return;
    _startingActivities.add(activity.id);
    try {
      final request = ActivityProgressRequestDTO(
        sessionId: DateTime.now().millisecondsSinceEpoch,
        progressPercentage: 0,
        positionSeconds: 0,
        deviceId: _getDeviceId(),
        sessionMetadata: SessionMetadataDTO(
          appVersion: '1.2.3',
          osVersion: _getOsVersion(),
          networkType: _isOnline ? 'wifi' : 'none',
          batteryLevel: _getBatteryLevel(),
        ),
      );
      final updatedActivity = await _activityService.startActivity(
        activity.id,
        request,
      );
      _updateActivityInList(_activities, updatedActivity);
      _updateActivityInList(_recommendedActivities, updatedActivity);
      _updateActivityInList(_popularActivities, updatedActivity);
      _updateActivityInList(_newActivities, updatedActivity);
      _updateActivityInList(_cachedActivities, updatedActivity);
      _updateActivityInList(_cachedRecommendedActivities, updatedActivity);
      _updateActivityInList(_cachedPopularActivities, updatedActivity);
      _updateActivityInList(_cachedNewActivities, updatedActivity);
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ActivityDetailPage(activity: updatedActivity),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      await _loadInitialData(); // Refresh after return
    } catch (e) {
      _showSnackBar(
        message: 'Impossible de démarrer l’activité : ${e.toString()}',
        color: Colors.red,
        icon: Icons.error_outline,
      );
    } finally {
      _startingActivities.remove(activity.id);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadInitialData();
  }

  String _getDeviceId() =>
      'flutter_mobile_${DateTime.now().millisecondsSinceEpoch}';
  String _getOsVersion() => 'iOS 17.2';
  double _getBatteryLevel() => 0.82;

  Future<void> _toggleFavorite(Activity activity) async {
    if (!_isOnline) {
      _showSnackBar(
        message: 'Mode hors ligne - impossible de modifier les favoris',
        color: Colors.orange,
        icon: Icons.wifi_off,
      );
      return;
    }
    try {
      final updatedActivity = await _activityService.toggleFavorite(
        activity.id,
      );
      _updateActivityInList(_activities, updatedActivity);
      _updateActivityInList(_recommendedActivities, updatedActivity);
      _updateActivityInList(_popularActivities, updatedActivity);
      _updateActivityInList(_newActivities, updatedActivity);
      _updateActivityInList(_cachedActivities, updatedActivity);
      _updateActivityInList(_cachedRecommendedActivities, updatedActivity);
      _updateActivityInList(_cachedPopularActivities, updatedActivity);
      _updateActivityInList(_cachedNewActivities, updatedActivity);
      _showSnackBar(
        message: (updatedActivity.isFavorite ?? false)
            ? '❤️ Ajouté aux favoris'
            : '💔 Retiré des favoris',
        color: (updatedActivity.isFavorite ?? false)
            ? Colors.pink
            : Colors.grey.shade600,
        icon: (updatedActivity.isFavorite ?? false)
            ? Icons.favorite
            : Icons.favorite_border,
      );
      await _saveToCache();
    } catch (e) {
      _showSnackBar(
        message: 'Erreur: $e',
        color: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  void _updateActivityInList(List<Activity> list, Activity updatedActivity) {
    final index = list.indexWhere((a) => a.id == updatedActivity.id);
    if (index != -1) setState(() => list[index] = updatedActivity);
  }

  void _showSnackBar({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============ WIDGETS DE L'INTERFACE ==========
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF7DBBC3),
      elevation: 0,
      toolbarHeight: 70,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _searchFocusNode.hasFocus
            ? _buildSearchField()
            : const Text(
                'Activités',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        if (!_searchFocusNode.hasFocus) ...[
          _buildRoleBasedActionButton(),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
              onPressed: _isLoading ? null : _loadInitialData,
              tooltip: 'Actualiser',
            ),
          ),
        ],
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7DBBC3), Color(0xFF5DA8B0)],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'Rechercher une activité...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (_) => _searchFocusNode.unfocus(),
      ),
    );
  }

  Widget _buildRoleBasedActionButton() {
    final user = _authService.currentUser;
    final isAdmin = user?.isAdmin == true;
    final isContentCreator = user?.isContentCreator == true;
    if (isAdmin || isContentCreator) {
      return Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 22),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddActivityPage()),
            );
            if (result == true && mounted) await _loadInitialData();
          },
          tooltip: 'Ajouter une activité',
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFloatingActionButton() {
    final user = _authService.currentUser;
    final isAdmin = user?.isAdmin == true;
    final isContentCreator = user?.isContentCreator == true;
    if (isAdmin || isContentCreator) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddActivityPage()),
          );
          if (result == true && mounted) await _loadInitialData();
        },
        backgroundColor: const Color(0xFF7DBBC3),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ajouter',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBody() {
    if (!_isInitialized) return _buildInitializingView();
    if (_hasError) return _buildErrorView();
    if (_isLoading) return _buildLoadingView();
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: const Color(0xFF7DBBC3),
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: _contentPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                if (!_isOnline && _errorMessage != null) _buildOfflineBanner(),
                _buildSearchBar(),
                const SizedBox(height: 24),
                if (_userStats != null) ...[
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                ],
                _buildCategoriesFilter(),
                const SizedBox(height: 32),
                if (!_isLoadingRecommended &&
                    _recommendedActivities.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Recommandé pour vous',
                    subtitle: 'Basé sur vos préférences',
                    icon: Icons.auto_awesome,
                    color: const Color(0xFFF9A826),
                  ),
                  const SizedBox(height: 20),
                  _buildRecommendedSection(),
                  const SizedBox(height: 40),
                ],
                if (!_isLoadingPopular && _popularActivities.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Tendances 🔥',
                    subtitle: 'Les plus populaires du moment',
                    icon: Icons.trending_up,
                    color: const Color(0xFFE91E63),
                  ),
                  const SizedBox(height: 20),
                  _buildPopularSection(),
                  const SizedBox(height: 40),
                ],
                if (!_isLoadingNew && _newActivities.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Nouveautés ✨',
                    subtitle: 'Récemment ajoutées',
                    icon: Icons.new_releases,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 20),
                  _buildNewActivitiesSection(),
                  const SizedBox(height: 40),
                ],
                _buildAllActivitiesSection(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
          if (_isLoadingMore && _isOnline)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _buildLoadingIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode hors ligne',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  _errorMessage ?? 'Données en cache affichées',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7DBBC3).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Lottie.asset(
              'assets/lotties/loading.json',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Préparation de votre espace',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isOnline ? 'Chargement des activités...' : 'Mode hors ligne...',
            style: TextStyle(fontSize: 15, color: const Color(0xFF7F8C8D)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lotties/loading.json', width: 100, height: 100),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: const Color(0xFF7DBBC3),
            highlightColor: const Color(0xFFB2E0E6),
            child: const Text(
              'Chargement des activités...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7DBBC3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFE74C3C),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Oups ! Une erreur est survenue',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Impossible de charger les activités',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF7F8C8D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7DBBC3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 12),
                  Text(
                    'Réessayer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Rechercher une activité...',
          hintStyle: const TextStyle(color: Color(0xFF95A5A6), fontSize: 15),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF7DBBC3),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  },
                  icon: const Icon(Icons.close, color: Color(0xFF95A5A6)),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 15),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_userStats == null) return const SizedBox.shrink();
    final totalActivities = _safeParseInt(_userStats!['totalActivities']);
    final completedActivities = _safeParseInt(
      _userStats!['completedActivities'],
    );
    final currentStreak = _safeParseInt(_userStats!['currentStreak']);
    final completionRate = totalActivities > 0
        ? (completedActivities / totalActivities * 100).toInt()
        : 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7DBBC3), Color(0xFF5DA8B0)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7DBBC3).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.check_circle,
                value: '$completedActivities/$totalActivities',
                label: 'Terminées',
                color: Colors.white,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.local_fire_department,
                value: '$currentStreak',
                label: 'Streak',
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completionRate / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$completionRate%',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7DBBC3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.category,
                color: Color(0xFF7DBBC3),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Explorer par catégories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoadingCategories
              ? _buildCategoriesShimmer()
              : _buildCategoriesList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(right: index < 4 ? 12 : 0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    final allCategories = [
      _CategoryModel(
        label: 'Toutes',
        icon: Icons.explore,
        color: const Color(0xFF7DBBC3),
        value: 'all',
      ),
      _CategoryModel(
        label: 'Populaires',
        icon: Icons.trending_up,
        color: const Color(0xFFE91E63),
        value: 'popular',
      ),
      _CategoryModel(
        label: 'Nouvelles',
        icon: Icons.fiber_new,
        color: const Color(0xFF4CAF50),
        value: 'new',
      ),
      ..._categories.map(
        (category) => _CategoryModel(
          label: category.name,
          icon: category.getIcon(),
          color: category.getColor(),
          value: category.name,
        ),
      ),
    ];
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: allCategories.length,
      itemBuilder: (context, index) {
        final category = allCategories[index];
        final isSelected = _selectedCategory == category.value;
        return Container(
          margin: EdgeInsets.only(
            right: index < allCategories.length - 1 ? 10 : 0,
          ),
          child: _buildCategoryChip(
            label: category.label,
            icon: category.icon,
            color: category.color,
            isSelected: isSelected,
            onTap: () {
              setState(() => _selectedCategory = category.value);
              _applyFilters();
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: isSelected ? Colors.white : color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _showAdvancedFilters,
            icon: Icon(Icons.tune, color: const Color(0xFF7DBBC3), size: 22),
            tooltip: 'Filtres avancés',
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    if (_isLoadingRecommended) return _buildSectionShimmer();
    if (_recommendedActivities.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedActivities.length,
        itemBuilder: (context, index) {
          final activity = _recommendedActivities[index];
          return Container(
            width: _featuredCardWidth,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 16,
              right: index == _recommendedActivities.length - 1 ? 0 : 0,
            ),
            child: _buildFeaturedActivityCard(
              activity,
              type: FeaturedCardType.recommended,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularSection() {
    if (_isLoadingPopular) return _buildSectionShimmer();
    if (_popularActivities.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _popularActivities.length,
        itemBuilder: (context, index) {
          final activity = _popularActivities[index];
          return Container(
            width: _featuredCardWidth * 0.9,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 16,
              right: index == _popularActivities.length - 1 ? 0 : 0,
            ),
            child: _buildFeaturedActivityCard(
              activity,
              type: FeaturedCardType.popular,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewActivitiesSection() {
    if (_isLoadingNew) return _buildSectionShimmer();
    if (_newActivities.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _newActivities.length,
        itemBuilder: (context, index) {
          final activity = _newActivities[index];
          return Container(
            width: _featuredCardWidth * 0.9,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 16,
              right: index == _newActivities.length - 1 ? 0 : 0,
            ),
            child: _buildFeaturedActivityCard(
              activity,
              type: FeaturedCardType.newActivity,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionShimmer() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: _featuredCardWidth * 0.9,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 16,
            right: index == 2 ? 0 : 0,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Carte pour les sections mises en avant (recommandé, populaire, nouveau)
  Widget _buildFeaturedActivityCard(
    Activity activity, {
    required FeaturedCardType type,
  }) {
    final badgeConfig = _getBadgeConfig(type);
    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => _navigateToActivity(activity),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              _buildActivityImage(
                assetId: activity.coverImageAssetId,
                fallbackColor: activity.getColor(),
                fallbackIcon: activity.getIcon(),
                width: double.infinity,
                height: double.infinity,
                borderRadius: 24,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badgeConfig.color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badgeConfig.icon,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badgeConfig.label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              activity.isFavorite == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: activity.isFavorite == true
                                  ? Colors.red
                                  : Colors.white,
                            ),
                            onPressed: () => _toggleFavorite(activity),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activity.durationDisplay ??
                                  '${activity.durationSeconds}s',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.remove_red_eye,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${activity.completionCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ), // vues
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildDifficultyIndicator(
                              activity.difficultyLevel,
                              lightBackground: true,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: activity.averageRating,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 14,
                                  unratedColor: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(activity.averageRating ?? 0.0).toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  // Carte en grille
  Widget _buildActivityGridCard(Activity activity) {
    final isStarting = _startingActivities.contains(activity.id);
    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _navigateToActivity(activity),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              _buildActivityImage(
                assetId: activity.coverImageAssetId,
                fallbackColor: activity.getColor(),
                fallbackIcon: activity.getIcon(),
                width: double.infinity,
                height: double.infinity,
                borderRadius: 20,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              if (isStarting)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            activity.isFavorite == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: activity.isFavorite == true
                                ? Colors.red
                                : Colors.white,
                          ),
                          onPressed: () => _toggleFavorite(activity),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (activity.shortDescription != null)
                          Text(
                            activity.shortDescription!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
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
                                  const Icon(
                                    Icons.access_time,
                                    size: 10,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.durationDisplay ??
                                        '${activity.durationSeconds}s',
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
                                    Icons.remove_red_eye,
                                    size: 10,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${activity.completionCount}',
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
                            _buildDifficultyIndicator(
                              activity.difficultyLevel,
                              lightBackground: true,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: activity.averageRating ?? 0.0,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 10,
                                  unratedColor: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${(activity.averageRating ?? 0.0).toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  // Carte en liste
  Widget _buildActivityListCard(Activity activity) {
    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _navigateToActivity(activity),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              _buildActivityImage(
                assetId: activity.coverImageAssetId,
                fallbackColor: activity.getColor(),
                fallbackIcon: activity.getIcon(),
                width: double.infinity,
                height: double.infinity,
                borderRadius: 20,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activity.getIcon(),
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  activity.isFavorite == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 20,
                                  color: activity.isFavorite == true
                                      ? Colors.red
                                      : Colors.white,
                                ),
                                onPressed: () => _toggleFavorite(activity),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (activity.shortDescription != null)
                            Text(
                              activity.shortDescription!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      activity.durationDisplay ??
                                          '${activity.durationSeconds}s',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.remove_red_eye,
                                      size: 12,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${activity.completionCount}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: activity.averageRating ?? 0.0,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 14,
                                    unratedColor: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(activity.averageRating ?? 0.0).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(
    String? difficultyLevel, {
    bool lightBackground = false,
  }) {
    Color color;
    String label;
    IconData icon;
    switch (difficultyLevel?.toLowerCase()) {
      case 'beginner':
        color = const Color(0xFF4CAF50);
        label = 'Débutant';
        icon = Icons.sentiment_satisfied;
        break;
      case 'intermediate':
        color = const Color(0xFFF9A826);
        label = 'Intermédiaire';
        icon = Icons.sentiment_neutral;
        break;
      case 'advanced':
        color = const Color(0xFFE91E63);
        label = 'Avancé';
        icon = Icons.sentiment_very_dissatisfied;
        break;
      default:
        color = const Color(0xFF7DBBC3);
        label = 'Tous niveaux';
        icon = Icons.people;
    }
    final textColor = lightBackground ? Colors.white : color;
    final bgColor = lightBackground
        ? color.withOpacity(0.8)
        : color.withOpacity(0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DBBC3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.grid_view,
                    color: Color(0xFF7DBBC3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Toutes les activités',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C3E50),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isGridView = true),
                    icon: Icon(
                      Icons.grid_view,
                      color: _isGridView
                          ? const Color(0xFF7DBBC3)
                          : const Color(0xFFBDC3C7),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFE0E0E0),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isGridView = false),
                    icon: Icon(
                      Icons.view_list,
                      color: !_isGridView
                          ? const Color(0xFF7DBBC3)
                          : const Color(0xFFBDC3C7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildActivitiesList(),
      ],
    );
  }

  Widget _buildActivitiesList() {
    if (_activities.isEmpty && !_isLoadingMore) {
      return Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lotties/empty.json', height: 180, width: 180),
            const SizedBox(height: 24),
            const Text(
              'Aucune activité trouvée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Essayez avec d\'autres termes de recherche'
                  : 'Modifiez vos filtres pour voir plus d\'activités',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF7F8C8D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty || _selectedCategory != 'all')
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedCategory = 'all';
                    _selectedDuration = 'all';
                    _selectedDifficulty = 'all';
                    _showCompletedOnly = false;
                  });
                  _applyFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DBBC3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Réinitialiser les filtres',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      );
    }
    return _isGridView ? _buildActivitiesGrid() : _buildActivitiesListView();
  }

  Widget _buildActivitiesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: _cardAspectRatio,
      ),
      itemCount: _activities.length,
      itemBuilder: (context, index) =>
          _buildActivityGridCard(_activities[index]),
    );
  }

  Widget _buildActivitiesListView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) =>
          _buildActivityListCard(_activities[index]),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF7DBBC3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7DBBC3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersBottomSheet(),
    );
  }

  Widget _buildFiltersBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Text(
              'Filtres avancés',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Affinez votre recherche',
              style: TextStyle(fontSize: 15, color: const Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Activités terminées uniquement',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      value: _showCompletedOnly,
                      onChanged: (value) {
                        Navigator.pop(context);
                        setState(() => _showCompletedOnly = value);
                        _applyFilters();
                      },
                      activeColor: const Color(0xFF7DBBC3),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterSection(
                    title: 'Durée',
                    icon: Icons.timer,
                    options: const [
                      'Toutes',
                      'Court (<5min)',
                      'Moyen (5-15min)',
                      'Long (>15min)',
                    ],
                    selectedOption: _selectedDuration,
                    onOptionSelected: (value) =>
                        setState(() => _selectedDuration = value),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterSection(
                    title: 'Difficulté',
                    icon: Icons.analytics,
                    options: const [
                      'Toutes',
                      'Débutant',
                      'Intermédiaire',
                      'Avancé',
                    ],
                    selectedOption: _selectedDifficulty,
                    onOptionSelected: (value) =>
                        setState(() => _selectedDifficulty = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showCompletedOnly = false;
                          _selectedDuration = 'all';
                          _selectedDifficulty = 'all';
                        });
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7F8C8D),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Réinitialiser',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                        _showSnackBar(
                          message: 'Filtres appliqués',
                          color: const Color(0xFF4CAF50),
                          icon: Icons.check_circle,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7DBBC3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Appliquer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required List<String> options,
    required String selectedOption,
    required Function(String) onOptionSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF7DBBC3)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected = selectedOption == _getOptionValue(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => onOptionSelected(_getOptionValue(option)),
                selectedColor: const Color(0xFF7DBBC3),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF7DBBC3)
                      : const Color(0xFFE0E0E0),
                ),
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getOptionValue(String option) {
    if (option == 'Toutes') return 'all';
    if (option == 'Court (<5min)') return 'short';
    if (option == 'Moyen (5-15min)') return 'medium';
    if (option == 'Long (>15min)') return 'long';
    return option.toLowerCase();
  }

  _BadgeConfig _getBadgeConfig(FeaturedCardType type) {
    switch (type) {
      case FeaturedCardType.recommended:
        return _BadgeConfig(
          label: 'RECOMMANDÉ',
          icon: Icons.auto_awesome,
          color: const Color(0xFFF9A826),
        );
      case FeaturedCardType.popular:
        return _BadgeConfig(
          label: 'POPULAIRE',
          icon: Icons.trending_up,
          color: const Color(0xFFE91E63),
        );
      case FeaturedCardType.newActivity:
        return _BadgeConfig(
          label: 'NOUVEAU',
          icon: Icons.fiber_new,
          color: const Color(0xFF4CAF50),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _isInitialized
          ? _buildAppBar()
          : const PreferredSize(
              preferredSize: Size.fromHeight(70),
              child: SizedBox.shrink(),
            ),
      body: _buildBody(),
      floatingActionButton: _isInitialized
          ? _buildFloatingActionButton()
          : null,
    );
  }
}

class _CategoryModel {
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  _CategoryModel({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
  });
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color color;
  _BadgeConfig({required this.label, required this.icon, required this.color});
}

enum FeaturedCardType { recommended, popular, newActivity }
