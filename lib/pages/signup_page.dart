import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:math';
import 'package:moodia/pages/verification_email_page.dart'; // ✅ Nouvelle page OTP
import 'package:moodia/pages/login_page.dart';
import 'package:moodia/services/api_service.dart';
import 'package:moodia/models/auth_dtos.dart';
import '../widgets/footer_links.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  // Animation Controllers
  AnimationController? _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<double> _scaleAnimation;

  // Form Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _acceptTerms = false;
  String? _errorMessage;

  // États de connexion
  bool _isOnline = true;
  bool _isCheckingConnection = true;

  // Connectivity
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // API Service
  final ApiService _apiService = ApiService();

  // Flag pour éviter les setState après dispose
  bool _isDisposed = false;

  // Responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  // Colors (harmonisées avec la page de login)
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
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideUpAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController!.forward();
  }

  // ========== DÉTECTION INTERNET ==========
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (!_isDisposed && mounted) {
        _updateConnectionState(result);
      }

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
      print('🔄 Signup mode: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
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

  // ========== INSCRIPTION ==========
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Veuillez accepter les conditions d\'utilisation';
      });
      return;
    }

    if (!_isOnline) {
      setState(() {
        _errorMessage =
            'Inscription impossible hors-ligne. Rétablissez la connexion.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final request = SignupRequest(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      if (kDebugMode) {
        print('📤 Envoi de la requête d\'inscription...');
      }

      // Appel à l'API d'inscription
      final response = await _apiService.register(request);
      // Ne pas convertir en AuthResponse, on ne sauvegarde rien

      if (kDebugMode) {
        print('✅ Inscription réussie pour ${request.email}');
      }

      // ✅ Sauvegarder uniquement l'email pour la vérification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_verification_email', request.email);

      // Supprimer toutes les éventuelles anciennes données (au cas où)
      await prefs.remove('jwt_token');
      await prefs.remove('user_data');
      await prefs.remove('is_logged_in');
      await prefs.remove('userId');
      await prefs.remove('email_verified');

      if (!mounted || _isDisposed) return;

      // Afficher l'animation de succès puis naviguer vers VerifyEmailPage
      await _showSuccessAndNavigate();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur inscription: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
      HapticFeedback.heavyImpact();
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ Animation de succès avec fermeture automatique puis navigation vers OTP
  Future<void> _showSuccessAndNavigate() async {
    // Afficher le dialog de succès (non fermable)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Empêche la fermeture par retour arrière
        child: Center(
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
      ),
    );

    // Attendre 1 seconde pour que l'utilisateur voie l'animation
    await Future.delayed(const Duration(seconds: 1));

    // Fermer le dialog
    if (mounted) {
      Navigator.of(context).pop(); // ferme le dialog
      // Petit délai pour laisser le temps à l'animation de fermeture
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Naviguer vers la page de vérification par code OTP
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
      );
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 409) {
        return 'Cet email est déjà utilisé';
      } else if (error.statusCode == 400) {
        return 'Données invalides. Vérifiez vos informations';
      }
      return 'Erreur serveur: ${error.statusCode}';
    } else if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return 'Problème de connexion. Vérifiez votre internet.';
    }
    return 'Erreur de connexion. Vérifiez votre internet.';
  }

  // ========== CONSTRUCTION UI ==========
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
    _animationController?.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
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
    if (_animationController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AnimatedBuilder(
      animation: _animationController!,
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

                  Text(
                    'Rejoignez Moodia',
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
                        ? 'Mode hors-ligne - Inscription impossible'
                        : 'Commencez votre voyage vers le bien-être',
                    style: TextStyle(
                      fontSize: _isDesktop ? 16 : 14,
                      color: !_isOnline ? _offlineColor : _textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _isDesktop ? 40 : 32),

                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Nom complet',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Veuillez entrer votre nom';
                      if (value.length < 2) return 'Nom trop court';
                      return null;
                    },
                  ),
                  SizedBox(height: _isDesktop ? 20 : 16),

                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Veuillez entrer votre email';
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value)) return 'Email invalide';
                      return null;
                    },
                  ),
                  SizedBox(height: _isDesktop ? 20 : 16),

                  _buildTextField(
                    controller: _usernameController,
                    label: 'Nom d\'utilisateur',
                    prefixIcon: Icons.alternate_email_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Veuillez choisir un nom d\'utilisateur';
                      if (value.length < 3) return '3 caractères minimum';
                      final usernameRegex = RegExp(r'^[a-zA-Z0-9_.-]+$');
                      if (!usernameRegex.hasMatch(value))
                        return 'Caractères autorisés: lettres, chiffres, . _ -';
                      return null;
                    },
                  ),
                  SizedBox(height: _isDesktop ? 20 : 16),

                  _buildPasswordField(),
                  SizedBox(height: _isDesktop ? 24 : 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged: _isOnline
                              ? (value) {
                                  setState(() => _acceptTerms = value ?? false);
                                  HapticFeedback.selectionClick();
                                }
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          activeColor: _primaryColor,
                          checkColor: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                              height: 1.3,
                            ),
                            children: [
                              const TextSpan(text: 'J\'accepte les '),
                              TextSpan(
                                text: 'conditions d\'utilisation',
                                style: TextStyle(
                                  color: _isOnline
                                      ? _primaryColor
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' et la '),
                              TextSpan(
                                text: 'politique de confidentialité',
                                style: TextStyle(
                                  color: _isOnline
                                      ? _primaryColor
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _isDesktop ? 32 : 24),

                  if (_errorMessage != null) _buildErrorWidget(),

                  _buildSignupButton(),

                  if (!_isOnline) ...[
                    const SizedBox(height: 20),
                    _buildOfflineInfoCard(),
                  ],

                  SizedBox(height: _isDesktop ? 32 : 24),

                  _buildDivider(),

                  SizedBox(height: _isDesktop ? 32 : 24),

                  _buildLoginLink(),
                  const SizedBox(height: 30),
                  const FooterLinksCompact(),
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
        prefixIcon: Icon(prefixIcon, color: _primaryColor, size: 22),
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
          borderSide: BorderSide(color: _primaryColor, width: 2),
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
        if (value == null || value.isEmpty)
          return 'Veuillez entrer un mot de passe';
        if (value.length < 8) return '8 caractères minimum';
        if (!RegExp(r'[A-Z]').hasMatch(value))
          return 'Doit contenir une majuscule';
        if (!RegExp(r'[a-z]').hasMatch(value))
          return 'Doit contenir une minuscule';
        if (!RegExp(r'[0-9]').hasMatch(value))
          return 'Doit contenir un chiffre';
        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value))
          return 'Doit contenir un caractère spécial';
        return null;
      },
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

  Widget _buildSignupButton() {
    final bool isDisabled = _isLoading || !_isOnline || !_acceptTerms;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _signup,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: _isDesktop ? 20 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: _isLoading ? 0 : 8,
          shadowColor: _primaryColor.withOpacity(0.5),
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
                  Icon(Icons.person_add_alt_1_rounded, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'CRÉER MON COMPTE',
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
            child: Text(
              'Mode hors-ligne : vous ne pouvez pas créer de compte sans connexion internet.',
              style: TextStyle(fontSize: 14, color: _textSecondary),
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: TextStyle(
            fontSize: _isDesktop ? 16 : 14,
            color: _textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = 1.0;
                      const end = 0.0;
                      const curve = Curves.easeInOut;
                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      return ScaleTransition(
                        scale: animation.drive(tween),
                        child: child,
                      );
                    },
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.1),
                  _secondaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Se connecter',
              style: TextStyle(
                fontSize: _isDesktop ? 16 : 14,
                color: _primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
