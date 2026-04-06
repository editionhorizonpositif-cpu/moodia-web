import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:moodia/services/notification_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moodia/services/activity_api_service.dart';
import 'package:moodia/services/habit_api_service.dart';
import 'package:moodia/services/journal_api_service.dart';
import 'package:moodia/services/notification_api_service.dart';
import 'package:moodia/services/numerology_api_service.dart';
import 'package:provider/provider.dart';

import 'routes/route.dart';
import 'services/audio_manager.dart';
import 'services/playback_manager.dart';
import 'services/video_manager.dart';
import 'services/auth_service.dart';
import 'services/completion_service.dart';
import 'services/main_message_service.dart';
import 'services/api_service.dart';
import 'services/user_service.dart';
import 'services/analytics_service.dart';
import 'services/emotion_api_service.dart';
import 'services/media_service.dart';
import 'services/meditation_service.dart';
import 'widgets/mini_player_widget.dart';
import 'providers/subscription_provider.dart';
import 'services/user_cache_service.dart';
import 'services/media_cache_service.dart';
import 'services/cache_manager.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/enhanced_add_mood_page.dart';
import 'pages/emotion_dashboard.dart';
import 'pages/coping_strategies_page.dart';
import 'pages/splash_page.dart';

// ⭐ Import du service de nettoyage de session
import 'services/session_cleanup_service.dart';

// ⭐ Clé globale pour la navigation (utilisée pour rediriger après expiration)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await _configureSystem();
  await _initializeCaches();

  // ⭐ Configuration du callback global pour l'expiration de session
  ApiService.onSessionExpired = () {
    // Le nettoyage complet et la redirection se font via le service dédié
    SessionCleanupService.cleanupAndRedirect(navigatorKey);
  };
  ApiService.navigatorKey = navigatorKey;

  runApp(const MoodiaApp());
}

Future<void> _configureSystem() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

Future<void> _initializeCaches() async {
  if (kDebugMode) print('🔄 Initialisation des caches...');
  try {
    await SharedPreferences.getInstance();
    final userCache = UserCacheService();
    final mediaCache = MediaCacheService();
    if (kDebugMode) print('✅ Caches initialisés avec succès');
  } catch (e) {
    if (kDebugMode) print('❌ Erreur initialisation caches: $e');
  }
}

class MoodiaApp extends StatefulWidget {
  const MoodiaApp({super.key});

  @override
  State<MoodiaApp> createState() => _MoodiaAppState();
}

