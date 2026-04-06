import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';

import '../../services/numerology_api_service.dart';
import '../../services/numerology_profile_api_service.dart';
import '../../services/api_service.dart';
import '../../models/numerology_profile.dart';
import '../../widgets/number_expansion_card.dart';
import '../../widgets/calendar_item.dart';
import 'add_numerology_info_page.dart';
import 'edit_numerology_profile_page.dart';
import 'numerology_day_interpretation_page.dart';

class PremiumNumerologyProfilePage extends StatefulWidget {
  const PremiumNumerologyProfilePage({super.key});

  @override
  State<PremiumNumerologyProfilePage> createState() =>
      _PremiumNumerologyProfilePageState();
}

class _PremiumNumerologyProfilePageState
    extends State<PremiumNumerologyProfilePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ========== SERVICES ==========
  late final NumerologyApiService _numerologyApiService;
  late final NumerologyProfileApiService _profileApiService;

  // ========== ÉTATS ==========
  NumerologyProfile? _profile;
  int? _userId;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isServerError = false;

  // État pour le menu contextuel
  bool _isMenuVisible = false;

  // ========== ANIMATIONS ==========
  late AnimationController _animationController;
  late AnimationController _menuAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _menuAnimation;
  late ConfettiController _confettiController;

  // ========== STREAMS ==========
  StreamSubscription? _profileSubscription;

  // ========== FLAG POUR ÉVITER LES REDIRECTIONS MULTIPLES ==========
  bool _isRedirecting = false;

  // ========== INITIALISATION ==========

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeServices() {
    final apiService = ApiService();
    _numerologyApiService = NumerologyApiService(apiService);
    _profileApiService = NumerologyProfileApiService(_numerologyApiService);

    _profileSubscription = _profileApiService.profileStream.listen((profile) {
      if (mounted) {
        setState(() {
          _profile = profile;
        });
      }
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _menuAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _menuAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserId();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshProfile();
    }
  }

  // ========== GESTION DU CACHE ==========

  /// Sauvegarde le profil dans SharedPreferences
  // ========== GESTION DU CACHE ==========

  /// Sauvegarde le profil en cache (format JSON)
  Future<void> _cacheProfile(NumerologyProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = {
        'id': profile.id,
        'userId': profile.userId,
        'birthDate': profile.birthDate.toIso8601String(),
        'fullName': profile.fullName,
        'lifePathNumber': profile.lifePathNumber,
        'expressionNumber': profile.expressionNumber,
        'realizationNumber': profile.realizationNumber,
        'soulUrgeNumber': profile.soulUrgeNumber,
        'personalYear': profile.personalYear,
        'personalMonth': profile.personalMonth,
        'personalDay': profile.personalDay,
        'summary': profile.summary,
        'createdAt': profile.createdAt?.toIso8601String(),
        'updatedAt': profile.updatedAt?.toIso8601String(),
        'lifePathInterpretation': profile.lifePathInterpretation,
        'expressionInterpretation': profile.expressionInterpretation,
        'realizationInterpretation': profile.realizationInterpretation,
        'soulUrgeInterpretation': profile.soulUrgeInterpretation,
        'personalYearInterpretation': profile.personalYearInterpretation,
        'personalMonthInterpretation': profile.personalMonthInterpretation,
        'personalDayInterpretation': profile.personalDayInterpretation,
      };
      final jsonString = jsonEncode(json);
      await prefs.setString('cached_numerology_profile', jsonString);
      if (kDebugMode) print('💾 Profil numérologique sauvegardé en cache');
    } catch (e) {
      debugPrint('Erreur mise en cache: $e');
    }
  }

  /// Charge le profil depuis le cache
  Future<NumerologyProfile?> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_numerology_profile');
      if (jsonString == null) return null;
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return NumerologyProfile.fromJzon(json);
    } catch (e) {
      debugPrint('Erreur chargement cache: $e');
      return null;
    }
  }

  // Version améliorée avec JSON
  Future<void> _cacheProfileJson(NumerologyProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = {
        'id': profile.id,
        'userId': profile.userId,
        'birthDate': profile.birthDate.toIso8601String(),
        'fullName': profile.fullName,
        'lifePathNumber': profile.lifePathNumber,
        'expressionNumber': profile.expressionNumber,
        'realizationNumber': profile.realizationNumber,
        'soulUrgeNumber': profile.soulUrgeNumber,
        'personalYear': profile.personalYear,
        'personalMonth': profile.personalMonth,
        'personalDay': profile.personalDay,
        'summary': profile.summary,
        'createdAt': profile.createdAt?.toIso8601String(),
        'updatedAt': profile.updatedAt?.toIso8601String(),
        'lifePathInterpretation': profile.lifePathInterpretation,
        'expressionInterpretation': profile.expressionInterpretation,
        'realizationInterpretation': profile.realizationInterpretation,
        'soulUrgeInterpretation': profile.soulUrgeInterpretation,
        'personalYearInterpretation': profile.personalYearInterpretation,
        'personalMonthInterpretation': profile.personalMonthInterpretation,
        'personalDayInterpretation': profile.personalDayInterpretation,
      };
      final jsonString = jsonEncode(json);
      await prefs.setString('cached_numerology_profile', jsonString);
      if (kDebugMode)
        print('💾 Profil numérologique sauvegardé en cache (JSON)');
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache JSON: $e');
    }
  }

  Future<NumerologyProfile?> _loadCachedProfileJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_numerology_profile');
      if (jsonString == null) return null;

      final Map<String, dynamic> json = jsonDecode(jsonString);
      return NumerologyProfile.fromJzon(json);
    } catch (e) {
      debugPrint('Erreur chargement cache JSON: $e');
      return null;
    }
  }

  // ========== CHARGEMENT DES DONNÉES ==========

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        _redirectToLogin();
        return;
      }

      setState(() {
        _userId = userId;
        _isLoading = true;
        _errorMessage = null;
        _isServerError = false;
      });

      await _loadProfile();
    } catch (e) {
      debugPrint('❌ Erreur récupération userId: $e');
      setState(() {
        _errorMessage = 'Erreur de session';
        _isLoading = false;
        _isServerError = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    if (_userId == null) return;

    try {
      // Tenter d'abord en ligne
      final profile = await _profileApiService.loadProfile(
        userId: _userId!,
        autoCreateIfMissing: false,
      );

      if (profile == null && mounted && !_isRedirecting) {
        // Aucun profil en ligne -> rediriger vers création
        _isRedirecting = true;
        if (kDebugMode) {
          print('🚀 Profil non trouvé - Redirection vers création');
        }

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddNumerologyInfoPage(),
          ),
        );

        _isRedirecting = false;

        if (result == true && mounted) {
          await _refreshProfile();
        }
        return;
      }

      if (profile != null) {
        // Profil trouvé en ligne -> sauvegarder en cache
        await _cacheProfileJson(profile);
        setState(() {
          _profile = profile;
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
          _isServerError = false;
        });
        _confettiController.play();
        return;
      }

      // Si profile == null (pas trouvé en ligne) mais on a déjà géré la redirection
      // On essaye de charger depuis le cache en cas d'absence de réseau ? Non, on a déjà redirigé.
      // Ce cas ne devrait pas arriver.
    } on NumerologyException catch (e) {
      if (e.type == NumerologyExceptionType.server) {
        // Erreur serveur -> essayer de charger depuis le cache
        final cached = await _loadCachedProfileJson();
        if (cached != null) {
          setState(() {
            _profile = cached;
            _isLoading = false;
            _isRefreshing = false;
            _errorMessage = null;
            _isServerError = false;
          });
          _showSnackBar('Mode hors-ligne : données en cache', isError: false);
        } else {
          setState(() {
            _errorMessage =
                'Le service numérologique est temporairement indisponible. Aucune donnée en cache.';
            _isLoading = false;
            _isRefreshing = false;
            _profile = null;
            _isServerError = true;
          });
        }
      } else {
        // Autre erreur (validation, etc.)
        final cached = await _loadCachedProfileJson();
        if (cached != null) {
          setState(() {
            _profile = cached;
            _isLoading = false;
            _isRefreshing = false;
            _errorMessage = null;
            _isServerError = false;
          });
          _showSnackBar('Données en cache (erreur réseau)', isError: false);
        } else {
          setState(() {
            _errorMessage = e.message;
            _isLoading = false;
            _isRefreshing = false;
            _profile = null;
            _isServerError = false;
          });
        }
      }
    } catch (e) {
      // Erreur inattendue, essayer cache
      final cached = await _loadCachedProfileJson();
      if (cached != null) {
        setState(() {
          _profile = cached;
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
          _isServerError = false;
        });
        _showSnackBar('Données en cache', isError: false);
      } else {
        setState(() {
          _errorMessage = 'Erreur inattendue: $e';
          _isLoading = false;
          _isRefreshing = false;
          _profile = null;
          _isServerError = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    if (_userId == null || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
      _isServerError = false;
    });

    try {
      _numerologyApiService.clearCache(_userId!);

      final profile = await _profileApiService.loadProfile(
        userId: _userId!,
        autoCreateIfMissing: false,
        forceRefresh: true,
      );

      if (profile == null && mounted && !_isRedirecting) {
        _isRedirecting = true;

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddNumerologyInfoPage(),
          ),
        );

        _isRedirecting = false;

        if (result == true && mounted) {
          await _refreshProfile();
        }
        return;
      }

      if (profile != null) {
        await _cacheProfileJson(profile);
        setState(() {
          _profile = profile;
          _isRefreshing = false;
          _errorMessage = null;
          _isServerError = false;
        });
      } else {
        setState(() {
          _isRefreshing = false;
          _errorMessage = 'Profil non trouvé';
          _isServerError = false;
        });
      }
    } on NumerologyException catch (e) {
      if (e.type == NumerologyExceptionType.server) {
        setState(() {
          _isRefreshing = false;
          _errorMessage =
              'Le service numérologique est temporairement indisponible.';
          _isServerError = true;
        });
      } else {
        setState(() {
          _isRefreshing = false;
          _errorMessage = e.message;
          _isServerError = false;
        });
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _errorMessage = e.toString();
        _isServerError = false;
      });
    }
  }

  // ========== ACTIONS PROFIL ==========

  Future<void> _navigateToCreateProfile() async {
    if (_isRedirecting) return;

    _isRedirecting = true;

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddNumerologyInfoPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    _isRedirecting = false;

    if (result == true && mounted) {
      await _refreshProfile();
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_profile == null) return;

    _menuAnimationController.reverse();
    setState(() => _isMenuVisible = false);

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditNumerologyProfilePage(profile: _profile!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    if (result == true && mounted) {
      await _refreshProfile();
      _showSnackBar('Profil mis à jour avec succès !');
    }
  }

  Future<void> _navigateToDayInterpretation() async {
    if (_profile == null) return;

    _menuAnimationController.reverse();
    setState(() => _isMenuVisible = false);

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NumerologyDayInterpretationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _toggleMenu() {
    if (_isMenuVisible) {
      _menuAnimationController.reverse();
      setState(() => _isMenuVisible = false);
    } else {
      _menuAnimationController.forward();
      setState(() => _isMenuVisible = true);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _shareProfile() async {
    if (_profile == null) return;

    try {
      final shareText =
          '''
✨ MON PROFIL NUMÉROLOGIQUE MOODIA ✨

👤 ${_profile!.fullName}
📅 Né(e) le ${DateFormat.yMMMMd('fr_FR').format(_profile!.birthDate)}

🔮 CHEMIN DE VIE: ${_profile!.lifePathNumber}
📝 EXPRESSION: ${_profile!.expressionNumber}
🏆 RÉALISATION: ${_profile!.realizationNumber}
💝 INTIME: ${_profile!.soulUrgeNumber}

📆 CYCLES ACTUELS:
• Année personnelle: ${_profile!.personalYear}
• Mois personnel: ${_profile!.personalMonth}

Découvrez votre propre profil sur Moodia! 🌟
''';

      await Share.share(shareText, subject: 'Mon Profil Numérologique Moodia');
      _showSnackBar('Profil partagé avec succès !');
    } catch (e) {
      _showSnackBar('Erreur lors du partage', isError: true);
    }
  }

  void _redirectToLogin() {
    Future.microtask(() {
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF8B6B9E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========== CONSTRUCTEURS D'ÉTATS ==========

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lotties/loading_numerology.json',
            width: 180,
            height: 180,
            errorBuilder: (context, error, stackTrace) {
              return const CircularProgressIndicator(
                color: Color(0xFF8B6B9E),
                strokeWidth: 3,
              );
            },
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              'Chargement de votre univers numérologique...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8B6B9E),
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, double scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isServerError
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Icon(
                        _isServerError
                            ? Icons.cloud_off_rounded
                            : Icons.error_outline_rounded,
                        size: 70,
                        color: _isServerError
                            ? Colors.orange
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              _isServerError
                  ? 'Service Indisponible'
                  : 'Oups ! Une erreur est survenue',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1A3F),
                fontFamily: 'PlayfairDisplay',
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: _isServerError
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                _errorMessage ?? 'Impossible de charger votre profil',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6D5D82),
                  fontFamily: 'OpenSans',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            _buildActionButton(
              onPressed: _navigateToHome,
              icon: Icons.home_rounded,
              label: 'ACCUEIL',
              color: const Color(0xFF6D5D82),
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              onPressed: _refreshProfile,
              icon: Icons.refresh_rounded,
              label: 'RESSAYER',
              color: const Color(0xFF5D8CAE),
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              onPressed: _navigateToCreateProfile,
              icon: Icons.auto_awesome_rounded,
              label: 'CRÉER MON PROFIL',
              color: const Color(0xFF8B6B9E),
              isGradient: true,
            ),

            const SizedBox(height: 24),

            if (_isServerError)
              TextButton(
                onPressed: _showServerErrorInfoDialog,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5D8CAE),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Qu'est-ce que cela signifie ?",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'OpenSans',
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

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isGradient = false,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: isGradient
                  ? const LinearGradient(
                      colors: [Color(0xFF8B6B9E), Color(0xFF5D8CAE)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isGradient ? null : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: isGradient
                  ? null
                  : Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                if (isGradient)
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(20),
                splashColor: isGradient
                    ? Colors.white.withOpacity(0.2)
                    : color.withOpacity(0.2),
                highlightColor: Colors.transparent,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isGradient ? Colors.white : color,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isGradient ? Colors.white : color,
                          fontFamily: 'OpenSans',
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (isGradient) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showServerErrorInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Service Temporairement Indisponible',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C1A3F),
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Notre service de numérologie rencontre actuellement des difficultés techniques. Voici ce que vous pouvez faire :',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A3863),
                  fontFamily: 'OpenSans',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoBullet('🔄', 'Réessayer dans quelques minutes'),
              const SizedBox(height: 12),
              _buildInfoBullet('📱', 'Vérifier votre connexion internet'),
              const SizedBox(height: 12),
              _buildInfoBullet(
                '✨',
                'Vous pouvez toujours créer un nouveau profil numérologique',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B6B9E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'J\'AI COMPRIS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBullet(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6D5D82),
              fontFamily: 'OpenSans',
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileNotFoundState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.7, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, double scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF8B6B9E).withOpacity(0.2),
                          const Color(0xFF5D8CAE).withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Lottie.asset(
                        'assets/lotties/numerology_empty.json',
                        width: 160,
                        height: 160,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF8B6B9E).withOpacity(0.1),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 64,
                              color: Color(0xFF8B6B9E),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            const Text(
              'Votre Profil Numérologique',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1A3F),
                fontFamily: 'PlayfairDisplay',
                letterSpacing: 0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Révélez les mystères de votre existence à travers la science sacrée des nombres',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6D5D82),
                  fontFamily: 'OpenSans',
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 48),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B6B9E).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFE5E0F0).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 32,
                    color: Color(0xFF8B6B9E),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun profil trouvé',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C1A3F),
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Votre voyage numérologique n\'a pas encore commencé. Créez votre profil unique pour découvrir les énergies qui vous guident.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6D5D82),
                      fontFamily: 'OpenSans',
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildActionButton(
              onPressed: _navigateToCreateProfile,
              icon: Icons.auto_awesome_rounded,
              label: 'CRÉER MON PROFIL NUMÉROLOGIQUE',
              color: const Color(0xFF8B6B9E),
              isGradient: true,
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: _navigateToHome,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5D8CAE),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'RETOUR À L\'ACCUEIL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSacredDot(const Color(0xFF8B6B9E)),
                const SizedBox(width: 12),
                _buildSacredDot(const Color(0xFF5D8CAE)),
                const SizedBox(width: 12),
                _buildSacredDot(const Color(0xFFF6C667)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSacredDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  // ========== MENU CONTEXTUEL ==========

  Widget _buildFloatingMenu() {
    if (!_isMenuVisible) return const SizedBox.shrink();

    return Positioned(
      top: kToolbarHeight + 8,
      right: 16,
      child: ScaleTransition(
        scale: _menuAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(
                  icon: Icons.edit,
                  label: 'Modifier mon profil',
                  color: const Color(0xFF8B6B9E),
                  onTap: _navigateToEditProfile,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.today,
                  label: 'Interprétation du jour',
                  color: const Color(0xFF5D8CAE),
                  onTap: _navigateToDayInterpretation,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.share,
                  label: 'Partager',
                  color: const Color(0xFFF6C667),
                  onTap: () {
                    _menuAnimationController.reverse();
                    setState(() => _isMenuVisible = false);
                    _shareProfile();
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.refresh,
                  label: 'Actualiser',
                  color: const Color(0xFF6D5D82),
                  onTap: () {
                    _menuAnimationController.reverse();
                    setState(() => _isMenuVisible = false);
                    _refreshProfile();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C1A3F),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.withOpacity(0.1),
      ),
    );
  }

  // ========== PAGE DE PROFIL ==========

  Widget _buildProfileContent() {
    if (_profile == null) return const SizedBox.shrink();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          floating: false,
          pinned: true,
          snap: false,
          stretch: true,
          backgroundColor: const Color(0xFF8B6B9E),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Profil Numérologique',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                fontFamily: 'OpenSans',
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF8B6B9E),
                        const Color(0xFF5D8CAE).withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -20,
                  top: -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Lottie.asset(
                      'assets/lotties/numerology_bg.json',
                      width: 240,
                      height: 240,
                      errorBuilder: (context, error, stackTrace) {
                        return Container();
                      },
                    ),
                  ),
                ),
              ],
            ),
            stretchModes: const [StretchMode.zoomBackground],
          ),
          actions: [
            IconButton(
              onPressed: _shareProfile,
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Partager',
            ),
            IconButton(
              onPressed: _toggleMenu,
              icon: AnimatedRotation(
                turns: _isMenuVisible ? 0.25 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isMenuVisible ? Icons.close : Icons.more_vert,
                  color: Colors.white,
                ),
              ),
              tooltip: 'Options',
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildMainNumbersDashboard(),
              const SizedBox(height: 24),
              _buildEnergyRadialChart(),
              const SizedBox(height: 24),
              _buildSacredNumberCards(),
              const SizedBox(height: 24),
              _buildNumerologyCalendar(),
              const SizedBox(height: 24),
              _buildRecommendations(),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6B9E).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B6B9E), Color(0xFF5D8CAE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B6B9E).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(_profile!.fullName),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cinzel',
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C1A3F),
                    fontFamily: 'PlayfairDisplay',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.cake, size: 16, color: Color(0xFF6D5D82)),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat.yMMMMd('fr_FR').format(_profile!.birthDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6D5D82),
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NOUVEAU : widget pour afficher un nombre avec son interprétation complète
  Widget _buildNumberInterpretationCard({
    required String title,
    required int? number,
    required String? interpretation,
    required IconData icon,
    required Color color,
    required String energy,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec le nombre et le titre
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number?.toString() ?? '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cinzel',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withOpacity(0.7),
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(energy, style: const TextStyle(fontSize: 28)),
              ],
            ),
          ),
          // Interprétation
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                SelectableText(
                  interpretation ?? 'Interprétation non disponible',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF4A3863),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainNumbersDashboard() {
    return Column(
      children: [
        _buildNumberInterpretationCard(
          title: 'Chemin de Vie',
          number: _profile!.lifePathNumber,
          interpretation: _profile!.lifePathInterpretation,
          icon: Icons.terrain,
          color: const Color(0xFF8B6B9E),
          energy: '🌙',
          subtitle: 'Votre destinée',
        ),
        _buildNumberInterpretationCard(
          title: 'Expression',
          number: _profile!.expressionNumber,
          interpretation: _profile!.expressionInterpretation,
          icon: Icons.record_voice_over,
          color: const Color(0xFF5D8CAE),
          energy: '☀️',
          subtitle: 'Votre potentiel',
        ),
        _buildNumberInterpretationCard(
          title: 'Réalisation',
          number: _profile!.realizationNumber,
          interpretation: _profile!.realizationInterpretation,
          icon: Icons.emoji_events,
          color: const Color(0xFFF6C667),
          energy: '🔥',
          subtitle: 'Vos accomplissements',
        ),
      ],
    );
  }

  Widget _buildEnergyRadialChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6B9E).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, color: Color(0xFF8B6B9E), size: 24),
              SizedBox(width: 12),
              Text(
                'Carte Énergétique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C1A3F),
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _navigateToDayInterpretation,
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B6B9E).withOpacity(0.1),
                      const Color(0xFF5D8CAE).withOpacity(0.05),
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text(
                        'Voir l\'interprétation\ndu jour',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B6B9E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSacredNumberCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFF6C667),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Nombres Sacrés',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C1A3F),
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
            ],
          ),
        ),
        if (_profile!.soulUrgeNumber != null)
          NumberExpansionCard(
            title: 'Nombre Intime',
            number: _profile!.soulUrgeNumber!,
            interpretation: _profile!.soulUrgeInterpretation ?? '',
            icon: Icons.favorite,
            color: const Color(0xFFFF9E7D),
          ),
      ],
    );
  }

  Widget _buildNumerologyCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6B9E).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month, color: Color(0xFF5D8CAE), size: 24),
              SizedBox(width: 12),
              Text(
                'Calendrier Numérologique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C1A3F),
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Année personnelle
          _buildNumberInterpretationCard(
            title: 'Année Personnelle',
            number: _profile!.personalYear,
            interpretation: _profile!.personalYearInterpretation,
            icon: Icons.calendar_today,
            color: const Color(0xFF8B6B9E),
            energy: '🌍',
            subtitle: 'Votre vibration annuelle',
          ),

          const SizedBox(height: 16),

          // Mois personnel
          _buildNumberInterpretationCard(
            title: 'Mois Personnel',
            number: _profile!.personalMonth,
            interpretation: _profile!.personalMonthInterpretation,
            icon: Icons.calendar_view_month,
            color: const Color(0xFF5D8CAE),
            energy: '🌙',
            subtitle: 'Votre énergie mensuelle',
          ),

          const SizedBox(height: 16),

          // Carte d'information pour modifier le profil
          GestureDetector(
            onTap: _navigateToEditProfile,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6C667).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFF6C667).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6C667).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFFF6C667)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vos Informations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2C1A3F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_profile!.fullName}\n${DateFormat.yMMMMd('fr_FR').format(_profile!.birthDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6D5D82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFF6C667)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton vers l'interprétation du jour
          Center(
            child: TextButton.icon(
              onPressed: _navigateToDayInterpretation,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text(
                'Voir l\'interprétation complète du jour',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B6B9E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B6B9E).withOpacity(0.05),
            const Color(0xFF5D8CAE).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8B6B9E).withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFFF6C667), size: 24),
              SizedBox(width: 12),
              Text(
                'Recommandations du Jour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C1A3F),
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '• Prenez un moment pour méditer sur vos aspirations profondes',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF4A3863),
              fontFamily: 'OpenSans',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Écrivez vos intentions pour aligner vos actions avec votre chemin de vie',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF4A3863),
              fontFamily: 'OpenSans',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Entourez-vous de personnes qui vibrent à votre fréquence',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF4A3863),
              fontFamily: 'OpenSans',
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _navigateToDayInterpretation,
              icon: const Icon(Icons.today, size: 18),
              label: const Text('EN SAVOIR PLUS SUR VOTRE JOURNÉE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6B9E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    return '??';
  }

  // ========== BUILD PRINCIPAL ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/sacred_pattern.png'),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
          ),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Color(0xFF8B6B9E),
              Color(0xFF5D8CAE),
              Color(0xFFF6C667),
              Color(0xFFFF9E7D),
            ],
          ),

          if (_isLoading) ...[
            _buildLoadingState(),
          ] else if (_errorMessage != null) ...[
            _buildErrorState(),
          ] else if (_profile == null) ...[
            _buildProfileNotFoundState(),
          ] else ...[
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildProfileContent(),
              ),
            ),
          ],

          // Overlay pour fermer le menu en tapant à l'extérieur
          if (_isMenuVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(color: Colors.transparent),
              ),
            ),

          // Menu contextuel flottant
          _buildFloatingMenu(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _menuAnimationController.dispose();
    _confettiController.dispose();
    _profileSubscription?.cancel();
    _profileApiService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
