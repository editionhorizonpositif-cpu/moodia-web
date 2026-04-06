// lib/pages/home_page.dart - Version corrigée avec overflow fix, cache citations, drawer modifié
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Models et services
import '../models/quote.dart';
import '../models/main_message.dart';
import '../models/mood_entry_enhanced.dart';
import '../services/api_service.dart';
import '../services/main_message_service.dart';
import '../services/notification_api_service.dart';
import '../services/habit_api_service.dart';
import '../services/journal_api_service.dart';
import '../services/meditation_service.dart';
import '../services/emotion_api_service.dart';
import '../services/user_cache_service.dart';
import 'premium_numerology_profile_page.dart';
import 'activities_page.dart';
import 'habits_page.dart';
import 'meditation_list_page.dart';
import 'journal_home_page.dart';
import 'challenge_dashboard_page.dart';
import '../services/auth_service.dart';
import 'emotion_dashboard.dart';

// Imports pour les défis et abonnements
import '../providers/subscription_provider.dart';
import '../widgets/premium_badge.dart';
import '../widgets/footer_links.dart';
import '../routes/route.dart';
import '../services/notification_cache_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late Future<void> _initializationFuture;
  late AnimationController _premiumAnimationController;

  // Données
  List<Quote> _quotes = [];
  Quote? _currentQuote;
  Timer? _quoteTimer;
  Timer? _statsRefreshTimer;
  List<MainMessage> _mainMessages = [];
  MainMessage? _currentMainMessage;
  bool _isLoadingMessages = false;
  bool _isLoadingQuotes = false;
  String? _errorMessage;

  // État utilisateur
  String _fullName = "Moodien.ne";
  String _initials = "M";
  String _currentMood = "neutral";
  String? _lastMoodEmoji;
  String? _lastMoodText;
  DateTime? _lastMoodDate;

  // Notifications
  int _unreadNotifications = 0;

  // État de connexion
  bool _isOnline = true;
  String? _connectionStatus;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Couleurs du thème
  static const Color _primaryColor = Color(0xFF7DBBC3);
  static const Color _secondaryColor = Color(0xFFFFB6C1);
  static const Color _mintColor = Color(0xFFC9E4DE);
  static const Color _backgroundColor = Color(0xFFF8FCFD);
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _surfaceColor = Colors.white;
  static const Color _errorColor = Color(0xFFE57373);
  static const Color _successColor = Color(0xFF81C784);
  static const Color _warningColor = Color(0xFFFFB74D);
  static const Color _infoColor = Color(0xFF4FC3F7);
  static const Color _premiumColor = Color(0xFFFFD700);
  static const Color _offlineColor = Color(0xFFF6AD55);

  // Services
  ApiService? _apiService;
  NotificationApiService? _notificationService;
  HabitApiService? _habitService;
  JournalApiService? _journalService;
  MeditationService? _meditationService;
  EmotionApiService? _emotionService;
  AuthService? _authService;
  MainMessageService? _mainMessageService;
  UserCacheService? _userCache;

  // Flags
  bool _servicesInitialized = false;
  bool _subscriptionInitialized = false;
  bool _isLoadingPremium = false;

  int? _currentUserId;

  // Cache local
  final Map<String, dynamic> _localCache = {};

  // Carrousel
  int _currentMessageIndex = 0;
  Timer? _carouselTimer;

  // Messages par défaut (fallback)
  final List<MainMessage> _defaultMessages = [
    MainMessage(
      id: 1,
      type: 'WELCOME',
      title: 'Bienvenue sur Moodia',
      message:
          'Nous sommes ravis de vous accueillir. Explorez les modules pour améliorer votre bien-être.',
      description: 'Message de bienvenue',
      url: null,
      icon: '🎉',
      colorCode: '#7DBBC3',
      priority: 1,
      isActive: true,
      targetAudience: 'ALL',
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
      updatedBy: 'system',
    ),
    MainMessage(
      id: 2,
      type: 'TIP',
      title: 'Astuce du jour',
      message:
          'Prenez 5 minutes pour méditer chaque jour. Votre esprit vous remerciera.',
      description: 'Conseil bien-être',
      url: null,
      icon: '💡',
      colorCode: '#81C784',
      priority: 1,
      isActive: true,
      targetAudience: 'ALL',
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
      updatedBy: 'system',
    ),
    MainMessage(
      id: 3,
      type: 'MOTIVATION',
      title: 'Restez motivé',
      message: 'Chaque petit pas compte. Continuez vos efforts !',
      description: 'Message motivation',
      url: null,
      icon: '🔥',
      colorCode: '#FFB74D',
      priority: 1,
      isActive: true,
      targetAudience: 'ALL',
      startDate: null,
      endDate: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: 'system',
      updatedBy: 'system',
    ),
  ];

  // Liste des modules (inchangée)
  final List<HomeModule> _modules = [
    HomeModule(
      title: "Méditation",
      iconPath: "assets/lotties/meditation.json",
      route: const MeditationListPage(),
      color: Color(0xFF7DBBC3),
      description: "Calmez votre esprit",
      isPremium: false,
      routeName: '/meditations',
    ),
    HomeModule(
      title: "Mon Journal",
      iconPath: "assets/lotties/journal.json",
      route: const JournalHomePage(),
      color: Color(0xFFFFB6C1),
      description: "Exprimez vos pensées",
      isPremium: false,
      routeName: '/journal',
    ),
    HomeModule(
      title: "Émotions",
      iconPath: "assets/lotties/emotions.json",
      route: const EmotionDashboard(),
      color: Color(0xFFF9A826),
      description: "Analysez vos sentiments",
      isPremium: false,
      routeName: '/emotions',
    ),
    HomeModule(
      title: "Défis",
      iconPath: "assets/lotties/challenge.json",
      route: const ChallengeDashboardPage(),
      color: Color(0xFF9C27B0),
      description: "Relevez des défis bien-être",
      isPremium: false,
      routeName: AppRoutes.challenges,
    ),
    HomeModule(
      title: "Numérologie",
      iconPath: "assets/lotties/numerology.json",
      route: const PremiumNumerologyProfilePage(),
      color: Color(0xFFC9E4DE),
      description: "Découvrez votre chemin",
      isPremium: true,
      routeName: '/premium-numerology',
    ),
    HomeModule(
      title: "Activités",
      iconPath: "assets/lotties/activity.json",
      route: const ActivitiesPage(),
      color: Color(0xFFA3D4E0),
      description: "Restez actif",
      isPremium: false,
      routeName: '/activities',
    ),
    HomeModule(
      title: "Habitudes",
      iconPath: "assets/lotties/habits.json",
      route: const HabitsPage(),
      color: Color(0xFFE2C2FF),
      description: "Développez des routines",
      isPremium: false,
      routeName: '/habits',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _premiumAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializationFuture = _initializeHome();
    _initConnectivity();

    _statsRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted && _servicesInitialized && _isOnline) {
        _refreshDataIfOnline();
      }
    });
  }

  // ========== DÉTECTION DE LA CONNECTIVITÉ ==========

  Future<void> _initConnectivity() async {
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
      if (mounted) {
        setState(() {
          _isOnline = false;
          _connectionStatus = '📴 Mode hors-ligne (par défaut)';
        });
      }
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

    if (hasInternet && mounted) {
      _refreshDataIfOnline();
    }
  }

  // ========== CHARGEMENT DES DONNÉES ==========

  Future<void> _loadMainMessages() async {
    if (_mainMessageService == null || _isLoadingMessages) return;

    setState(() {
      _isLoadingMessages = true;
      _errorMessage = null;
    });

    try {
      // Appeler le service (il gère lui-même le cache)
      // forceRefresh = true uniquement si on est en ligne
      final paginated = await _mainMessageService!.getAllMessages(
        page: 0,
        size: 50,
        forceRefresh: _isOnline,
      );

      final now = DateTime.now();
      final validMessages = paginated.content.where((msg) {
        final isActive = msg.isActive == true;
        final isBeforeEnd = msg.endDate == null || now.isBefore(msg.endDate!);
        return isActive && isBeforeEnd;
      }).toList();

      if (mounted) {
        setState(() {
          _mainMessages = validMessages.isEmpty
              ? _defaultMessages
              : validMessages;
          _isLoadingMessages = false;
          _currentMainMessage = _mainMessages.first;
          _currentMessageIndex = 0;
          _startCarousel();
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement messages: $e');
      if (mounted) {
        setState(() {
          _mainMessages = _defaultMessages;
          _isLoadingMessages = false;
          _currentMainMessage = _mainMessages.first;
          _currentMessageIndex = 0;
          _startCarousel();
        });
      }
    }
  }

  void _startCarousel() {
    _stopCarousel();
    if (_mainMessages.length <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _mainMessages.isEmpty) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _mainMessages.length;
        _currentMainMessage = _mainMessages[_currentMessageIndex];
      });
    });
  }

  void _stopCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = null;
  }

  // --- Citations avec cache ---

  // Nouvelle implémentation correcte
  // --- Citations avec cache (version corrigée) ---

  Future<void> _saveQuotes(List<Quote> quotes) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> strings = [];
    for (final q in quotes) {
      // Stocker id|text|author|category (avec gestion des valeurs nulles)
      final category = q.category;
      strings.add('${q.id}|${q.text}|${q.author}|$category');
    }
    await prefs.setStringList('cached_quotes_list', strings);
    await prefs.setInt(
      'cached_quotes_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<List<Quote>> _loadQuotesFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList('cached_quotes_list');
    if (strings == null || strings.isEmpty) return [];
    final quotes = <Quote>[];
    for (final s in strings) {
      final parts = s.split('|');
      if (parts.length >= 3) {
        final id = int.tryParse(parts[0]) ?? 0;
        final text = parts[1];
        final author = parts[2];
        final category = parts.length > 3
            ? parts[3]
            : 'Générale'; // valeur par défaut
        quotes.add(
          Quote(id: id, text: text, author: author, category: category),
        );
      }
    }
    return quotes;
  }

  Future<void> _loadQuotes() async {
    if (_apiService == null || _isLoadingQuotes) return;

    // D'abord, essayer de charger depuis le cache
    final cachedQuotes = await _loadQuotesFromCache();
    if (cachedQuotes.isNotEmpty && mounted) {
      setState(() {
        _quotes = cachedQuotes;
        _isLoadingQuotes = false;
      });
      _startQuoteRotation();
    }

    if (!_isOnline) {
      // Si hors ligne, on se contente du cache
      if (mounted && _quotes.isEmpty) {
        setState(() {
          _isLoadingQuotes = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoadingQuotes = true);

    try {
      final quotes = await _apiService!.getQuotes();
      debugPrint('📚 Citations reçues : ${quotes.length}');
      // Mettre en cache
      await _saveQuotes(quotes);
      if (mounted) {
        setState(() {
          _quotes = quotes;
          _isLoadingQuotes = false;
        });
        _startQuoteRotation();
      }
    } catch (e) {
      debugPrint("❌ Erreur chargement citations: $e");
      if (mounted) setState(() => _isLoadingQuotes = false);
    }
  }

  Future<void> _loadUnreadNotifications() async {
    if (_notificationService == null) return;
    if (!_isOnline) {
      if (mounted) setState(() => _unreadNotifications = 0);
      return;
    }
    try {
      final count = await _notificationService!.getMyUnreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (e) {
      debugPrint('Erreur comptage notifications: $e');
      if (mounted) setState(() => _unreadNotifications = 0);
    }
  }

  Future<void> _loadUserData() async {
    if (_authService == null) return;

    try {
      final user = _authService!.currentUser;
      final cachedUser = await _userCache?.loadCachedUser();
      final displayUser = user ?? cachedUser;

      if (displayUser != null) {
        debugPrint(
          '✅ Utilisateur chargé: ${displayUser.fullName} (id: ${displayUser.id})',
        );
        _currentUserId = displayUser.id;
        if (mounted) {
          setState(() {
            _fullName = displayUser.fullName;
            _initials = _getInitials(displayUser.fullName);
          });
        }
        _localCache['fullName'] = displayUser.fullName;
        _localCache['initials'] = _getInitials(displayUser.fullName);
      } else {
        debugPrint('⚠️ Aucun utilisateur trouvé');
        setState(() {
          _fullName = _localCache['fullName'] ?? "Moodien.ne";
          _initials = _localCache['initials'] ?? "M";
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
      if (mounted) {
        setState(() {
          _fullName = _localCache['fullName'] ?? "Moodien.ne";
          _initials = _localCache['initials'] ?? "M";
        });
      }
    }
  }

  Future<void> _loadLastMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _currentUserId ?? _authService?.currentUser?.id;
      if (userId == null) return;

      final lastMood = prefs.getString('lastMood_$userId');
      final lastMoodEmoji = prefs.getString('lastMoodEmoji_$userId');
      final lastMoodText = prefs.getString('lastMoodText_$userId');
      final lastMoodDateStr = prefs.getString('lastMoodDate_$userId');

      if (lastMood != null && mounted) {
        setState(() {
          _currentMood = lastMood;
          _lastMoodEmoji = lastMoodEmoji;
          _lastMoodText = lastMoodText;
          if (lastMoodDateStr != null) {
            _lastMoodDate = DateTime.parse(lastMoodDateStr);
          }
        });
      }

      if (_isOnline && _emotionService != null) {
        try {
          final recentEntries = await _emotionService!.getRecentMoodEntries(7);
          if (recentEntries.isNotEmpty && mounted) {
            final latestEntry = recentEntries.first;
            await _saveMoodToPreferences(
              latestEntry.primaryEmotion,
              latestEntry.note ?? "",
              latestEntry.createdAt ?? DateTime.now(),
            );
          }
        } catch (e) {
          debugPrint('Erreur chargement dernières émotions: $e');
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement dernière humeur: $e');
    }
  }

  Future<void> _saveMoodToPreferences(
    String mood,
    String? text,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _currentUserId ?? _authService?.currentUser?.id;
    if (userId == null) return;

    await prefs.setString('lastMood_$userId', mood);
    if (text != null && text.isNotEmpty) {
      await prefs.setString('lastMoodText_$userId', text);
    }
    await prefs.setString('lastMoodDate_$userId', date.toIso8601String());

    if (mounted) {
      setState(() {
        _currentMood = mood;
        _lastMoodText = text;
        _lastMoodDate = date;
      });
    }
  }

  void _initializeProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // ✅ Vérification

      try {
        final subscriptionProvider = Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        );
        if (_isOnline) {
          subscriptionProvider.refreshSubscription().catchError((e) {
            debugPrint('Erreur refreshSubscription: $e');
            if (mounted) {
              // ✅ Vérification avant d’utiliser le contexte
              subscriptionProvider.loadCachedSubscription();
            }
          });
        } else {
          subscriptionProvider.loadCachedSubscription();
        }
      } catch (e) {
        debugPrint('Erreur accès SubscriptionProvider: $e');
      }
    });
  }

  String _getInitials(String name) {
    final parts = name.trim().split(" ");
    return parts.map((e) => e.isNotEmpty ? e[0].toUpperCase() : "").join();
  }

  void _startQuoteRotation() {
    if (_quotes.isEmpty) return;
    _changeQuote();
    _quoteTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _quotes.isNotEmpty) _changeQuote();
    });
  }

  void _changeQuote() {
    if (_quotes.isEmpty) return;
    final random = Random();
    Quote? newQuote;
    int attempts = 0;
    while (attempts < 3) {
      newQuote = _quotes[random.nextInt(_quotes.length)];
      if (newQuote.id != _currentQuote?.id) break;
      attempts++;
    }
    if (mounted) setState(() => _currentQuote = newQuote);
  }

  Future<void> _logout() async {
    // 1. Annuler TOUS les timers pour éviter des callbacks après démontage
    _statsRefreshTimer?.cancel();
    _statsRefreshTimer = null;
    _quoteTimer?.cancel();
    _quoteTimer = null;
    _carouselTimer?.cancel();
    _carouselTimer = null;

    // 2. Déconnexion via AuthService (supprime token, auth_data, etc.)
    if (_authService != null) {
      try {
        await _authService!.logout();
      } catch (e) {
        debugPrint('Erreur AuthService.logout: $e');
      }
    } else if (_apiService != null) {
      try {
        await _apiService!.logout();
      } catch (e) {
        debugPrint('Erreur ApiService.logout: $e');
      }
    }

    // 3. Vider les caches utilisateur (données personnelles)
    if (_journalService != null) {
      try {
        await _journalService!.clearCache();
      } catch (e) {
        debugPrint('Erreur journalService.clearCache: $e');
      }
    }
    if (_emotionService != null) {
      try {
        await _emotionService!.clearCache();
      } catch (e) {
        debugPrint('Erreur emotionService.clearCache: $e');
      }
    }
    if (_userCache != null) {
      try {
        await _userCache!.clearCache();
      } catch (e) {
        debugPrint('Erreur userCache.clearCache: $e');
      }
    }

    // 4. Notifications (lectures en attente)
    try {
      await NotificationCacheService.clearPendingReads();
      await NotificationCacheService.saveNotifications([]);
    } catch (e) {
      debugPrint('Erreur nettoyage notifications: $e');
    }

    // 5. Abonnement (statut premium)
    SubscriptionProvider? subscriptionProvider;
    try {
      subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
    } catch (e) {
      debugPrint('Provider.of SubscriptionProvider: $e');
    }
    if (subscriptionProvider != null) {
      try {
        await subscriptionProvider.clearCache();
      } catch (e) {
        debugPrint('Erreur subscriptionProvider.clearCache: $e');
      }
    }

    // 6. Redirection vers login (seulement si le widget est encore monté)
    if (mounted) {
      try {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      } catch (e) {
        debugPrint('Erreur navigation: $e');
      }
    }
  }

  // Gestion de la redirection des messages
  Future<void> _handleMessageTap(MainMessage message) async {
    final url = message.url;
    if (url == null || url.isEmpty) return;

    if (url.startsWith('/')) {
      if (mounted) {
        try {
          Navigator.pushNamed(context, url);
        } catch (e) {
          debugPrint('Erreur navigation interne: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lien interne non disponible')),
          );
        }
      }
    } else if (url.startsWith('http')) {
      final shouldLaunch = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('🌐 Lien externe'),
          content: Text(
            'Vous allez être redirigé vers :\n$url\n\nVoulez-vous continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ouvrir'),
            ),
          ],
        ),
      );
      if (shouldLaunch == true) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible d\'ouvrir le lien')),
          );
        }
      }
    }
  }

  String _getMoodLabel(String mood) {
    String cleanMood = mood.trim().toLowerCase();
    switch (cleanMood) {
      case 'sad':
      case 'triste':
        return 'Triste';
      case 'low':
      case 'bas':
        return 'Bas';
      case 'neutral':
      case 'neutre':
        return 'Neutre';
      case 'good':
      case 'bien':
        return 'Bien';
      case 'great':
      case 'excellent':
        return 'Excellent';
      case 'happy':
      case 'heureux':
        return 'Heureux';
      case 'angry':
      case 'en colère':
      case 'en colere':
        return 'En colère';
      case 'anxious':
      case 'anxieux':
        return 'Anxieux';
      case 'calm':
      case 'calme':
        return 'Calme';
      case 'love':
      case 'amoureux':
        return 'Amoureux';
      default:
        return mood.isNotEmpty ? mood : 'Neutre';
    }
  }

  String _getMoodEmoji(String mood) {
    final moodLower = mood.toLowerCase().trim();
    if (moodLower.contains('heureux') ||
        moodLower == 'happy' ||
        moodLower == 'joyeux')
      return '😊';
    if (moodLower.contains('triste') || moodLower == 'sad') return '😢';
    if (moodLower.contains('colère') ||
        moodLower == 'angry' ||
        moodLower == 'faché')
      return '😠';
    if (moodLower.contains('anxieux') ||
        moodLower == 'anxious' ||
        moodLower.contains('stress'))
      return '😰';
    if (moodLower.contains('calme') ||
        moodLower == 'calm' ||
        moodLower == 'relax')
      return '😌';
    if (moodLower.contains('amour') ||
        moodLower == 'love' ||
        moodLower == 'amoureux')
      return '🥰';
    if (moodLower.contains('fatigué') ||
        moodLower == 'tired' ||
        moodLower == 'fatigue')
      return '😴';
    if (moodLower.contains('bien') ||
        moodLower == 'good' ||
        moodLower == 'content')
      return '🙂';
    if (moodLower.contains('excellent') || moodLower == 'great') return '😁';
    return '😐';
  }

  void _navigateToEnhancedAddMood() {
    Navigator.pushNamed(context, '/enhanced-add-mood').then((result) {
      if (result == true && mounted) _loadLastMood();
    });
  }

  void _navigateToCopingStrategies(String emotionName) {
    Navigator.pushNamed(
      context,
      '/coping-strategies',
      arguments: {'emotionName': emotionName},
    );
  }

  void _navigateToSubscription() {
    Navigator.pushNamed(context, AppRoutes.subscription).then((_) {
      if (mounted) {
        try {
          final subscriptionProvider = Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          );
          subscriptionProvider.refreshSubscription();
        } catch (e) {
          debugPrint('Erreur refresh après abonnement: $e');
        }
      }
    });
  }

  void _navigateToNotifications() {
    Navigator.pushNamed(context, AppRoutes.notifications).then((_) {
      if (mounted && _isOnline) _loadUnreadNotifications();
    });
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile').then((_) {
      if (mounted) _loadUserData();
    });
  }

  void _navigateToModule(HomeModule module) {
    if (module.isPremium) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      if (subscriptionProvider.isPremium) {
        Navigator.pushNamed(context, module.routeName);
      } else {
        _showPremiumDialog(module.title);
      }
    } else {
      Navigator.pushNamed(context, module.routeName);
    }
  }

  void _showPremiumDialog(String moduleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('✨ Contenu Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _premiumColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: _premiumColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Le module "$moduleName" est réservé aux membres Premium.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Débloquez tous les contenus exclusifs dès maintenant !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSubscription();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _premiumColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Découvrir Premium'),
          ),
        ],
      ),
    );
  }

  void _showQuickAddMood() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: _textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "Comment vous sentez-vous?",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildQuickEmotionButton('😊', 'Heureux', 'happy'),
                  _buildQuickEmotionButton('😢', 'Triste', 'sad'),
                  _buildQuickEmotionButton('😠', 'En colère', 'angry'),
                  _buildQuickEmotionButton('😨', 'Anxieux', 'anxious'),
                  _buildQuickEmotionButton('😌', 'Calme', 'calm'),
                  _buildQuickEmotionButton('❤️', 'Amoureux', 'love'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToEnhancedAddMood();
                  },
                  icon: const Icon(Icons.insights),
                  label: const Text('Analyse émotionnelle détaillée'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEmotionButton(
    String emoji,
    String label,
    String moodValue,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _quickRecordMood(moodValue, label, emoji);
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _textColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: _textColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _quickRecordMood(String mood, String label, String emoji) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _currentUserId ?? _authService?.currentUser?.id;

      await _saveMoodToPreferences(
        label,
        "Humeur rapide: $emoji",
        DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Humeur "$label" enregistrée')),
              ],
            ),
            backgroundColor: _successColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Détails',
              textColor: Colors.white,
              onPressed: _navigateToEnhancedAddMood,
            ),
          ),
        );
      }

      if (_isOnline && userId != null && _emotionService != null) {
        final entry = MoodEntryEnhanced(
          userId: userId,
          primaryEmotion: label,
          secondaryEmotions: [],
          intensity: _mapMoodToIntensity(mood),
          physicalSensations: {'symptoms': [], 'energy': null, 'sleep': null},
          triggers: [],
          note: "Humeur rapide: $emoji",
          context: "Non spécifié",
          copingStrategiesUsed: [],
          needSupport: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _emotionService!.saveEnhancedMoodEntry(entry);
      }
    } catch (e) {
      debugPrint('Erreur enregistrement rapide humeur: $e');
    }
  }

  double _mapMoodToIntensity(String mood) {
    switch (mood) {
      case 'happy':
      case 'joyeux':
      case 'heureux':
      case 'love':
      case 'amoureux':
        return 8.0;
      case 'calm':
      case 'calme':
        return 5.0;
      case 'sad':
      case 'triste':
        return 3.0;
      case 'angry':
      case 'colère':
        return 7.0;
      case 'anxious':
      case 'anxieux':
        return 6.0;
      default:
        return 5.0;
    }
  }

  void _refreshDataIfOnline() async {
    if (!_servicesInitialized || !_isOnline || !mounted) return;

    await Future.wait([
      _loadMainMessages().catchError((e) => debugPrint('Erreur messages: $e')),
      _loadQuotes().catchError((e) => debugPrint('Erreur quotes: $e')),
      _loadUnreadNotifications().catchError(
        (e) => debugPrint('Erreur notifs: $e'),
      ),
    ]);

    if (!mounted) return; // ✅ Vérification après les appels asynchrones

    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      await subscriptionProvider.refreshSubscription();
    } catch (e) {
      debugPrint('Erreur refresh abonnement: $e');
    }
  }

  void _manualRefresh() {
    if (_isOnline) {
      _refreshDataIfOnline();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Actualisation en cours...'),
              ],
            ),
            backgroundColor: _primaryColor,
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.offline_bolt, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Mode hors-ligne : données en cache uniquement'),
              ),
            ],
          ),
          backgroundColor: _offlineColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_servicesInitialized) {
      _initializeServices();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted && _servicesInitialized && _isOnline) {
        _refreshDataIfOnline();
      }
    }
  }

  @override
  void dispose() {
    _stopCarousel();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _premiumAnimationController.dispose();
    _quoteTimer?.cancel();
    _statsRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeHome() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() {});
  }

  void _initializeServices() {
    try {
      debugPrint('Initialisation des services...');

      _apiService = Provider.of<ApiService>(context, listen: false);
      _authService = Provider.of<AuthService>(context, listen: false);
      _mainMessageService = Provider.of<MainMessageService>(
        context,
        listen: false,
      );
      _userCache = UserCacheService();

      _notificationService = NotificationApiService();
      _habitService = HabitApiService();
      _journalService = JournalApiService();
      _meditationService = MeditationService(_apiService!);
      _emotionService = EmotionApiService();

      _servicesInitialized = true;
      debugPrint('Services initialisés avec succès');

      _loadInitialData();
      _initializeProviders();
    } catch (e) {
      debugPrint('Erreur initialisation services: $e');
      setState(() => _servicesInitialized = true);
    }
  }

  Future<void> _loadInitialData() async {
    if (!_servicesInitialized) return;

    try {
      await _loadUserData();
      await _loadLastMood();

      if (_isOnline) {
        await _loadMainMessages();
        await _loadQuotes();
        await _loadUnreadNotifications();
      } else {
        await _loadCachedData();
        // Même hors ligne, on affiche les messages par défaut
        setState(() {
          _mainMessages = _defaultMessages;
          _currentMainMessage = _mainMessages.first;
          _startCarousel();
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données initiales: $e');
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final cachedUser = await _userCache?.loadCachedUser();
      if (cachedUser != null && mounted) {
        setState(() {
          _fullName = cachedUser.fullName;
          _initials = _getInitials(cachedUser.fullName);
        });
      }
      // Charger citations depuis cache
      final cachedQuotes = await _loadQuotesFromCache();
      if (cachedQuotes.isNotEmpty && mounted) {
        setState(() {
          _quotes = cachedQuotes;
          _isLoadingQuotes = false; // important
        });
        _startQuoteRotation();
      } else if (mounted) {
        // Pas de citations en cache
        setState(() {
          _isLoadingQuotes = false;
        });
      }
      if (kDebugMode) debugPrint('Données chargées depuis le cache');
    } catch (e) {
      debugPrint('Erreur chargement cache: $e');
      if (mounted) setState(() => _isLoadingQuotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (!_servicesInitialized || _isLoadingPremium) {
          return _buildLoadingScreen();
        }

        return Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, child) {
            return Scaffold(
              backgroundColor: _backgroundColor,
              appBar: _buildAppBar(isDesktop, subscriptionProvider),
              drawer: !isDesktop
                  ? _buildDrawer(context, subscriptionProvider)
                  : null,
              body: CustomScrollView(
                slivers: [
                  // Bannière premium
                  if (!subscriptionProvider.isPremium && _isOnline)
                    SliverToBoxAdapter(child: _buildPremiumBanner()),

                  // Carrousel de messages (toujours affiché)
                  SliverToBoxAdapter(child: _buildMessageCarousel()),

                  // Section de bienvenue
                  SliverToBoxAdapter(child: _buildWelcomeSection()),

                  // Actions rapides
                  SliverToBoxAdapter(child: _buildQuickActionsSection()),

                  // Grille des modules (convertie en SliverToBoxAdapter pour éviter l'overflow)
                  SliverToBoxAdapter(
                    child: _buildModulesGrid(
                      isDesktop,
                      isTablet,
                      subscriptionProvider.isPremium,
                    ),
                  ),

                  // Citations
                  // Citations (affiché même hors ligne si des citations sont disponibles)
                  if (_currentQuote != null || _isLoadingQuotes)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildQuoteSection(),
                      ),
                    ),

                  SliverToBoxAdapter(child: FooterLinksCompact()),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _showQuickAddMood,
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_comment),
                label: const Text('Ajouter une humeur'),
                elevation: 4,
              ),
              bottomNavigationBar: !isDesktop
                  ? _buildBottomNavigationBar(subscriptionProvider)
                  : null,
            );
          },
        );
      },
    );
  }

  // Nouvelle méthode pour la grille des modules (pour éviter l'overflow)
  Widget _buildModulesGrid(bool isDesktop, bool isTablet, bool isPremium) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 4 : (isTablet ? 3 : 2),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: _modules.length,
        itemBuilder: (context, index) =>
            _buildModuleCard(_modules[index], index, isPremium),
      ),
    );
  }

  // ========== WIDGETS DE CONSTRUCTION ==========

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                ),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(25),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chargement de votre espace bien-être...',
              style: TextStyle(fontSize: 16, color: _textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _premiumColor.withOpacity(0.2),
            _premiumColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _premiumColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: _premiumColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✨ Débloquez le Premium',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Accédez à tous les contenus exclusifs et outils avancés',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _navigateToSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _premiumColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: const Text('Découvrir'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AnimatedBuilder(
            animation: _premiumAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + _premiumAnimationController.value * 0.1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _premiumColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _premiumColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCarousel() {
    if (_mainMessages.isEmpty) return const SizedBox.shrink();
    final message = _currentMainMessage ?? _mainMessages.first;

    Color messageColor;
    IconData messageIcon;
    switch (message.type.toUpperCase()) {
      case 'WELCOME':
        messageColor = _primaryColor;
        messageIcon = Icons.waving_hand;
        break;
      case 'TIP':
        messageColor = _successColor;
        messageIcon = Icons.lightbulb;
        break;
      case 'MOTIVATION':
        messageColor = _warningColor;
        messageIcon = Icons.bolt;
        break;
      case 'ANNOUNCEMENT':
        messageColor = Colors.purple;
        messageIcon = Icons.announcement;
        break;
      default:
        messageColor = _secondaryColor;
        messageIcon = Icons.message;
    }

    final hasUrl = message.url != null && message.url!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasUrl ? () => _handleMessageTap(message) : null,
          borderRadius: BorderRadius.circular(24),
          splashColor: messageColor.withOpacity(0.3),
          highlightColor: messageColor.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  messageColor.withOpacity(0.05),
                  messageColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: messageColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: messageColor.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: messageColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(messageIcon, color: messageColor, size: 28),
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
                                  message.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _textColor,
                                  ),
                                ),
                              ),
                              if (hasUrl) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.open_in_new,
                                  size: 18,
                                  color: messageColor,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: _textColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_mainMessages.length > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_mainMessages.length, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _currentMessageIndex
                              ? messageColor
                              : messageColor.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor.withOpacity(0.05), _backgroundColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bonjour $_fullName,",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "comment vous sentez-vous aujourd'hui?",
                  style: TextStyle(
                    fontSize: 16,
                    color: _textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                if (_lastMoodDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Dernière humeur: ${_getMoodLabel(_currentMood)} (${_formatDate(_lastMoodDate!)})",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (_lastMoodText != null && _lastMoodText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.format_quote,
                          size: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastMoodText!,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: _textColor.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          _buildCurrentMoodDisplay(),
        ],
      ),
    );
  }

  Widget _buildCurrentMoodDisplay() {
    return GestureDetector(
      onTap: _showQuickAddMood,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: _primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _lastMoodEmoji ?? _getMoodEmoji(_currentMood),
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              _getMoodLabel(_currentMood),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (_lastMoodDate != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(_lastMoodDate!),
                style: TextStyle(
                  fontSize: 12,
                  color: _textColor.withOpacity(0.5),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Cliquez pour modifier',
              style: TextStyle(
                fontSize: 12,
                color: _textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Actions rapides",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (_isOnline)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/emotions'),
                  child: Row(
                    children: [
                      Text('Voir plus', style: TextStyle(color: _primaryColor)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16, color: _primaryColor),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionCard(
                  'Analyse émotionnelle',
                  'Comprendre vos émotions',
                  Icons.insights,
                  _primaryColor,
                  _navigateToEnhancedAddMood,
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  'Stratégies d\'adaptation',
                  'Gérer les émotions difficiles',
                  Icons.psychology,
                  _secondaryColor,
                  () => _navigateToCopingStrategies('Anxiété'),
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  'Statistiques',
                  'Votre évolution',
                  Icons.timeline,
                  _mintColor,
                  () => Navigator.pushNamed(context, '/emotions'),
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  'Méditation rapide',
                  '5 min de relaxation',
                  Icons.self_improvement,
                  const Color(0xFF9C27B0),
                  () => Navigator.pushNamed(context, '/meditations'),
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  'Nouveau défi',
                  'Relever un défi',
                  Icons.emoji_events,
                  Colors.purple,
                  () => Navigator.pushNamed(context, AppRoutes.challenges),
                ),
                const SizedBox(width: 12),
                _buildQuickActionCard(
                  'Devenir Premium',
                  'Accès illimité',
                  Icons.workspace_premium,
                  _premiumColor,
                  _navigateToSubscription,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: _textColor.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(HomeModule module, int index, bool isPremium) {
    final isModulePremium = module.isPremium;
    final canAccess = !isModulePremium || (isModulePremium && isPremium);

    return InkWell(
      onTap: () => _navigateToModule(module),
      borderRadius: BorderRadius.circular(20),
      splashColor: module.color.withOpacity(0.2),
      highlightColor: module.color.withOpacity(0.1),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    module.color.withOpacity(0.1),
                    module.color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      module.iconPath,
                      height: 60,
                      width: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _getModuleIcon(module.title),
                        size: 60,
                        color: module.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textColor.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (isModulePremium)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _premiumColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _premiumColor.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!canAccess)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: _premiumColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteSection() {
    if (_isLoadingQuotes) {
      return _buildLoadingCard('Chargement des citations...');
    }
    if (_currentQuote == null) {
      return _buildEmptyCard(
        'Pas de citations disponibles',
        Icons.format_quote,
      );
    }
    return _buildQuoteCard(_currentQuote!);
  }

  Widget _buildLoadingCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_backgroundColor, _surfaceColor],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircularProgressIndicator(color: _primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _textColor.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: _textColor.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.withOpacity(0.05),
              _mintColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_quote, size: 40, color: _primaryColor),
            const SizedBox(height: 8),
            Text(
              "\"${quote.text}\"",
              style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "- ${quote.author}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    bool isDesktop,
    SubscriptionProvider subscriptionProvider,
  ) {
    Color statusColor = _isOnline ? _successColor : _offlineColor;
    IconData statusIcon = _isOnline ? Icons.wifi : Icons.offline_bolt;
    String statusText = _isOnline ? 'En ligne' : 'Hors ligne';

    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 2,
      title: Row(
        children: [
          Image.asset(
            'assets/images/moodia_logo.png',
            height: 50,
            width: 50,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 50,
                width: 50,
                color: _primaryColor,
                child: const Center(
                  child: Text('M', style: TextStyle(color: Colors.white)),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Moodia',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (subscriptionProvider.isPremium) ...[
            const SizedBox(width: 8),
            const PremiumBadge(size: 20),
          ],
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDesktop) ...[
          ..._modules
              .take(4)
              .map(
                (module) => TextButton(
                  onPressed: () => _navigateToModule(module),
                  child: Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                    ),
                  ),
                ),
              ),
          const SizedBox(width: 20),
        ],
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: _manualRefresh,
          tooltip: 'Actualiser',
        ),

        Stack(
          children: [
            IconButton(
              icon: const Icon(Iconsax.notification),
              onPressed: _navigateToNotifications,
              tooltip: 'Notifications',
            ),
            if (_unreadNotifications > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    _unreadNotifications > 9
                        ? '9+'
                        : _unreadNotifications.toString(),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: CircleAvatar(
            backgroundColor: _primaryColor.withOpacity(0.1),
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
          onPressed: _navigateToProfile,
        ),
        if (isDesktop)
          IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
      ],
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    SubscriptionProvider subscriptionProvider,
  ) {
    return Drawer(
      backgroundColor: _surfaceColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    _initials,
                    style: const TextStyle(fontSize: 24, color: _primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isOnline
                      ? "Soyez fier de votre progression"
                      : "Mode hors-ligne",
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          if (!subscriptionProvider.isPremium && _isOnline)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _navigateToSubscription,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _premiumColor.withOpacity(0.2),
                        _premiumColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _premiumColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _premiumColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Débloquez tous les contenus',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: _premiumColor),
                    ],
                  ),
                ),
              ),
            ),
          // Modules filtrés : on retire Défis et Numérologie
          ..._modules
              .where(
                (module) =>
                    module.title != "Défis" && module.title != "Numérologie",
              )
              .map(
                (module) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: module.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getModuleIcon(module.title),
                      color: module.color,
                    ),
                  ),
                  title: Text(
                    module.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    module.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textColor.withOpacity(0.6),
                    ),
                  ),
                  trailing: module.isPremium && !subscriptionProvider.isPremium
                      ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToModule(module);
                  },
                ),
              ),
          const Divider(),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.logout, color: Colors.red),
            ),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(SubscriptionProvider subscriptionProvider) {
    return BottomAppBar(
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      color: _surfaceColor,
      height: 70,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Iconsax.home, "Accueil", isActive: true),
            _buildBottomNavItem(Iconsax.book, "Journal"),
            const SizedBox(width: 40),
            _buildBottomNavItem(Iconsax.notification, "Notif."),
            _buildBottomNavItem(
              subscriptionProvider.isPremium
                  ? Icons.workspace_premium
                  : Iconsax.profile_circle,
              subscriptionProvider.isPremium ? "Premium" : "Profil",
              isPremium: subscriptionProvider.isPremium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label, {
    bool isActive = false,
    bool isPremium = false,
  }) {
    VoidCallback? onTap;
    Color color = isActive ? _primaryColor : _textColor.withOpacity(0.5);
    if (isPremium) color = _premiumColor;

    switch (label) {
      case "Notif.":
        onTap = _navigateToNotifications;
        break;
      case "Premium":
        onTap = _navigateToSubscription;
        break;
      case "Profil":
        onTap = _navigateToProfile;
        break;
      case "Journal":
        onTap = () => Navigator.pushNamed(context, '/journal');
        break;
      default:
        onTap = () {};
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(icon, color: color, size: 24),
              if (label == "Notif." && _unreadNotifications > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadNotifications > 9
                          ? '9+'
                          : _unreadNotifications.toString(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModuleIcon(String title) {
    switch (title) {
      case "Méditation":
        return Icons.self_improvement;
      case "Mon Journal":
        return Iconsax.book;
      case "Émotions":
        return Iconsax.emoji_happy;
      case "Défis":
        return Icons.emoji_events;
      case "Numérologie":
        return Iconsax.calculator;
      case "Activités":
        return Iconsax.activity;
      case "Habitudes":
        return Iconsax.timer;
      default:
        return Iconsax.category;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inSeconds < 60) return "À l'instant";
    if (difference.inMinutes < 60) return "Il y a ${difference.inMinutes} min";
    if (difference.inHours < 24) return "Il y a ${difference.inHours} h";
    if (difference.inDays == 1) return "Hier";
    if (difference.inDays < 7) return "Il y a ${difference.inDays} j";
    return DateFormat('dd/MM/yy').format(date);
  }
}

class HomeModule {
  final String title;
  final String iconPath;
  final Widget route;
  final Color color;
  final String description;
  final bool isPremium;
  final String routeName;

  HomeModule({
    required this.title,
    required this.iconPath,
    required this.route,
    required this.color,
    required this.description,
    this.isPremium = false,
    required this.routeName,
  });
}