class _MoodiaAppState extends State<MoodiaApp> with WidgetsBindingObserver {
  late Future<Services> _servicesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _servicesFuture = _initializeServices();
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Services>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error);
        }

        final services = snapshot.data!;

        return MultiProvider(
          providers: [
            // ===== NIVEAU 1: SERVICES DE BASE (aucune dépendance) =====
            Provider<UserCacheService>.value(value: UserCacheService()),
            Provider<MediaCacheService>.value(value: MediaCacheService()),
            Provider<NotificationCacheService>.value(
              value: NotificationCacheService(),
            ),

            Provider<ApiService>.value(value: services.apiService),

            ChangeNotifierProvider<AuthService>.value(
              value: services.authService,
            ),

            // ===== NIVEAU 2: SERVICES API =====
            Provider<EmotionApiService>(
              create: (_) => EmotionApiService(),
              lazy: true,
            ),
            Provider<JournalApiService>(
              create: (_) => JournalApiService(),
              lazy: true,
            ),
            Provider<HabitApiService>(
              create: (_) => HabitApiService(),
              lazy: true,
            ),
            Provider<NotificationApiService>(
              create: (_) => NotificationApiService(),
              lazy: true,
            ),
            Provider<NumerologyApiService>(
              create: (context) =>
                  NumerologyApiService(context.read<ApiService>()),
              lazy: true,
            ),
            Provider<ActivityApiService>(
              create: (_) => ActivityApiService(),
              lazy: true,
            ),

            // ===== NIVEAU 3: SERVICES MÉDIAS =====
            Provider<MediaService>(
              create: (context) => MediaService(context.read<ApiService>()),
              lazy: true,
            ),
            Provider<MeditationService>(
              create: (context) =>
                  MeditationService(context.read<ApiService>()),
              lazy: true,
            ),

            // ===== NIVEAU 4: SERVICES COMPOSÉS =====
            Provider<MainMessageService>(
              create: (context) =>
                  MainMessageService(context.read<ApiService>()),
              lazy: true,
            ),
            Provider<CompletionService>(
              create: (context) => CompletionService(
                meditationService: context.read<MeditationService>(),
              ),
              lazy: true,
            ),
            Provider<AnalyticsService>(
              create: (_) => AnalyticsService(),
              lazy: true,
            ),

            // ===== NIVEAU 5: USER SERVICE =====
            ChangeNotifierProxyProvider<AuthService, UserService>(
              create: (context) => UserService(context.read<AuthService>()),
              update: (context, authService, userService) {
                return userService ?? UserService(authService);
              },
            ),

            // ===== NIVEAU 6: MANAGERS AUDIO/VIDEO =====
            ChangeNotifierProvider<PlaybackManager>(
              create: (_) => PlaybackManager(),
              lazy: false,
            ),
            ChangeNotifierProvider<AudioManager>(
              create: (_) => AudioManager(),
              lazy: false,
            ),
            ChangeNotifierProvider<VideoManager>(
              create: (_) => VideoManager(),
              lazy: true,
            ),

            // ===== NIVEAU 7: PROVIDERS MÉTIER =====
            ChangeNotifierProvider<SubscriptionProvider>(
              create: (context) => SubscriptionProvider(
                apiService: context.read<ApiService>(),
                authService: context.read<AuthService>(),
              ),
              lazy: false,
            ),
            // ===== ENFIN: CACHE MANAGER =====
            Provider<CacheManager>(
              create: (context) => CacheManager(
                userCache: context.read<UserCacheService>(),
                notificationApi: context.read<NotificationApiService>(),
                meditationService: context.read<MeditationService>(),
                journalApi: context.read<JournalApiService>(),
                emotionApi: context.read<EmotionApiService>(),
                completionService: context.read<CompletionService>(),
              ),
              lazy: false,
            ),
          ],
          child: const _MaterialAppWithTheme(),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF7DBBC3),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(75),
                ),
                child: const Icon(
                  Icons.self_improvement,
                  size: 80,
                  color: Color(0xFF7DBBC3),
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Initialisation...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object? error) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontFamily: 'OpenSans'),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _servicesFuture = _initializeServices()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DBBC3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Services {
  final ApiService apiService;
  final AuthService authService;
  Services({required this.apiService, required this.authService});
}

Future<Services> _initializeServices() async {
  final apiService = ApiService();

  if (kDebugMode) {
    print('🔍 Test connexion backend...');
    try {
      final testUrl = Uri.parse('http://127.0.0.1:8080/actuator/health');
      final response = await http
          .get(testUrl)
          .timeout(const Duration(seconds: 5));
      print('✅ Backend accessible: ${response.statusCode}');
    } catch (e) {
      print('❌ Backend NON accessible: $e');
      print('⚠️ Mode hors-ligne activé');
    }
  }

  await apiService.initialize();
  final authService = await AuthService.create(apiService);
  await authService.initialize();

  return Services(apiService: apiService, authService: authService);
}

// ⭐ Widget de l'application avec thème et navigation
class _MaterialAppWithTheme extends StatelessWidget {
  const _MaterialAppWithTheme();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ⭐ Clé pour la navigation globale
      title: 'Moodia',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const MoodiaSplashPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.home: (_) => const HomePage(),
      },
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (_shouldShowMiniPlayer(context))
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: MiniPlayerWidget(),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowMiniPlayer(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return false;

    final excludedRoutes = {
      '/',
      AppRoutes.splash,
      AppRoutes.login,
      '/register',
      '/onboarding',
      AppRoutes.verifyEmail,
      '/forgot-password',
    };

    return !excludedRoutes.contains(route.settings.name);
  }
}
