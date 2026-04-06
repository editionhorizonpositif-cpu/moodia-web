// route.dart - Version complète avec toutes les routes
import 'package:flutter/material.dart';
import 'package:moodia/pages/notifications_page.dart';
import 'package:moodia/pages/subscription_plan_page.dart';

// Pages d'authentification
import '../pages/splash_page.dart';
import '../pages/login_page.dart';
import '../pages/signup_page.dart';
import '../pages/home_page.dart';
import '../pages/verification_email_page.dart';

// Pages challenges
import '../pages/challenge_dashboard_page.dart';
import '../pages/challenge_search_page.dart';
import '../pages/challenge_detail_page.dart';
import '../pages/challenge_join_page.dart';
import '../pages/challenge_progress_page.dart';
import '../pages/challenge_completion_page.dart';
import '../pages/challenge_leaderboard_page.dart';

// Pages utilisateur challenges
import '../pages/user_challenges_page.dart';
//import '../pages/user_challenge_history_page.dart';

// Pages admin challenges
/*import '../pages/admin_challenge_list_page.dart';
import '../pages/add_challenge_page.dart';*/

// Pages journal, habitudes, méditations, émotions
import '../pages/journal_home_page.dart';
import '../pages/habits_page.dart';
import '../pages/meditation_list_page.dart';
import '../pages/emotion_dashboard.dart';

// Pages premium et profil
import '../pages/premium_numerology_profile_page.dart';
import '../pages/activities_page.dart';
import '../pages/profile_page.dart';

// Pages émotions avancées
import '../pages/enhanced_add_mood_page.dart';
import '../pages/coping_strategies_page.dart';

import '../pages/forgot_password_page.dart';
import '../pages/reset_password_page.dart';

// ⭐ NOUVELLES PAGES FOOTER
import '../pages/help_page.dart';
import '../pages/privacy_page.dart';
import '../pages/terms_page.dart';
import '../pages/unsubscribe_page.dart';
import '../pages/preferences_page.dart';

class AppRoutes {
  // Routes d'authentification
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  // Routes challenges
  static const String challenges = '/challenges';
  static const String challengeSearch = '/challenges/search';
  static const String challengeDetail = '/challenges/:id';
  static const String challengeJoin = '/challenges/join/:id';
  static const String challengeProgress = '/challenges/progress/:id';
  static const String challengeCompletion = '/challenges/completion/:id';
  static const String challengeLeaderboard = '/challenges/leaderboard/:id';
  static const String notifications = '/notifications';

  // Routes utilisateur challenges
  static const String userChallenges = '/user/challenges';
  static const String userChallengeHistory = '/user/challenges/history';

  // Routes admin challenges
  static const String adminChallenges = '/admin/challenges';
  static const String addChallenge = '/admin/challenges/add';

  // Routes premium
  static const String subscription = '/subscription';

  // ⭐ NOUVELLES ROUTES AJOUTÉES ⭐
  static const String journal = '/journal';
  static const String habits = '/habits';
  static const String meditations = '/meditations';
  static const String emotions = '/emotions';
  static const String premiumNumerology = '/premium-numerology';
  static const String activities = '/activities';
  static const String profile = '/profile';
  static const String enhancedAddMood = '/enhanced-add-mood';
  static const String copingStrategies = '/coping-strategies';

  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  // ⭐ NOUVELLES ROUTES FOOTER
  static const String help = '/help';
  static const String contact = '/contact';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  static const String unsubscribe = '/unsubscribe';
  static const String preferences = '/preferences';

  // ⭐ GÉNÉRATION DE ROUTES POUR NAVIGATOR 2.0 ⭐
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Gestion des arguments
    final args = settings.arguments;

    // Extraire l'ID des routes avec paramètres
    final String? routeName = settings.name;

    // Gestion spéciale pour les routes avec paramètres (format: /challenges/123)
    if (routeName != null && routeName.startsWith('/challenges/')) {
      final parts = routeName.split('/');
      if (parts.length >= 3) {
        final id = int.tryParse(parts[2]);
        if (id != null) {
          return MaterialPageRoute(
            builder: (_) => ChallengeDetailPage(challengeId: id),
            settings: settings,
          );
        }
      }
    }

