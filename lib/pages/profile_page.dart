// lib/pages/profile_page.dart - Version simplifiée online/offline

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

// Services et Modèles
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/user_cache_service.dart';
import '../services/notification_cache_service.dart';
import '../services/journal_api_service.dart';
import '../services/emotion_api_service.dart';
import '../providers/subscription_provider.dart';
import '../models/user.dart';
import 'login_page.dart';
import 'subscription_plan_page.dart';
import 'settings_page.dart';
import 'home_page.dart';
import '../widgets/footer_links.dart';

class ProfessionalProfilePage extends StatefulWidget {
  const ProfessionalProfilePage({super.key});

  @override
  State<ProfessionalProfilePage> createState() =>
      _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends State<ProfessionalProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideUpAnimation;

  User? _currentUser;
  bool _isLoading = true;
  bool _isRefreshing = false;

  // État de connexion simplifié : en ligne ou hors ligne
  bool _isOnline = true;
  String? _connectionStatus;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _biometricEnabled = false;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Français';
  String _selectedRegion = 'France';

  // Animations de vibrations
  double _avatarScale = 1.0;
  double _statsRotation = 0.0;

  // Colors
  static const Color _primaryColor = Color(0xFF7DBBC3);
  static const Color _warningColor = Color(0xFFF6AD55);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFE74C3C);
  static const Color _offlineColor = Color(0xFFF6AD55);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _slideUpAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  // ========== DÉTECTION SIMPLIFIÉE DE LA CONNECTIVITÉ ==========

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
          _connectionStatus = '📴 Hors ligne (par défaut)';
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
  }

  String _getStatusMessage() {
    return _isOnline ? '📶 En ligne' : '📴 Hors ligne';
  }

  Color _getStatusColor() {
    return _isOnline ? _successColor : _offlineColor;
  }

  IconData _getStatusIcon() {
    return _isOnline ? Icons.wifi : Icons.offline_bolt;
  }

  // ========== CHARGEMENT DES DONNÉES ==========

  Future<void> _initializeApp() async {
    await _loadUserData();
    await _loadPreferences();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animationController.forward();
    });
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCache = UserCacheService();

      // 1. Charger depuis le cache
      final cachedUser = await userCache.loadCachedUser();

      if (cachedUser != null) {
        setState(() {
          _currentUser = cachedUser;
        });

        if (kDebugMode) {
          print('✅ Profil chargé depuis cache: ${cachedUser.email}');
        }
      }

      // 2. Si en ligne, essayer de rafraîchir depuis le serveur
      if (_isOnline) {
        try {
          await authService.initialize();

          if (authService.currentUser != null) {
            setState(() {
              _currentUser = authService.currentUser;
            });

            // Mettre à jour le cache
            await userCache.cacheUser(authService.currentUser!);

            if (kDebugMode) {
              print(
                '✅ Profil rafraîchi depuis serveur: ${authService.currentUser!.email}',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Impossible de rafraîchir depuis serveur: $e');
          }
        }
      }

      // 3. Trigger des animations secondaires
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _triggerAvatarPulse();
          _triggerStatsRotation();
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement profil: $e');
      if (mounted) {
        _showErrorSnackbar('Erreur de chargement du profil');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
          _darkMode = prefs.getBool('dark_mode') ?? false;
          _notificationsEnabled =
              prefs.getBool('notifications_enabled') ?? true;
          _selectedLanguage = prefs.getString('language') ?? 'Français';
          _selectedRegion = prefs.getString('region') ?? 'France';
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement préférences: $e');
    }
  }

  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;

    // En mode hors ligne, pas de rafraîchissement
    if (!_isOnline) {
      _showErrorSnackbar('Impossible de rafraîchir: hors ligne');
      return;
    }

    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCache = UserCacheService();

      // Rafraîchir depuis le serveur
      await authService.refreshUserData();

      if (mounted) {
        setState(() {
          _currentUser = authService.currentUser;
        });

        // Mettre à jour le cache
        if (authService.currentUser != null) {
          await userCache.cacheUser(authService.currentUser!);
        }

        _showSuccessSnackbar('Profil actualisé avec succès');
        _triggerAvatarPulse();
      }
    } catch (e) {
      debugPrint('❌ Erreur rafraîchissement: $e');
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'actualisation';
        if (e.toString().contains('401') || e.toString().contains('403')) {
          errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        }
        _showErrorSnackbar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _triggerAvatarPulse() {
    setState(() => _avatarScale = 1.05);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _avatarScale = 1.0);
    });
  }

  void _triggerStatsRotation() {
    setState(() => _statsRotation = 0.1);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _statsRotation = 0.0);
    });
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  // ========== DÉCONNEXION ==========

  Future<void> _handleLogout() async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Déconnexion',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte Moodia ?',
          style: TextStyle(color: Color(0xFF5D6D7E), fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(
                color: Color(0xFF7DBBC3),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCache = UserCacheService();

      // 1. Nettoyer les caches utilisateur (données personnelles)
      await userCache.clearCache();

      // 2. Nettoyer les caches des services métier (journal, émotions)
      final journalService = JournalApiService();
      final emotionService = EmotionApiService();
      await journalService.clearCache();
      await emotionService.clearCache();

      // 3. Nettoyer les notifications en attente
      await NotificationCacheService.clearPendingReads();
      await NotificationCacheService.saveNotifications([]);

      // 4. Nettoyer le cache de l'abonnement (statut premium)
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      await subscriptionProvider.clearCache();

      // 5. Déconnexion via AuthService (supprime token, auth_data, etc.)
      await authService.logout();

      // 6. Redirection vers login (si le widget est encore monté)
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ Erreur déconnexion: $e');
      if (mounted) {
        _showErrorSnackbar('Erreur lors de la déconnexion, redirection forcée');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  // ========== MÉTHODES D'INTERACTION ==========

  Future<void> _toggleBiometricAuth() async {
    HapticFeedback.lightImpact();

    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;

      if (!canAuthenticate) {
        _showErrorSnackbar('Authentification biométrique non disponible');
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Activez l\'authentification biométrique pour Moodia',
      );

      if (authenticated) {
        setState(() => _biometricEnabled = !_biometricEnabled);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', _biometricEnabled);

        _showSuccessSnackbar(
          _biometricEnabled
              ? '🔐 Authentification biométrique activée'
              : '🔓 Authentification biométrique désactivée',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur auth biométrique: $e');
      _showErrorSnackbar('Erreur d\'authentification biométrique');
    }
  }

  Future<void> _showTimezoneSelector() async {
    if (!_isOnline) {
      _showErrorSnackbar('Modification impossible : hors ligne');
      return;
    }

    HapticFeedback.lightImpact();

    final timezones = [
      'Europe/Paris',
      'Europe/London',
      'America/New_York',
      'America/Los_Angeles',
      'Asia/Tokyo',
      'Australia/Sydney',
      'Africa/Cairo',
      'Asia/Dubai',
    ];

    final selectedTimezone = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🌍 Sélectionner un fuseau horaire',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF7F8C8D)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: timezones.length,
                itemBuilder: (context, index) {
                  final timezone = timezones[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: _primaryColor,
                    ),
                    title: Text(
                      timezone,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    trailing: _currentUser?.timezone == timezone
                        ? const Icon(Icons.check_circle, color: _successColor)
                        : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, timezone);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedTimezone != null &&
        selectedTimezone != _currentUser?.timezone) {
      try {
        final userService = Provider.of<UserService>(context, listen: false);
        final userCache = UserCacheService();

        await userService.updateTimezone(selectedTimezone);

        if (mounted) {
          final updatedUser = _currentUser?.copyWith(
            timezone: selectedTimezone,
          );
          setState(() {
            _currentUser = updatedUser;
          });

          if (updatedUser != null) {
            await userCache.cacheUser(updatedUser);
          }

          _showSuccessSnackbar('Fuseau horaire mis à jour: $selectedTimezone');
        }
      } catch (e) {
        debugPrint('❌ Erreur mise à jour fuseau horaire: $e');
        _showErrorSnackbar('Erreur lors de la mise à jour');
      }
    }
  }

  Future<void> _showDatePicker() async {
    if (!_isOnline) {
      _showErrorSnackbar('Modification impossible : hors ligne');
      return;
    }

    HapticFeedback.lightImpact();

    final now = DateTime.now();
    final initialDate =
        _currentUser?.birthDate ?? DateTime(now.year - 25, 1, 1);
    final firstDate = DateTime(now.year - 100, 1, 1);
    final lastDate = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && selectedDate != _currentUser?.birthDate) {
      try {
        final userService = Provider.of<UserService>(context, listen: false);
        final userCache = UserCacheService();

        await userService.updateBirthDate(selectedDate);

        if (mounted) {
          final updatedUser = _currentUser?.copyWith(birthDate: selectedDate);
          setState(() {
            _currentUser = updatedUser;
          });

          if (updatedUser != null) {
            await userCache.cacheUser(updatedUser);
          }

          final formattedDate = DateFormat(
            'dd/MM/yyyy',
            'fr_FR',
          ).format(selectedDate);
          _showSuccessSnackbar('Date de naissance mise à jour: $formattedDate');
        }
      } catch (e) {
        debugPrint('❌ Erreur mise à jour date naissance: $e');
        _showErrorSnackbar('Erreur lors de la mise à jour');
      }
    }
  }

  Future<void> _showPhoneEditDialog() async {
    if (!_isOnline) {
      _showErrorSnackbar('Modification impossible : hors ligne');
      return;
    }

    HapticFeedback.mediumImpact();

    final phoneController = TextEditingController(
      text: _currentUser?.phoneNumber ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '📱 Modifier le numéro de téléphone',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                hintText: '+33 6 12 34 56 78',
                labelText: 'Numéro de téléphone',
                prefixIcon: const Icon(Icons.phone, color: _primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryColor, width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ce numéro sera utilisé pour les notifications et la sécurité',
              style: TextStyle(fontSize: 12, color: Color(0xFF7F8C8D)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhone = phoneController.text.trim();
              if (newPhone.isNotEmpty &&
                  newPhone != _currentUser?.phoneNumber) {
                try {
                  final userService = Provider.of<UserService>(
                    context,
                    listen: false,
                  );
                  final userCache = UserCacheService();

                  await userService.updatePhoneNumber(newPhone);

                  if (mounted) {
                    final updatedUser = _currentUser?.copyWith(
                      phoneNumber: newPhone,
                    );
                    setState(() {
                      _currentUser = updatedUser;
                    });

                    if (updatedUser != null) {
                      await userCache.cacheUser(updatedUser);
                    }

                    _showSuccessSnackbar('Numéro de téléphone mis à jour');
                    Navigator.pop(context);
                  }
                } catch (e) {
                  debugPrint('❌ Erreur mise à jour téléphone: $e');
                  _showErrorSnackbar('Erreur lors de la mise à jour');
                }
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Enregistrer',
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

  // ... (Les autres méthodes _showHelpDialog, _exportData, etc. restent identiques mais peuvent aussi être conditionnées à _isOnline)

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF8FBFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profil'),
        actions: [
          // Indicateur de connexion simplifié
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), size: 14, color: _getStatusColor()),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusMessage().split(' ')[0],
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _navigateToHome,
            tooltip: 'Retour à l\'accueil',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _currentUser == null
          ? _buildNotAuthenticatedScreen()
          : LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: constraints.maxWidth > 900
                            ? _buildDesktopLayout()
                            : _buildMobileLayout(),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: _isLoading || _currentUser == null
          ? null
          : FloatingActionButton(
              onPressed: _refreshProfile,
              backgroundColor: _getStatusColor(),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 24),
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lotties/loading.json',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'Chargement de votre profil...',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(
                _primaryColor.withOpacity(0.8),
              ),
              minHeight: 4,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthenticatedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lotties/error.json', width: 200, height: 200),
          const SizedBox(height: 20),
          const Text(
            'Profil non disponible',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Connectez-vous pour voir votre profil',
            style: TextStyle(fontSize: 16, color: Color(0xFF5D6D7E)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text(
              'Se connecter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 32),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 24),
                    _buildPreferencesCard(),
                    const SizedBox(height: 24),
                    _buildSecurityCard(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                    const SizedBox(height: 40), // espace avant le footer
                    const FooterLinksCompact(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshProfile,
        color: _primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 40,
        edgeOffset: 20,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildPersonalInfoCard(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildPreferencesCard(),
                const SizedBox(height: 24),
                _buildSecurityCard(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
                const SizedBox(height: 40),
                const FooterLinksCompact(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideUpAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: _avatarScale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        center: Alignment.center,
                        colors: [
                          _primaryColor,
                          Color(0xFF4FC3F7),
                          Color(0xFF2196F3),
                          _primaryColor,
                        ],
                        stops: [0.0, 0.25, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey[100],
                            backgroundImage:
                                _currentUser?.profilePictureUrl != null
                                ? NetworkImage(_currentUser!.profilePictureUrl!)
                                : null,
                            child: _currentUser?.profilePictureUrl == null
                                ? Text(
                                    _currentUser?.initials ?? 'U',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_currentUser?.isPremium == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionPlanPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF9A826),
                                Color(0xFFFFC107),
                                Color(0xFFF9A826),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF9A826).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.diamond,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentUser?.displayName ?? 'Utilisateur',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _currentUser?.email ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF5D6D7E),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (_currentUser?.emailVerified == true)
                    _buildAnimatedStatusChip(
                      icon: Icons.verified,
                      text: 'Vérifié',
                      color: _successColor,
                    ),
                  if (_currentUser?.createdAt != null)
                    _buildAnimatedStatusChip(
                      icon: Icons.calendar_month,
                      text:
                          'Membre depuis ${DateFormat('MMM yyyy', 'fr_FR').format(_currentUser!.createdAt!)}',
                      color: _primaryColor,
                    ),
                  if (_currentUser?.streakCount != null &&
                      _currentUser!.streakCount > 0)
                    _buildAnimatedStatusChip(
                      icon: Icons.local_fire_department,
                      text: '${_currentUser!.streakCount} jours',
                      color: const Color(0xFFF44336),
                    ),
                  if (_currentUser?.isAdmin == true)
                    _buildAnimatedStatusChip(
                      icon: Icons.admin_panel_settings,
                      text: 'Administrateur',
                      color: const Color(0xFF9C27B0),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatusChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final user = _currentUser;

    return Transform.rotate(
      angle: _statsRotation,
      child: SizedBox(
        height: 200,
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          padding: const EdgeInsets.all(8),
          children: [
            _buildAnimatedStatCard(
              title: 'Série actuelle',
              value: _isOnline ? '${user?.currentStreakDays ?? 0} jours' : '?',
              subtitle: 'Objectif: ${user?.weeklyGoal ?? 7} jours',
              icon: Icons.timeline,
              color: const Color(0xFF4FC3F7),
              progress:
                  (user?.currentStreakDays ?? 0) / (user?.weeklyGoal ?? 7),
              badge: (user?.currentStreakDays ?? 0) >= 7 ? '🔥' : null,
            ),
            _buildAnimatedStatCard(
              title: 'Activités totales',
              value: _isOnline ? '${user?.totalActivitiesCompleted ?? 0}' : '?',
              subtitle: '${user?.totalTimeMinutes ?? 0} min',
              icon: Icons.self_improvement,
              color: _primaryColor,
              progress: (user?.totalActivitiesCompleted ?? 0) / 100,
              badge: (user?.totalActivitiesCompleted ?? 0) > 50 ? '🏆' : null,
            ),
            _buildAnimatedStatCard(
              title: 'Meilleure série',
              value: _isOnline ? '${user?.bestStreakDays ?? 0} jours' : '?',
              subtitle: 'Record personnel',
              icon: Icons.star_border,
              color: const Color(0xFF81C784),
              progress: (user?.bestStreakDays ?? 0) / 30,
              badge: (user?.bestStreakDays ?? 0) >= 30 ? '🌟' : null,
            ),
            _buildAnimatedStatCard(
              title: 'Objectif quotidien',
              value: '${user?.dailyGoal ?? 1} séances',
              subtitle: user?.notificationEnabled == true
                  ? 'Rappels activés'
                  : 'Sans rappels',
              icon: Icons.flag,
              color: const Color(0xFFF9A826),
              progress: 0.6,
              badge: (user?.dailyGoal ?? 0) >= 2 ? '🎯' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
    String? badge,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showStatDetails(title, value, subtitle);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  if (badge != null)
                    Text(badge, style: const TextStyle(fontSize: 18)),
                ],
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D6D7E),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7F8C8D),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(10),
                minHeight: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatDetails(String title, String value, String subtitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 16, color: Color(0xFF5D6D7E)),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Conseils pour améliorer vos statistiques :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              _buildTipItem('Pratiquez régulièrement chaque jour'),
              _buildTipItem('Fixez-vous des objectifs réalistes'),
              _buildTipItem('Utilisez les rappels de Moodia'),
              _buildTipItem('Partagez vos progrès avec la communauté'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: _successColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF5D6D7E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📋 Informations personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                IconButton(
                  onPressed: !_isOnline ? null : _showEditProfileDialog,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: !_isOnline ? Colors.grey : _primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  tooltip: 'Modifier le profil',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Nom complet',
              value: _currentUser?.fullName ?? 'Non renseigné',
              isEditable: false,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _currentUser?.email ?? 'Non renseigné',
              isEditable: false,
              verified: _currentUser?.emailVerified == true,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.phone_android,
              label: 'Téléphone',
              value: _currentUser?.phoneNumber ?? 'Non renseigné',
              isEditable: _isOnline,
              onTap: _showPhoneEditDialog,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.cake,
              label: 'Date de naissance',
              value: _currentUser?.birthDate != null
                  ? DateFormat(
                      'dd MMMM yyyy',
                      'fr_FR',
                    ).format(_currentUser!.birthDate!)
                  : 'Non renseignée',
              isEditable: _isOnline,
              onTap: _showDatePicker,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Fuseau horaire',
              value: _currentUser?.timezone ?? 'Non renseigné',
              isEditable: _isOnline,
              onTap: _showTimezoneSelector,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditable,
    bool verified = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 18, color: _primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 12,
                          color: _successColor,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF2C3E50),
                      fontWeight: isEditable
                          ? FontWeight.w700
                          : FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isEditable)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: _primaryColor, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _ActionItem(
        icon: Icons.upgrade_rounded,
        label: 'Abonnement',
        color: const Color(0xFFF9A826),
        gradient: const LinearGradient(
          colors: [Color(0xFFF9A826), Color(0xFFFFC107)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPlanPage()),
        ),
      ),
      _ActionItem(
        icon: Icons.download_rounded,
        label: 'Exporter',
        color: const Color(0xFF4FC3F7),
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: !_isOnline ? () {} : _exportData,
      ),
      _ActionItem(
        icon: Icons.help_center_rounded,
        label: 'Aide',
        color: const Color(0xFF81C784),
        gradient: const LinearGradient(
          colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: _showHelpDialog,
      ),
      _ActionItem(
        icon: Icons.settings_rounded,
        label: 'Paramètres',
        color: _primaryColor,
        gradient: LinearGradient(
          colors: [_primaryColor, const Color(0xFF4FC3F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        ),
      ),
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildAnimatedActionButton(action);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedActionButton(_ActionItem action) {
    return MouseRegion(
      onEnter: (_) => HapticFeedback.lightImpact(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: action.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: action.color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(action.icon, size: 24, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Préférences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            _buildPreferenceSwitch(
              icon: Icons.dark_mode,
              title: 'Mode sombre',
              subtitle: 'Interface adaptée pour la nuit',
              value: _darkMode,
              onChanged: (value) async {
                HapticFeedback.lightImpact();
                setState(() => _darkMode = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('dark_mode', value);
                _showSuccessSnackbar(
                  value ? 'Mode sombre activé' : 'Mode sombre désactivé',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildPreferenceSwitch(
              icon: Icons.notifications_active,
              title: 'Notifications',
              subtitle: 'Recevoir les notifications push',
              value: _notificationsEnabled,
              onChanged: (value) async {
                HapticFeedback.lightImpact();
                setState(() => _notificationsEnabled = value);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notifications_enabled', value);
                _showSuccessSnackbar(
                  value
                      ? 'Notifications activées'
                      : 'Notifications désactivées',
                );
              },
            ),
            const SizedBox(height: 12),
            _buildPreferenceSelector(
              icon: Icons.language,
              title: 'Langue',
              value: _selectedLanguage,
              onTap: _showLanguageSelector,
            ),
            const SizedBox(height: 12),
            _buildPreferenceSelector(
              icon: Icons.public,
              title: 'Région',
              value: _selectedRegion,
              onTap: _showRegionSelector,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5D6D7E),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _primaryColor,
            activeTrackColor: _primaryColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSelector({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5D6D7E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔒 Sécurité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            _buildSecurityItem(
              icon: Icons.fingerprint,
              title: 'Authentification biométrique',
              subtitle: 'Déverrouiller avec empreinte/visage',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (value) => _toggleBiometricAuth(),
                activeColor: _primaryColor,
              ),
              onTap: () => _toggleBiometricAuth(),
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              icon: Icons.security,
              title: '2FA - Authentification à deux facteurs',
              subtitle: 'Sécurisez votre compte avec un code',
              trailing: Switch(
                value: _currentUser?.twoFactorEnabled ?? false,
                onChanged: !_isOnline
                    ? null
                    : (value) => _toggleTwoFactorAuth(),
                activeColor: _primaryColor,
              ),
              onTap: !_isOnline ? null : _toggleTwoFactorAuth,
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              icon: Icons.lock_reset,
              title: 'Changer le mot de passe',
              subtitle: 'Mettez à jour votre mot de passe régulièrement',
              trailing: Icon(
                Icons.chevron_right,
                color: !_isOnline ? Colors.grey : _primaryColor,
              ),
              onTap: !_isOnline ? null : _showChangePasswordDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: onTap == null ? Colors.grey : _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: onTap == null
                          ? Colors.grey
                          : const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: onTap == null
                          ? Colors.grey
                          : const Color(0xFF5D6D7E),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: _errorColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _errorColor, width: 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: 12),
            Text(
              'Se déconnecter'.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder pour les méthodes non implémentées
  void _showHelpDialog() {
    // TODO: Implémenter l'aide
  }

  Future<void> _exportData() async {
    // TODO: Implémenter l'export
  }

  Future<void> _showLanguageSelector() async {
    // TODO: Implémenter la sélection de langue
  }

  Future<void> _showRegionSelector() async {
    // TODO: Implémenter la sélection de région
  }

  Future<void> _toggleTwoFactorAuth() async {
    // TODO: Implémenter la 2FA
  }

  Future<void> _showChangePasswordDialog() async {
    // TODO: Implémenter le changement de mot de passe
  }

  Future<void> _showEditProfileDialog() async {
    // TODO: Implémenter l'édition de profil
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final Gradient gradient;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
    required this.onTap,
  });
}
