// lib/pages/login_page.dart - Version ONLINE/OFFLINE avec cache
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_cache_service.dart';
import '../services/cache_manager.dart';
import '../models/auth_dtos.dart';
import '../widgets/footer_links.dart';
import '../providers/subscription_provider.dart';
import '../routes/route.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _scaleAnimation;

  // Form Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _rememberMe = true;
  String? _errorMessage;

  // États de connexion SIMPLES
  bool _isOnline = false; // true = online, false = offline
  bool _isCheckingConnection = true;
  bool _hasCachedCredentials = false;

  // Connectivity
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Flag pour éviter les setState après dispose
  bool _isDisposed = false;

  // Responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  // Colors
  static const Color _primaryColor = Color(0xFF667EEA);
  static const Color _secondaryColor = Color(0xFF764BA2);
  static const Color _successColor = Color(0xFF48BB78);
  static const Color _warningColor = Color(0xFFF6AD55);
  static const Color _errorColor = Color(0xFFF56565);
  static const Color _offlineColor = Color(0xFF9B59B6);
  static const Color _textPrimary = Color(0xFF2D3748);
  static const Color _textSecondary = Color(0xFF718096);
  static const Color _surfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initAnimations();
    _initConnectivity();
    _checkCachedCredentials();
    _loadRememberedEmail();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideUpAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  // ========== DÉTECTION INTERNET SIMPLE ==========
  Future<void> _initConnectivity() async {
    try {
      // Vérification initiale
      final result = await _connectivity.checkConnectivity();
      if (!_isDisposed && mounted) {
        _updateConnectionState(result);
      }

      // Écoute des changements
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        ConnectivityResult result,
      ) {
        if (!_isDisposed && mounted) {
          _updateConnectionState(result);
        }
      });
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isOnline = false;
          _isCheckingConnection = false;
        });
      }
    }
  }

  void _updateConnectionState(ConnectivityResult result) {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isOnline = result != ConnectivityResult.none;
      _isCheckingConnection = false;
    });

    if (kDebugMode) {
      print('🔄 Mode: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
    }
  }

  // Vérifie si des credentials existent en cache
  Future<void> _checkCachedCredentials() async {
    try {
      final userCache = UserCacheService();
      final hasUser = await userCache.isUserCached();
      if (!_isDisposed && mounted) {
        setState(() {
          _hasCachedCredentials = hasUser;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Erreur vérification cache: $e');
    }
  }

  Future<void> _loadRememberedEmail() async {
    if (_rememberMe) {
      try {
        final userCache = UserCacheService();
        final cachedEmail = await userCache.getCachedEmail();
        if (cachedEmail != null && cachedEmail.isNotEmpty) {
          _emailController.text = cachedEmail;
        }
      } catch (e) {
        print('Erreur chargement email: $e');
      }
    }
  }

  String _getStatusMessage() {
    if (_isCheckingConnection) return '🔄 Vérification...';
    return _isOnline ? '📶 Mode en ligne' : '📴 Mode hors-ligne';
  }

  Color _getStatusColor() {
    if (_isCheckingConnection) return Colors.grey;
    return _isOnline ? _successColor : _offlineColor;
  }

  IconData _getStatusIcon() {
    if (_isCheckingConnection) return Icons.help_outline;
    return _isOnline ? Icons.wifi : Icons.offline_bolt;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Vérifier si l'utilisateur change
      final userCache = UserCacheService();
      final cachedEmail = await userCache.getCachedEmail();
      if (cachedEmail != null && cachedEmail != email) {
        if (kDebugMode)
          print('🔄 Utilisateur différent → vidage global des caches');
        // Récupérer le CacheManager (via Provider ou injection)
        final cacheManager = context
            .read<CacheManager>(); // si vous utilisez Provider
        await cacheManager.clearAllCaches();
      }

      if (kDebugMode) {
        print(
          '🔄 Tentative de connexion - Mode: ${_isOnline ? "ONLINE" : "OFFLINE"}',
        );
      }

      final request = LoginRequest(email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      final apiService = ApiService();
      final authService = AuthService(prefs, apiService);

      await authService.initialize();

      bool success;

      if (_isOnline) {
        // MODE ONLINE → connexion API
        if (kDebugMode) print('🌐 Mode ONLINE - Connexion API...');
        if (kDebugMode) {
          print(
            '📤 Envoi de la requête de connexion... (attente de la réponse)',
          );
        }
        success = await authService.login(request, rememberMe: _rememberMe);
        if (kDebugMode) {
          print('✅ Réponse reçue pour la connexion');
        }
      } else {
        // MODE OFFLINE → utilisation du cache
        if (kDebugMode) print('📴 Mode OFFLINE - Utilisation cache...');

        final userCache = UserCacheService();
        final cachedUser = await userCache.loadCachedUser();

        // Vérifier si l'email correspond
        if (cachedUser != null && cachedUser.email == email) {
          authService.setUserFromCache(cachedUser);
          success = true;

          if (kDebugMode) print('✅ Connexion OFFLINE réussie avec cache');
        } else {
          success = false;
          if (kDebugMode) print('❌ Échec connexion OFFLINE - Pas de cache');
        }
      }

      if (!mounted || _isDisposed) return;

      if (success) {
        // Sauvegarder l'email pour la prochaine fois
        if (_rememberMe) {
          final userCache = UserCacheService();
          if (authService.currentUser != null) {
            await userCache.cacheUser(authService.currentUser!);
          }
        }

        // Rafraîchir abonnement seulement si online
        if (_isOnline) {
          try {
            final subscriptionProvider = Provider.of<SubscriptionProvider>(
              context,
              listen: false,
            );
            await subscriptionProvider.refreshSubscription();
          } catch (e) {
            print('⚠️ Erreur abonnement: $e');
          }
        }

        _showSuccessAnimation();

        final isEmailVerified = authService.currentUser?.emailVerified ?? false;

        if (!mounted || _isDisposed) return;

        // Message pour mode offline
        if (!_isOnline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.offline_bolt, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('Mode hors-ligne - Données en cache')),
                ],
              ),
              backgroundColor: _offlineColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 3),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        // Navigation immédiate (sans Future.delayed)
        if (_isOnline && !isEmailVerified) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/verify-email',
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        setState(() {
          _errorMessage = _isOnline
              ? (authService.authError ?? 'Échec de la connexion')
              : 'Identifiants incorrects ou non trouvés en cache';
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _errorMessage = _isOnline
              ? 'Erreur de connexion au serveur'
              : 'Erreur de connexion hors-ligne';
        });
      }
      HapticFeedback.heavyImpact();
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _successColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _successColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
            );
          },
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!_isDisposed && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  // Responsive getters
  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;
  bool get _isTablet {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _tabletBreakpoint;
  }

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= _desktopBreakpoint;

  double get _maxFormWidth {
    if (_isDesktop) return 500;
    if (_isTablet) return 450;
    return double.infinity;
  }

  EdgeInsets get _adaptivePadding {
    if (_isDesktop)
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 20);
    if (_isTablet)
      return const EdgeInsets.symmetric(horizontal: 30, vertical: 15);
    return const EdgeInsets.all(20);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectivitySubscription?.cancel();
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: _adaptivePadding,
                child: _buildForm(),
              ),
            ),
          ),
          if (_isCheckingConnection)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vérification de la connexion...',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    Color color1, color2;

    if (_isCheckingConnection) {
      color1 = Colors.grey.withOpacity(0.8);
      color2 = Colors.grey.withOpacity(0.6);
    } else if (_isOnline) {
      color1 = _primaryColor.withOpacity(0.8);
      color2 = _secondaryColor.withOpacity(0.8);
    } else {
      color1 = _offlineColor.withOpacity(0.8);
      color2 = _offlineColor.withOpacity(0.6);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(5, (index) {
            return Positioned(
              top: index * 150.0 - 100,
              left: index * 100.0 - 50,
              child: TweenAnimationBuilder<double>(
                duration: Duration(seconds: 10 + index),
                tween: Tween(begin: 0.0, end: 2 * pi),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(sin(value * 20) * 20, cos(value * 20) * 20),
                    child: Container(
                      width: 200 + index * 50,
                      height: 200 + index * 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideUpAnimation.value),
          child: Opacity(
            opacity: _fadeInAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: _maxFormWidth),
        child: Card(
          elevation: _isDesktop ? 24 : 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_isDesktop ? 32 : 24),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_isDesktop ? 32 : 24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_surfaceColor, _surfaceColor.withOpacity(0.95)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            padding: _isDesktop
                ? const EdgeInsets.all(40)
                : const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicateur de mode (online/offline)
                  if (!_isCheckingConnection)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _getStatusColor().withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getStatusIcon(),
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusMessage(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Logo
                  TweenAnimationBuilder<double>(
                    duration: const Duration(seconds: 2),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(angle: value * 0.1, child: child);
                    },
                    child: Container(
                      width: _isDesktop ? 100 : 80,
                      height: _isDesktop ? 100 : 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          _isDesktop ? 24 : 20,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  SizedBox(height: _isDesktop ? 32 : 24),

                  // Titre
                  Text(
                    'Bienvenue sur Moodia',
                    style: TextStyle(
                      fontSize: _isDesktop ? 32 : 28,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    !_isOnline
                        ? 'Mode hors-ligne - Connexion avec données en cache'
                        : 'Reconnectez-vous à votre bien-être',
                    style: TextStyle(
                      fontSize: _isDesktop ? 16 : 14,
                      color: _getStatusColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _isDesktop ? 40 : 32),

                  // Champ email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.email_outlined,
                    iconColor: _primaryColor,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email requis';
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) return 'Email invalide';
                      return null;
                    },
                  ),
                  SizedBox(height: _isDesktop ? 20 : 16),

                  // Champ mot de passe
                  _buildPasswordField(),
                  SizedBox(height: _isDesktop ? 20 : 16),

                  // Options
                  _buildOptionsRow(),
                  SizedBox(height: _isDesktop ? 32 : 24),

                  // Message d'erreur
                  if (_errorMessage != null) _buildErrorWidget(),

                  // Bouton de connexion
                  _buildLoginButton(),

                  // Info mode offline
                  if (!_isOnline) ...[
                    const SizedBox(height: 20),
                    _buildOfflineInfoCard(),
                  ],

                  SizedBox(height: _isDesktop ? 32 : 24),

                  // Séparateur
                  _buildDivider(),

                  SizedBox(height: _isDesktop ? 32 : 24),

                  // Lien inscription (désactivé en offline)
                  _buildSignupLink(),

                  // Réseaux sociaux (seulement en online)
                  if (_isOnline) ...[
                    SizedBox(height: _isDesktop ? 40 : 32),
                    _buildSocialSection(),
                    const SizedBox(height: 30),
                    const FooterLinksCompact(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required Color iconColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: _isDesktop ? 16 : 14,
        color: _textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: _isDesktop ? 16 : 14,
          color: _textSecondary,
        ),
        prefixIcon: Icon(prefixIcon, color: iconColor, size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: iconColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          vertical: _isDesktop ? 20 : 18,
          horizontal: 20,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      style: TextStyle(
        fontSize: _isDesktop ? 16 : 14,
        color: _textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        labelStyle: TextStyle(
          fontSize: _isDesktop ? 16 : 14,
          color: _textSecondary,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: _primaryColor,
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: _textSecondary,
          ),
          onPressed: () {
            setState(() => _passwordVisible = !_passwordVisible);
            HapticFeedback.lightImpact();
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          vertical: _isDesktop ? 20 : 18,
          horizontal: 20,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Mot de passe requis';
        return null;
      },
    );
  }

  Widget _buildOptionsRow() {
    if (_isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value ?? false);
                    HapticFeedback.selectionClick();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  activeColor: _primaryColor,
                  checkColor: Colors.white,
                ),
              ),
              Text(
                'Se souvenir de moi',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildForgotPasswordButton(),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                  HapticFeedback.selectionClick();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                activeColor: _primaryColor,
                checkColor: Colors.white,
              ),
            ),
            Text(
              'Se souvenir de moi',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _buildForgotPasswordButton(),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: !_isOnline
          ? null
          : () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, AppRoutes.forgotPassword);
            },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        foregroundColor: !_isOnline ? Colors.grey : _primaryColor,
      ),
      child: Text(
        'Mot de passe oublié ?',
        style: TextStyle(
          fontSize: 14,
          color: !_isOnline ? Colors.grey : _primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _errorColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: _errorColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: _errorColor,
                fontSize: _isDesktop ? 15 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    Color buttonColor;
    String buttonText;
    IconData buttonIcon;

    if (_isCheckingConnection) {
      buttonColor = Colors.grey;
      buttonText = 'VÉRIFICATION...';
      buttonIcon = Icons.help_outline;
    } else if (_isOnline) {
      buttonColor = _primaryColor;
      buttonText = 'SE CONNECTER';
      buttonIcon = Icons.login_rounded;
    } else {
      buttonColor = _offlineColor;
      buttonText = 'CONNEXION HORS-LIGNE';
      buttonIcon = Icons.offline_bolt;
    }

    final isOfflineDisabled =
        !_isOnline && !_hasCachedCredentials && !_isCheckingConnection;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || isOfflineDisabled || _isCheckingConnection)
            ? null
            : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: _isDesktop ? 20 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: _isLoading ? 0 : 8,
          shadowColor: buttonColor.withOpacity(0.5),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    isOfflineDisabled ? 'AUCUNE DONNÉE EN CACHE' : buttonText,
                    style: TextStyle(
                      fontSize: _isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOfflineInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _offlineColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _offlineColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _offlineColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: _offlineColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode hors-ligne',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _offlineColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasCachedCredentials
                      ? 'Vous pouvez vous connecter avec vos identifiants en cache.'
                      : 'Aucune donnée en cache. Connectez-vous en mode en ligne d\'abord.',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade300,
                  Colors.grey.shade300,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade300,
                  Colors.grey.shade300,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nouveau sur Moodia ? ',
          style: TextStyle(
            fontSize: _isDesktop ? 16 : 14,
            color: _textSecondary,
          ),
        ),
        GestureDetector(
          onTap: !_isOnline
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, '/register');
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(!_isOnline ? 0.05 : 0.1),
                  _secondaryColor.withOpacity(!_isOnline ? 0.05 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: _isDesktop ? 16 : 14,
                color: !_isOnline ? Colors.grey : _primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Text(
          'Connectez-vous rapidement avec',
          style: TextStyle(
            fontSize: _isDesktop ? 14 : 13,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              color: const Color(0xFFDB4437),
              onPressed: () {},
            ),
            SizedBox(width: _isDesktop ? 24 : 16),
            _buildSocialButton(
              icon: Icons.facebook,
              color: const Color(0xFF4267B2),
              onPressed: () {},
            ),
            SizedBox(width: _isDesktop ? 24 : 16),
            _buildSocialButton(
              icon: Icons.apple,
              color: Colors.black,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              onHover: (value) {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: _isDesktop ? 64 : 56,
                height: _isDesktop ? 64 : 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: _isDesktop ? 32 : 28),
              ),
            ),
          ),
        );
      },
    );
  }
}
