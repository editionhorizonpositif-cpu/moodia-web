/*import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../models/challenge_category.dart';
import '../models/challenge_participation.dart';
import '../models/challenge_completion.dart';
import '../models/challenge_statistics.dart';
import '../models/challenge_completion_statistics.dart';
import '../models/challenge_request_dtos.dart';
import '../services/challenge_api_service.dart';
import '../services/auth_service.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeApiService _apiService;
  final AuthService _authService;

  // État de chargement
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _disposed = false;

  // État des défis
  List<Challenge> _challenges = [];
  List<Challenge> get challenges => _challenges;

  List<Challenge> _activeChallenges = [];
  List<Challenge> get activeChallenges => _activeChallenges;

  List<Challenge> _featuredChallenges = [];
  List<Challenge> get featuredChallenges => _featuredChallenges;

  List<Challenge> _userChallenges = [];
  List<Challenge> get userChallenges => _userChallenges;

  List<Challenge> _userActiveChallenges = [];
  List<Challenge> get userActiveChallenges => _userActiveChallenges;

  List<Challenge> _userCompletedChallenges = [];
  List<Challenge> get userCompletedChallenges => _userCompletedChallenges;

  List<ChallengeParticipation> _userParticipations = [];
  List<ChallengeParticipation> get userParticipations => _userParticipations;

  List<ChallengeCompletion> _userCompletions = [];
  List<ChallengeCompletion> get userCompletions => _userCompletions;

  List<ChallengeCategory> _categories = [];
  List<ChallengeCategory> get categories => _categories;

  List<ChallengeCategory> _activeCategories = [];
  List<ChallengeCategory> get activeCategories => _activeCategories;

  Challenge? _selectedChallenge;
  Challenge? get selectedChallenge => _selectedChallenge;

  ChallengeParticipation? _selectedParticipation;
  ChallengeParticipation? get selectedParticipation => _selectedParticipation;

  ChallengeCompletion? _selectedCompletion;
  ChallengeCompletion? get selectedCompletion => _selectedCompletion;

  // Statistiques
  ChallengeStatistics? _statistics;
  ChallengeStatistics? get statistics => _statistics;

  // Pagination
  int _currentPage = 0;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _totalElements = 0;
  int get totalElements => _totalElements;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // Messages d'erreur
  String? _error;
  String? get error => _error;

  // Clés SharedPreferences pour le cache
  static const String _challengesCacheKey = 'cached_challenges';
  static const String _activeChallengesCacheKey = 'cached_active_challenges';
  static const String _featuredChallengesCacheKey =
      'cached_featured_challenges';
  static const String _userChallengesCacheKey = 'cached_user_challenges_';
  static const String _categoriesCacheKey = 'cached_categories';
  static const String _statisticsCacheKey = 'cached_challenge_statistics';

  ChallengeProvider({
    required ChallengeApiService apiService,
    required AuthService authService,
  }) : _apiService = apiService,
       _authService = authService;

  // ==================== MÉTHODES UTILITAIRES ====================

  void _setLoading(bool value) {
    _isLoading = value;
    if (!_disposed) notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ ChallengeProvider Error: $error');
    }
    if (!_disposed) notifyListeners();
  }

  int? _getCurrentUserId() {
    return _authService.currentUser?.id;
  }

  // ==================== MÉTHODES DE CACHE ====================

  /// ✅ Sauvegarde les défis dans le cache
  Future<void> _cacheChallenges(
    List<Challenge> challenges,
    String cacheKey,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = challenges.map((c) => c.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(challengesJson));
      if (kDebugMode)
        print('✅ Défis mis en cache: $cacheKey (${challenges.length})');
    } catch (e) {
      debugPrint('❌ Erreur cache défis: $e');
    }
  }

  /// ✅ Charge les défis depuis le cache
  Future<List<Challenge>> _loadChallengesFromCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final challenges = jsonList
            .map((json) => Challenge.fromJson(json))
            .toList();
        if (kDebugMode)
          print(
            '✅ Défis chargés depuis cache: $cacheKey (${challenges.length})',
          );
        return challenges;
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement cache défis: $e');
    }
    return [];
  }

  /// ✅ Sauvegarde les catégories dans le cache
  Future<void> _cacheCategories(List<ChallengeCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await prefs.setString(_categoriesCacheKey, jsonEncode(categoriesJson));
      if (kDebugMode)
        print('✅ Catégories mises en cache: ${categories.length}');
    } catch (e) {
      debugPrint('❌ Erreur cache catégories: $e');
    }
  }

  /// ✅ Charge les catégories depuis le cache
  Future<List<ChallengeCategory>> _loadCategoriesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_categoriesCacheKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final categories = jsonList
            .map((json) => ChallengeCategory.fromJson(json))
            .toList();
        if (kDebugMode)
          print('✅ Catégories chargées depuis cache: ${categories.length}');
        return categories;
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement cache catégories: $e');
    }
    return [];
  }

  /// ✅ Sauvegarde les statistiques dans le cache
  Future<void> _cacheStatistics(ChallengeStatistics? statistics) async {
    if (statistics == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _statisticsCacheKey,
        jsonEncode(statistics.toJson()),
      );
      if (kDebugMode) print('✅ Statistiques mises en cache');
    } catch (e) {
      debugPrint('❌ Erreur cache statistiques: $e');
    }
  }

  /// ✅ Charge les statistiques depuis le cache
  Future<ChallengeStatistics?> _loadStatisticsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_statisticsCacheKey);

      if (cachedData != null) {
        final json = jsonDecode(cachedData) as Map<String, dynamic>;
        final statistics = ChallengeStatistics.fromJson(json);
        if (kDebugMode) print('✅ Statistiques chargées depuis cache');
        return statistics;
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement cache statistiques: $e');
    }
    return null;
  }

  // ✅ NOUVELLE MÉTHODE: loadCachedData()
  /// Charge toutes les données depuis le cache local
  /// Utilisé en mode hors-ligne ou quand le backend est indisponible
  Future<void> loadCachedData() async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      if (kDebugMode) print('📦 Chargement des données défis depuis cache...');

      // Charger les défis
      _challenges = await _loadChallengesFromCache(_challengesCacheKey);
      _activeChallenges = await _loadChallengesFromCache(
        _activeChallengesCacheKey,
      );
      _featuredChallenges = await _loadChallengesFromCache(
        _featuredChallengesCacheKey,
      );

      // Charger les catégories
      _categories = await _loadCategoriesFromCache();
      _activeCategories = _categories.where((c) => c.isActive).toList();

      // Charger les statistiques
      _statistics = await _loadStatisticsFromCache();

      // Charger les défis utilisateur si connecté
      final userId = _getCurrentUserId();
      if (userId != null) {
        final userCacheKey = _userChallengesCacheKey + userId.toString();
        final cachedUserChallenges = await _loadChallengesFromCache(
          userCacheKey,
        );
        _userChallenges = cachedUserChallenges;

        // Filtrer actifs et complétés
        _userActiveChallenges = _userChallenges
            .where((c) => c.isActive && c.hasJoined == true)
            .toList();
        _userCompletedChallenges = _userChallenges
            .where((c) => c.participationStatus == 'COMPLETED')
            .toList();
      }

      if (kDebugMode) {
        print('✅ Données défis chargées depuis cache:');
        print('   - Défis: ${_challenges.length}');
        print('   - Actifs: ${_activeChallenges.length}');
        print('   - Vedettes: ${_featuredChallenges.length}');
        print('   - Catégories: ${_categories.length}');
        print('   - Défis utilisateur: ${_userChallenges.length}');
      }

      if (!_disposed) notifyListeners();
    } catch (e) {
      _setError('Erreur chargement cache: $e');
      debugPrint('❌ Erreur loadCachedData: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MÉTHODES DE RAFRAÎCHISSEMENT ====================

  Future<void> refreshAllData() async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      await Future.wait([
        loadChallenges(reset: true),
        loadActiveChallenges(),
        loadFeaturedChallenges(),
        loadCategories(),
        loadStatistics(),
        _loadUserSpecificData(),
      ]);
    } catch (e) {
      _setError('Erreur lors du rafraîchissement: $e');
      // En cas d'erreur, utiliser le cache
      await loadCachedData();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadUserSpecificData() async {
    if (_disposed) return;
    final userId = _getCurrentUserId();
    if (userId != null) {
      try {
        await Future.wait([
          loadUserChallenges(userId, reset: true),
          loadUserParticipations(userId),
          loadUserCompletions(userId),
        ]);
      } catch (e) {
        debugPrint('⚠️ Erreur chargement données utilisateur: $e');
      }
    }
  }

  // ==================== MÉTHODES CHALLENGES ====================

  Future<void> loadChallenges({
    int page = 0,
    int size = 20,
    bool reset = false,
  }) async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.getAllChallenges(
        page: page,
        size: size,
      );

      if (reset || page == 0) {
        _challenges = response.content;
      } else {
        _challenges.addAll(response.content);
      }

      // Mettre en cache
      await _cacheChallenges(_challenges, _challengesCacheKey);

      _currentPage = response.page;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;
      _hasMore = !response.last;

      if (!_disposed) notifyListeners();
    } catch (e) {
      _setError('Erreur chargement défis: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreChallenges() async {
    if (_disposed || !_hasMore || _isLoading) return;
    await loadChallenges(page: _currentPage + 1);
  }

  Future<void> loadActiveChallenges({int page = 0, int size = 20}) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getActiveChallenges(
        page: page,
        size: size,
      );
      if (!_disposed) {
        _activeChallenges = response.content;
        await _cacheChallenges(_activeChallenges, _activeChallengesCacheKey);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement défis actifs: $e');
    }
  }

  Future<void> loadFeaturedChallenges({int page = 0, int size = 10}) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getFeaturedChallenges(
        page: page,
        size: size,
      );
      if (!_disposed) {
        _featuredChallenges = response.content;
        await _cacheChallenges(
          _featuredChallenges,
          _featuredChallengesCacheKey,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement défis vedette: $e');
    }
  }

  Future<void> loadChallengesByCategory(
    int categoryId, {
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.getChallengesByCategory(
        categoryId,
        page: page,
        size: size,
      );
      if (!_disposed) {
        _challenges = response.content;
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur chargement défis par catégorie: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadChallengesByDifficulty(
    String difficulty, {
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.getChallengesByDifficulty(
        difficulty,
        page: page,
        size: size,
      );
      if (!_disposed) {
        _challenges = response.content;
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur chargement défis par difficulté: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadChallengesWithAvailableSlots({
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.getChallengesWithAvailableSlots(
        page: page,
        size: size,
      );
      if (!_disposed) {
        _challenges = response.content;
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur chargement défis avec places disponibles: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchChallenges(
    String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.searchChallenges(
        keyword,
        page: page,
        size: size,
      );
      if (!_disposed) {
        _challenges = response.content;
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur recherche défis: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRecommendedChallenges() async {
    if (_disposed) return;
    final userId = _getCurrentUserId();
    if (userId == null) return;

    _setLoading(true);
    _setError(null);

    try {
      final challenges = await _apiService.getRecommendedChallenges(userId);
      // On pourrait stocker ça dans une variable dédiée
      if (!_disposed) notifyListeners();
    } catch (e) {
      _setError('Erreur chargement défis recommandés: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadChallengeById(int id) async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      final userId = _getCurrentUserId();
      if (userId != null) {
        print('🔄 Chargement défi $id pour utilisateur $userId');
        _selectedChallenge = await _apiService.getChallengeByIdWithUserStatus(
          id,
          userId,
        );
        print('✅ Défi chargé - hasJoined: ${_selectedChallenge?.hasJoined}');
        print('✅ canJoin: ${_selectedChallenge?.canJoin()}');
        print('✅ status: ${_selectedChallenge?.participationStatus}');
      } else {
        print('⚠️ Utilisateur non connecté');
        _selectedChallenge = await _apiService.getChallengeById(id);
      }
      if (!_disposed) notifyListeners();
    } catch (e) {
      _setError('Erreur chargement défi: $e');
      print('❌ Erreur loadChallengeById: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MÉTHODES UTILISATEUR ====================

  Future<void> loadUserChallenges(
    int userId, {
    int page = 0,
    int size = 20,
    bool reset = false,
  }) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getUserChallenges(
        userId,
        page: page,
        size: size,
      );

      if (reset || page == 0) {
        _userChallenges = response.content;
      } else {
        _userChallenges.addAll(response.content);
      }

      // Mettre en cache les défis utilisateur
      final userCacheKey = _userChallengesCacheKey + userId.toString();
      await _cacheChallenges(_userChallenges, userCacheKey);

      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement défis utilisateur: $e');
    }
  }

  Future<void> loadUserActiveChallenges(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getUserActiveChallenges(
        userId,
        page: page,
        size: size,
      );
      if (!_disposed) {
        _userActiveChallenges = response.content;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement défis actifs utilisateur: $e');
    }
  }

  Future<void> loadUserCompletedChallenges(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getUserCompletedChallenges(
        userId,
        page: page,
        size: size,
      );
      if (!_disposed) {
        _userCompletedChallenges = response.content;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement défis complétés utilisateur: $e');
    }
  }

  // ==================== MÉTHODES PARTICIPATION ====================

  Future<void> loadUserParticipations(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getUserParticipations(
        userId,
        page: page,
        size: size,
      );
      if (!_disposed) {
        _userParticipations = response.content;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement participations utilisateur: $e');
    }
  }

  Future<void> loadParticipationById(int participationId) async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      _selectedParticipation = await _apiService.getParticipation(
        participationId,
      );
      if (!_disposed) notifyListeners();
    } catch (e) {
      _setError('Erreur chargement participation: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadChallengeParticipations(
    int challengeId, {
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getChallengeParticipations(
        challengeId,
        page: page,
        size: size,
      );
      // On pourrait stocker ça dans une variable dédiée
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement participations défi: $e');
    }
  }

  Future<bool> joinChallenge(int challengeId, {String? notes}) async {
    if (_disposed) return false;
    final userId = _getCurrentUserId();
    if (userId == null) {
      _setError('Utilisateur non connecté');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final request = ChallengeParticipationRequest(
        userId: userId,
        notes: notes,
      );

      final challenge = await _apiService.joinChallenge(challengeId, request);

      // Mettre à jour le défi sélectionné si c'est le même
      if (_selectedChallenge?.id == challengeId) {
        _selectedChallenge = challenge;
      }

      // Rafraîchir les données utilisateur
      await _loadUserSpecificData();

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur adhésion au défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> leaveChallenge(int challengeId) async {
    if (_disposed) return false;
    final userId = _getCurrentUserId();
    if (userId == null) {
      _setError('Utilisateur non connecté');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _apiService.leaveChallenge(challengeId, userId);

      // Mettre à jour le défi sélectionné si c'est le même
      if (_selectedChallenge?.id == challengeId) {
        _selectedChallenge = await _apiService.getChallengeByIdWithUserStatus(
          challengeId,
          userId,
        );
      }

      // Rafraîchir les données utilisateur
      await _loadUserSpecificData();

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur abandon du défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProgress(
    int challengeId,
    ChallengeProgressRequest request,
  ) async {
    if (_disposed) return false;
    final userId = _getCurrentUserId();
    if (userId == null) {
      _setError('Utilisateur non connecté');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final challenge = await _apiService.updateProgress(
        challengeId,
        userId,
        request,
      );

      // Mettre à jour le défi sélectionné si c'est le même
      if (_selectedChallenge?.id == challengeId) {
        _selectedChallenge = challenge;
      }

      // Rafraîchir les données utilisateur
      await _loadUserSpecificData();

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur mise à jour progression: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeChallenge(int challengeId) async {
    if (_disposed) return false;
    final userId = _getCurrentUserId();
    if (userId == null) {
      _setError('Utilisateur non connecté');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final challenge = await _apiService.completeChallenge(
        challengeId,
        userId,
      );

      // Mettre à jour le défi sélectionné si c'est le même
      if (_selectedChallenge?.id == challengeId) {
        _selectedChallenge = challenge;
      }

      // Rafraîchir les données utilisateur
      await _loadUserSpecificData();

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur complétion du défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MÉTHODES COMPLETIONS ====================

  Future<void> loadUserCompletions(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getUserCompletions(
        userId,
        page: page,
        size: size,
      );
      if (!_disposed) {
        _userCompletions = response.content;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement complétions utilisateur: $e');
    }
  }

  Future<void> loadCompletionById(int id) async {
    if (_disposed) return;
    _setLoading(true);
    _setError(null);

    try {
      _selectedCompletion = await _apiService.getCompletionById(id);
      if (!_disposed) notifyListeners();
    } catch (e) {
      _setError('Erreur chargement complétion: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> recordCompletion(
    int challengeId,
    ChallengeCompletionRequest request,
  ) async {
    if (_disposed) return false;
    final userId = _getCurrentUserId();
    if (userId == null) {
      _setError('Utilisateur non connecté');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final completion = await _apiService.recordCompletion(
        challengeId,
        userId,
        request,
      );

      // Rafraîchir les données utilisateur
      await _loadUserSpecificData();

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur enregistrement complétion: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCompletion(
    int id,
    ChallengeCompletionRequest request,
  ) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final completion = await _apiService.updateCompletion(id, request);

      if (_selectedCompletion?.id == id) {
        _selectedCompletion = completion;
      }

      // Rafraîchir les données utilisateur
      final userId = _getCurrentUserId();
      if (userId != null) {
        await loadUserCompletions(userId);
      }

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur mise à jour complétion: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCompletion(int id) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.deleteCompletion(id);

      // Rafraîchir les données utilisateur
      final userId = _getCurrentUserId();
      if (userId != null) {
        await loadUserCompletions(userId);
      }

      if (_selectedCompletion?.id == id) {
        _selectedCompletion = null;
      }

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur suppression complétion: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> issueCertificate(int id) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final completion = await _apiService.issueCertificate(id);

      if (_selectedCompletion?.id == id) {
        _selectedCompletion = completion;
      }

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur émission certificat: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleCompletionVisibility(int id, bool isPublic) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final completion = await _apiService.toggleCompletionVisibility(
        id,
        isPublic,
      );

      if (_selectedCompletion?.id == id) {
        _selectedCompletion = completion;
      }

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur changement visibilité: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MÉTHODES CATÉGORIES ====================

  Future<void> loadCategories({int page = 0, int size = 20}) async {
    if (_disposed) return;
    try {
      final response = await _apiService.getAllCategories(
        page: page,
        size: size,
      );
      if (!_disposed) {
        _categories = response.content;
        await _cacheCategories(_categories);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement catégories: $e');
    }
  }

  Future<void> loadActiveCategories() async {
    if (_disposed) return;
    try {
      _activeCategories = await _apiService.getActiveCategories();
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement catégories actives: $e');
    }
  }

  Future<void> loadCategoriesWithActiveChallenges() async {
    if (_disposed) return;
    try {
      final categories = await _apiService.getCategoriesWithActiveChallenges();
      if (!_disposed) {
        _activeCategories = categories;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement catégories avec défis actifs: $e');
    }
  }

  // ==================== MÉTHODES STATISTIQUES ====================

  Future<void> loadStatistics() async {
    if (_disposed) return;
    try {
      _statistics = await _apiService.getChallengeStatistics();
      await _cacheStatistics(_statistics);
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement statistiques: $e');
    }
  }

  Future<ChallengeStatistics?> loadUserStatistics(int userId) async {
    if (_disposed) return null;
    try {
      return await _apiService.getUserChallengeStatistics(userId);
    } catch (e) {
      debugPrint('❌ Erreur chargement statistiques utilisateur: $e');
      return null;
    }
  }

  Future<ChallengeCompletionStatistics?> loadUserCompletionStatistics(
    int userId,
  ) async {
    if (_disposed) return null;
    try {
      return await _apiService.getUserCompletionStatistics(userId);
    } catch (e) {
      debugPrint('❌ Erreur chargement statistiques complétion utilisateur: $e');
      return null;
    }
  }

  // ==================== MÉTHODES ADMIN ====================

  Future<bool> createChallenge(CreateChallengeRequest request) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final challenge = await _apiService.createChallenge(request);

      // Ajouter le nouveau défi à la liste
      _challenges.insert(0, challenge);

      // Mettre à jour le cache
      await _cacheChallenges(_challenges, _challengesCacheKey);

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur création défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateChallenge(int id, UpdateChallengeRequest request) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final challenge = await _apiService.updateChallenge(id, request);

      // Mettre à jour le défi dans les listes
      _updateChallengeInLists(challenge);

      if (_selectedChallenge?.id == id) {
        _selectedChallenge = challenge;
      }

      // Mettre à jour le cache
      await _cacheChallenges(_challenges, _challengesCacheKey);

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur mise à jour défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteChallenge(int id) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.deleteChallenge(id);

      // Retirer le défi des listes
      _challenges.removeWhere((c) => c.id == id);
      _activeChallenges.removeWhere((c) => c.id == id);
      _featuredChallenges.removeWhere((c) => c.id == id);
      _userChallenges.removeWhere((c) => c.id == id);
      _userActiveChallenges.removeWhere((c) => c.id == id);
      _userCompletedChallenges.removeWhere((c) => c.id == id);

      // Mettre à jour le cache
      await _cacheChallenges(_challenges, _challengesCacheKey);

      if (_selectedChallenge?.id == id) {
        _selectedChallenge = null;
      }

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur suppression défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleChallengeStatus(int id, bool active) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final challenge = await _apiService.toggleChallengeStatus(id, active);

      // Mettre à jour le défi dans les listes
      _updateChallengeInLists(challenge);

      if (_selectedChallenge?.id == id) {
        _selectedChallenge = challenge;
      }

      // Mettre à jour le cache
      await _cacheChallenges(_challenges, _challengesCacheKey);

      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur changement statut défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveChallenge(int id) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final challenge = await _apiService.approveChallenge(id);
      _updateChallengeInLists(challenge);
      if (_selectedChallenge?.id == id) {
        _selectedChallenge = challenge;
      }
      await _cacheChallenges(_challenges, _challengesCacheKey);
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur approbation défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectChallenge(int id) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final challenge = await _apiService.rejectChallenge(id);
      _updateChallengeInLists(challenge);
      if (_selectedChallenge?.id == id) {
        _selectedChallenge = challenge;
      }
      await _cacheChallenges(_challenges, _challengesCacheKey);
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur rejet défi: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MÉTHODES ADMIN CATÉGORIES ====================

  Future<bool> createCategory(ChallengeCategoryRequest request) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final category = await _apiService.createCategory(request);
      _categories.add(category);
      await _cacheCategories(_categories);
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur création catégorie: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCategory(int id, ChallengeCategoryRequest request) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final category = await _apiService.updateCategory(id, request);

      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = category;
      }

      await _cacheCategories(_categories);
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur mise à jour catégorie: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCategory(int id) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      await _cacheCategories(_categories);
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur suppression catégorie: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleCategoryStatus(int id, bool active) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      final category = await _apiService.toggleCategoryStatus(id, active);

      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = category;
      }

      await _cacheCategories(_categories);
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur changement statut catégorie: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCategoryOrder(List<int> categoryIds) async {
    if (_disposed) return false;
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.updateCategoryOrder(categoryIds);

      // Mettre à jour l'ordre localement
      _categories.sort((a, b) {
        final indexA = categoryIds.indexOf(a.id);
        final indexB = categoryIds.indexOf(b.id);
        return indexA.compareTo(indexB);
      });

      await _cacheCategories(_categories);
      if (!_disposed) notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur mise à jour ordre catégories: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MÉTHODES UTILITAIRES PRIVÉES ====================

  void _updateChallengeInLists(Challenge updatedChallenge) {
    // Mettre à jour dans challenges
    final index = _challenges.indexWhere((c) => c.id == updatedChallenge.id);
    if (index != -1) {
      _challenges[index] = updatedChallenge;
    }

    // Mettre à jour dans activeChallenges
    final activeIndex = _activeChallenges.indexWhere(
      (c) => c.id == updatedChallenge.id,
    );
    if (activeIndex != -1) {
      if (updatedChallenge.isActive) {
        _activeChallenges[activeIndex] = updatedChallenge;
      } else {
        _activeChallenges.removeAt(activeIndex);
      }
    } else if (updatedChallenge.isActive) {
      _activeChallenges.add(updatedChallenge);
    }

    // Mettre à jour dans featuredChallenges
    final featuredIndex = _featuredChallenges.indexWhere(
      (c) => c.id == updatedChallenge.id,
    );
    if (featuredIndex != -1) {
      if (updatedChallenge.isFeatured) {
        _featuredChallenges[featuredIndex] = updatedChallenge;
      } else {
        _featuredChallenges.removeAt(featuredIndex);
      }
    } else if (updatedChallenge.isFeatured) {
      _featuredChallenges.add(updatedChallenge);
    }

    // Mettre à jour dans userChallenges
    final userIndex = _userChallenges.indexWhere(
      (c) => c.id == updatedChallenge.id,
    );
    if (userIndex != -1) {
      _userChallenges[userIndex] = updatedChallenge;
    }

    // Mettre à jour dans userActiveChallenges
    final userActiveIndex = _userActiveChallenges.indexWhere(
      (c) => c.id == updatedChallenge.id,
    );
    if (userActiveIndex != -1) {
      if (updatedChallenge.hasJoined == true && updatedChallenge.isActive) {
        _userActiveChallenges[userActiveIndex] = updatedChallenge;
      } else {
        _userActiveChallenges.removeAt(userActiveIndex);
      }
    } else if (updatedChallenge.hasJoined == true &&
        updatedChallenge.isActive) {
      _userActiveChallenges.add(updatedChallenge);
    }

    // Mettre à jour dans userCompletedChallenges
    final userCompletedIndex = _userCompletedChallenges.indexWhere(
      (c) => c.id == updatedChallenge.id,
    );
    if (userCompletedIndex != -1) {
      if (updatedChallenge.participationStatus == 'COMPLETED') {
        _userCompletedChallenges[userCompletedIndex] = updatedChallenge;
      } else {
        _userCompletedChallenges.removeAt(userCompletedIndex);
      }
    } else if (updatedChallenge.participationStatus == 'COMPLETED') {
      _userCompletedChallenges.add(updatedChallenge);
    }
  }

  // ==================== MÉTHODES DE NETTOYAGE ====================

  void clearSelectedChallenge() {
    _selectedChallenge = null;
    if (!_disposed) notifyListeners();
  }

  void clearSelectedParticipation() {
    _selectedParticipation = null;
    if (!_disposed) notifyListeners();
  }

  void clearSelectedCompletion() {
    _selectedCompletion = null;
    if (!_disposed) notifyListeners();
  }

  // ==================== MÉTHODE LEADERBOARD ====================

  /// Récupère le classement d'un défi
  Future<List<ChallengeParticipation>> getLeaderboard(
    int challengeId, {
    int limit = 10,
  }) async {
    try {
      return await _apiService.getLeaderboard(challengeId, limit: limit);
    } catch (e) {
      debugPrint('❌ Erreur chargement classement: $e');
      return [];
    }
  }

  // ==================== MÉTHODE PUBLIQUE POUR CHARGER LES DONNÉES UTILISATEUR ====================

  /// Charge toutes les données spécifiques à l'utilisateur connecté
  Future<void> loadUserSpecificData() async {
    if (_disposed) return;
    final userId = _getCurrentUserId();
    if (userId != null) {
      try {
        await Future.wait([
          loadUserChallenges(userId, reset: true),
          loadUserParticipations(userId),
          loadUserCompletions(userId),
          loadUserActiveChallenges(userId),
          loadUserCompletedChallenges(userId),
        ]);
      } catch (e) {
        debugPrint('⚠️ Erreur chargement données utilisateur: $e');
        _setError('Erreur chargement données utilisateur: $e');
      }
      if (!_disposed) notifyListeners();
    }
  }

  // ✅ Nettoyer tout le cache
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_challengesCacheKey);
      await prefs.remove(_activeChallengesCacheKey);
      await prefs.remove(_featuredChallengesCacheKey);
      await prefs.remove(_categoriesCacheKey);
      await prefs.remove(_statisticsCacheKey);

      final userId = _getCurrentUserId();
      if (userId != null) {
        await prefs.remove(_userChallengesCacheKey + userId.toString());
      }

      if (kDebugMode) print('✅ Cache défis nettoyé');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage cache: $e');
    }
  }

  void clearError() {
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}*/