    switch (settings.name) {
      // Routes d'authentification
      case splash:
        return MaterialPageRoute(builder: (_) => const MoodiaSplashPage());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case register:
        return MaterialPageRoute(builder: (_) => const SignupPage());

      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      // ⭐ NOUVELLES ROUTES
      case journal:
        return MaterialPageRoute(builder: (_) => const JournalHomePage());

      case habits:
        return MaterialPageRoute(builder: (_) => const HabitsPage());

      case meditations:
        return MaterialPageRoute(builder: (_) => const MeditationListPage());

      case emotions:
        return MaterialPageRoute(builder: (_) => const EmotionDashboard());

      case premiumNumerology:
        return MaterialPageRoute(
          builder: (_) => const PremiumNumerologyProfilePage(),
        );

      case activities:
        return MaterialPageRoute(builder: (_) => const ActivitiesPage());

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfessionalProfilePage(),
        );

      case enhancedAddMood:
        return MaterialPageRoute(builder: (_) => const EnhancedAddMoodPage());

      case copingStrategies:
        if (args is Map<String, dynamic>) {
          final emotionName = args['emotionName'] as String? ?? 'Joie';
          return MaterialPageRoute(
            builder: (_) => CopingStrategiesPage(emotionName: emotionName),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const CopingStrategiesPage(emotionName: 'Joie'),
        );

      // Routes premium
      case subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionPlanPage());

      // Routes challenges
      case challenges:
        return MaterialPageRoute(
          builder: (_) => const ChallengeDashboardPage(),
        );

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());

      case challengeSearch:
        return MaterialPageRoute(builder: (_) => const ChallengeSearchPage());

      case challengeDetail:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ChallengeDetailPage(challengeId: args),
          );
        }
        return _errorRoute('ID du défi manquant ou invalide');

      case challengeJoin:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ChallengeJoinPage(challengeId: args),
          );
        }
        return _errorRoute('ID du défi manquant ou invalide');

      case challengeProgress:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ChallengeProgressPage(challengeId: args),
          );
        }
        return _errorRoute('ID du défi manquant ou invalide');

      case challengeCompletion:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ChallengeCompletionPage(challengeId: args),
          );
        }
        return _errorRoute('ID du défi manquant ou invalide');

      case challengeLeaderboard:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ChallengeLeaderboardPage(challengeId: args),
          );
        }
        return _errorRoute('ID du défi manquant ou invalide');

      // Routes utilisateur challenges
      case userChallenges:
        return MaterialPageRoute(builder: (_) => const UserChallengesPage());

      /*case userChallengeHistory:
        return MaterialPageRoute(
          builder: (_) => const UserChallengeHistoryPage(),
        );

      // Routes admin challenges
      case adminChallenges:
        return MaterialPageRoute(
          builder: (_) => const AdminChallengeListPage(),
        );

      case addChallenge:
        return MaterialPageRoute(builder: (_) => const AddChallengePage());*/

      // Dans generateRoute, ajoutez les cas :
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      case resetPassword:
        // Si on veut passer un token en argument (optionnel)
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => ResetPasswordPage(token: args),
          );
        }
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage());

      case verifyEmail:
        return MaterialPageRoute(builder: (_) => VerifyEmailPage());
      // ⭐ NOUVELLES PAGES FOOTER
      case help:
        return MaterialPageRoute(builder: (_) => const HelpPage());
      case contact:
        return MaterialPageRoute(builder: (_) => const HelpPage());
      case privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyPage());
      case terms:
        return MaterialPageRoute(builder: (_) => const TermsPage());
      case unsubscribe:
        return MaterialPageRoute(builder: (_) => const UnsubscribePage());
      case preferences:
        return MaterialPageRoute(builder: (_) => const PreferencesPage());

      default:
        return _errorRoute('Page non trouvée: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur de navigation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigation avec Navigator 2.0
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (Route<dynamic> route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DBBC3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
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
