import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/api_service.dart';
import '../models/numerology_profile.dart';

class NumerologyDayInterpretationPage extends StatefulWidget {
  final NumerologyProfile? profile;

  const NumerologyDayInterpretationPage({super.key, this.profile});

  @override
  State<NumerologyDayInterpretationPage> createState() =>
      _NumerologyDayInterpretationPageState();
}

class _NumerologyDayInterpretationPageState
    extends State<NumerologyDayInterpretationPage>
    with TickerProviderStateMixin {
  // ========== ÉTATS ==========
  NumerologyProfile? _profile;
  bool _isLoading = true;
  bool _isPlaying = false;
  final AudioPlayer _player = AudioPlayer();

  // ========== ANIMATIONS ==========
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final AnimationController _rotateController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _rotateAnimation;

  // ========== CITATIONS SACRÉES ==========
  final List<String> _sacredQuotes = const [
    "Chaque jour porte une vibration unique qui influence votre chemin",
    "Les nombres sont les clés qui ouvrent les portes de la conscience",
    "Écoutez la sagesse silencieuse des chiffres qui vous entourent",
    "Votre journée est une toile où les nombres peignent leur magie",
    "L'univers vous parle à travers les nombres du jour",
  ];

  String _currentQuote = "";

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _currentQuote = _sacredQuotes[0];
    _startQuoteRotation();
    _loadProfile();
  }

  void _initializeAnimations() {
    // Contrôleur principal d'apparition
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Contrôleur d'échelle
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Contrôleur de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Contrôleur de flottement
    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    // Contrôleur de rotation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    // Démarrer l'animation d'apparition
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  void _startQuoteRotation() {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          final currentIndex = _sacredQuotes.indexOf(_currentQuote);
          final nextIndex = (currentIndex + 1) % _sacredQuotes.length;
          _currentQuote = _sacredQuotes[nextIndex];
        });
        _startQuoteRotation();
      }
    });
  }

  Future<void> _playSoftBell() async {
    if (_isPlaying) return;

    try {
      setState(() => _isPlaying = true);
      await _player.play(AssetSource('sounds/soft_bell.mp3'));
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Erreur audio: $e');
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _loadProfile() async {
    // Si le profil est passé en paramètre
    if (widget.profile != null) {
      setState(() {
        _profile = widget.profile;
        _isLoading = false;
      });
      await _playSoftBell();
      return;
    }

    // Sinon, charger depuis SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId != null && mounted) {
        final fetchedProfile = await ApiService().getNumerologyProfileByUserId(
          userId,
        );
        setState(() {
          _profile = fetchedProfile;
          _isLoading = false;
        });
        await _playSoftBell();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getEnergyEmoji(int? number) {
    switch (number) {
      case 1:
        return '☀️';
      case 2:
        return '🌙';
      case 3:
        return '🎨';
      case 4:
        return '🏛️';
      case 5:
        return '🌪️';
      case 6:
        return '💝';
      case 7:
        return '🔮';
      case 8:
        return '⚖️';
      case 9:
        return '🌊';
      default:
        return '✨';
    }
  }

  Color _getNumberColor(int? number) {
    switch (number) {
      case 1:
        return const Color(0xFFFF6B6B);
      case 2:
        return const Color(0xFF4A90E2);
      case 3:
        return const Color(0xFFF6C667);
      case 4:
        return const Color(0xFF6B8E4A);
      case 5:
        return const Color(0xFFFF9E7D);
      case 6:
        return const Color(0xFFD4A5A5);
      case 7:
        return const Color(0xFF9B6BB3);
      case 8:
        return const Color(0xFF4A6B7D);
      case 9:
        return const Color(0xFFE57373);
      default:
        return const Color(0xFF8B6B9E);
    }
  }

  List<String> _getRecommendations(int number) {
    switch (number) {
      case 1:
        return [
          "Prenez une initiative audacieuse aujourd'hui",
          "Affirmez votre leadership avec confiance",
          "Un nouveau départ vous attend",
          "Osez être pionnier dans vos projets",
        ];
      case 2:
        return [
          "Cultivez l'harmonie dans vos relations",
          "Écoutez votre intuition profonde",
          "La patience sera votre alliée",
          "Cherchez l'équilibre en toutes choses",
        ];
      case 3:
        return [
          "Exprimez votre créativité sans retenue",
          "Partagez votre joie avec les autres",
          "Laissez parler votre cœur",
          "La communication est votre force",
        ];
      case 4:
        return [
          "Structurez vos idées avec méthode",
          "La discipline mène au succès",
          "Construisez des bases solides",
          "La persévérance paiera",
        ];
      case 5:
        return [
          "Accueillez le changement positivement",
          "Explorez de nouveaux horizons",
          "Libérez-vous des routines",
          "L'aventure vous appelle",
        ];
      case 6:
        return [
          "Prenez soin de vos proches",
          "L'équilibre familial est essentiel",
          "Offrez votre soutien sincèrement",
          "La beauté est dans les détails",
        ];
      case 7:
        return [
          "Méditez sur vos aspirations",
          "La solitude peut être enrichissante",
          "Cherchez la sagesse intérieure",
          "Les réponses sont en vous",
        ];
      case 8:
        return [
          "Visualisez vos objectifs ambitieux",
          "Le pouvoir est entre vos mains",
          "Agissez avec intégrité",
          "L'abondance est à portée",
        ];
      case 9:
        return [
          "Pratiquez la compassion",
          "Lâchez prise sur le passé",
          "Ouvrez votre cœur aux autres",
          "La sagesse vous guide",
        ];
      default:
        return [
          "Écoutez votre intuition aujourd'hui",
          "Restez ouvert aux synchronicités",
          "La magie opère dans l'instant présent",
          "Confiance en l'univers",
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1A1A2E),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Arrière-plan cosmique
            _buildCosmicBackground(),

            // Étoiles animées
            Positioned.fill(
              child: CustomPaint(
                painter: StarPainter(animation: _floatController.value),
              ),
            ),

            // Particules énergétiques
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: EnergyParticlesPainter(
                      animation: _pulseController.value,
                    ),
                  );
                },
              ),
            ),

            // Contenu principal
            SafeArea(
              child: _isLoading
                  ? _buildLoadingState()
                  : _profile == null
                  ? _buildErrorState()
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'SAGESSE DU JOUR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      centerTitle: true,
    );
  }

  Widget _buildCosmicBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: const [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F0F1A),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation de chargement
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B6B9E).withOpacity(0.3),
                        const Color(0xFF5D8CAE).withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Lottie.asset(
                      'assets/lotties/cosmic_loading.json',
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B6B9E),
                            strokeWidth: 3,
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

          // Texte de chargement
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, double opacity, child) {
              return Opacity(
                opacity: opacity,
                child: Column(
                  children: [
                    const Text(
                      'CONNEXION COSMIQUE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B6B9E),
                        fontFamily: 'OpenSans',
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        _currentQuote,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontFamily: 'OpenSans',
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
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
          // Icône d'erreur
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.nights_stay_rounded,
              size: 70,
              color: Colors.redAccent,
            ),
          ),

          const SizedBox(height: 32),

          // Titre
          const Text(
            'PROFIL INTROUVABLE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'PlayfairDisplay',
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 16),

          // Message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Créez d\'abord votre profil numérologique pour découvrir l\'énergie de votre journée',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontFamily: 'OpenSans',
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // Bouton retour
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B6B9E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              shadowColor: const Color(0xFF8B6B9E).withOpacity(0.5),
            ),
            child: const Text('RETOUR'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final dayNumber = _profile!.personalDay ?? 1;
    final yearNumber = _profile!.personalYear ?? 1;
    final monthNumber = _profile!.personalMonth ?? 1;
    final dayColor = _getNumberColor(dayNumber);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            children: [
              // Cadran lunaire
              _buildLunarDial(dayNumber, dayColor),

              const SizedBox(height: 24),

              // Date sublime
              _buildSacredDate(now, formatter, dayColor),

              const SizedBox(height: 32),

              // Titre sacré
              _buildSacredTitle(dayNumber, dayColor),

              const SizedBox(height: 16),

              // Citation animée
              _buildAnimatedQuote(dayColor),

              const SizedBox(height: 32),

              // Carte principale
              _buildSacredCard(
                title: "INTERPRÉTATION DE VOTRE JOURNÉE",
                number: dayNumber,
                interpretation:
                    _profile!.personalDayInterpretation ??
                    "Aujourd'hui, vous êtes guidé par l'énergie du nombre $dayNumber. Cette vibration influence votre humeur, vos interactions et les opportunités qui se présentent à vous.",
                color: dayColor,
                icon: Icons.wb_sunny_rounded,
              ),

              const SizedBox(height: 20),

              // Cartes secondaires
              _buildSecondaryCards(yearNumber, monthNumber),

              const SizedBox(height: 24),

              // Recommandations
              _buildRecommendations(dayNumber),

              const SizedBox(height: 24),

              // Pieds de page sacrés
              _buildSacredFooter(dayColor),

              const SizedBox(height: 20),

              // Mantra
              _buildMantra(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLunarDial(int dayNumber, Color dayColor) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  dayColor.withOpacity(0.3),
                  dayColor.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [dayColor, dayColor.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dayColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cinzel',
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _getEnergyEmoji(dayNumber),
                        style: const TextStyle(fontSize: 24),
                      ),
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

  Widget _buildSacredDate(DateTime now, DateFormat formatter, Color dayColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, color: dayColor, size: 18),
          const SizedBox(width: 10),
          Text(
            formatter.format(now).toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'OpenSans',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSacredTitle(int dayNumber, Color dayColor) {
    return Column(
      children: [
        const Text(
          'VIBRATION DU JOUR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B6B9E),
            fontFamily: 'OpenSans',
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [dayColor, dayColor.withOpacity(0.7)],
          ).createShader(bounds),
          child: Text(
            'JOUR $dayNumber',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'PlayfairDisplay',
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedQuote(Color dayColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey<String>(_currentQuote),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dayColor.withOpacity(0.3)),
        ),
        child: Text(
          _currentQuote,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontFamily: 'OpenSans',
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSacredCard({
    required String title,
    required int number,
    required String? interpretation,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color.withOpacity(0.8),
                        fontFamily: 'OpenSans',
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'NOMBRE $number',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontFamily: 'Cinzel',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getEnergyEmoji(number),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Text(
              interpretation ?? "Aucune interprétation disponible.",
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                fontFamily: 'OpenSans',
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCards(int yearNumber, int monthNumber) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            title: "ANNÉE",
            number: yearNumber,
            interpretation: _profile!.personalYearInterpretation,
            color: _getNumberColor(yearNumber),
            icon: Icons.calendar_month_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            title: "MOIS",
            number: monthNumber,
            interpretation: _profile!.personalMonthInterpretation,
            color: _getNumberColor(monthNumber),
            icon: Icons.calendar_view_month_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required String title,
    required int number,
    required String? interpretation,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                  fontFamily: 'OpenSans',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Cinzel',
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getEnergyEmoji(number),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            interpretation?.split('.').first ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
              fontFamily: 'OpenSans',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(int dayNumber) {
    final recommendations = _getRecommendations(dayNumber);
    final color = _getNumberColor(dayNumber);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                'RECOMMANDATIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9),
                  fontFamily: 'OpenSans',
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations
              .map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontFamily: 'OpenSans',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSacredFooter(Color dayColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSacredSymbol('☉', dayColor),
        const SizedBox(width: 16),
        _buildSacredSymbol('☽', dayColor.withOpacity(0.7)),
        const SizedBox(width: 16),
        _buildSacredSymbol('♁', dayColor.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildSacredSymbol(String symbol, Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1 * (1 + _pulseAnimation.value * 0.5)),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMantra() {
    return Text(
      'Om Mani Padme Hum',
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.3),
        fontFamily: 'OpenSans',
        fontStyle: FontStyle.italic,
        letterSpacing: 2,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    _player.dispose();
    super.dispose();
  }
}

// ========== PAINTER D'ÉTOILES ==========
class StarPainter extends CustomPainter {
  final double animation;

  StarPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 * (1 - animation))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = (i * 37 + animation * 100) % size.width;
      final y = (i * 73 + animation * 50) % size.height;
      final starSize = 1.5 + (i % 3) * 0.5;

      paint.color = Colors.white.withOpacity(0.2 + (i % 5) * 0.05);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ========== PAINTER DE PARTICULES ÉNERGÉTIQUES ==========
class EnergyParticlesPainter extends CustomPainter {
  final double animation;

  EnergyParticlesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 53 + animation * 200) % size.width;
      final y = (i * 97 + animation * 100) % size.height;
      final particleSize = 1.0 + animation * 1.5;

      paint.color = const Color(0xFF8B6B9E).withOpacity(0.1 * (1 - animation));
      canvas.drawCircle(Offset(x, y), particleSize, paint);

      paint.color = const Color(0xFF5D8CAE).withOpacity(0.08 * (1 - animation));
      canvas.drawCircle(Offset(x + 30, y - 20), particleSize * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
