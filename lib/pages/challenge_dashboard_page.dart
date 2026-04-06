// lib/pages/challenge_dashboard_page.dart
// Version temporaire : "Bientôt disponible"
// Le code original est commenté pour une réactivation ultérieure.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class ChallengeDashboardPage extends StatefulWidget {
  const ChallengeDashboardPage({super.key});

  @override
  State<ChallengeDashboardPage> createState() => _ChallengeDashboardPageState();
}

class _ChallengeDashboardPageState extends State<ChallengeDashboardPage>
    with TickerProviderStateMixin {
  // ========== CODE ORIGINAL COMMENTÉ ==========
  /*
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoadingMore = false;
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  // Thème des défis
  static const Color _primaryColor = Color(0xFF7DBBC3);
  static const Color _primaryDarkColor = Color(0xFF5A9AA3);
  static const Color _secondaryColor = Color(0xFFFFB6C1);
  static const Color _accentColor = Color(0xFF9C27B0);
  static const Color _energyColor = Color(0xFFFF6B6B);
  static const Color _successColor = Color(0xFF4ECDC4);
  static const Color _warningColor = Color(0xFFFFB347);
  static const Color _infoColor = Color(0xFF6C5CE7);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _surfaceColor = Colors.white;
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _textLightColor = Color(0xFF7F8C8D);

  final List<Color> _gradientColors = [
    const Color(0xFF7DBBC3),
    const Color(0xFF9C27B0),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFB347),
    const Color(0xFF6C5CE7),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeData();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<ChallengeProvider>(context, listen: false);
    await provider.refreshAllData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreChallenges();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadMoreChallenges() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final provider = Provider.of<ChallengeProvider>(context, listen: false);
    await provider.loadMoreChallenges();
    setState(() => _isLoadingMore = false);
  }

  void _handleCategoryFilter(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _animationController.reset();
    _animationController.forward();
  }

  bool _isAdmin() {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.currentUser?.isAdmin ?? false;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  void _navigateTo(String route, {Object? arguments}) {
    if (route == '/home') {
      Navigator.pushNamed(context, '/home');
    } else if (route == '/challenges/search') {
      Navigator.pushNamed(context, '/challenges/search');
    } else if (route == '/user/challenges') {
      Navigator.pushNamed(context, '/user/challenges');
    } else if (route == '/notifications') {
      Navigator.pushNamed(context, '/notifications');
    } else if (route == '/admin/challenges/add') {
      Navigator.pushNamed(context, '/admin/challenges/add');
    } else if (route.startsWith('/challenges/detail/')) {
      final challengeIdString = route.replaceAll('/challenges/detail/', '');
      final challengeId = int.tryParse(challengeIdString);
      if (challengeId != null) {
        Navigator.pushNamed(
          context,
          '/challenges/detail',
          arguments: challengeId,
        );
      }
    } else if (route == '/login') {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ... (tous les widgets et méthodes restants)
  // Fin du code original
  */

  // ========== NOUVEAU CONTENU : BIENTÔT DISPONIBLE ==========
  @override
  Widget build(BuildContext context) {
    // Forcer la couleur de la barre d'état en blanc (pour correspondre au design)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Défis bien-être',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône animée
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7DBBC3), Color(0xFF9C27B0)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7DBBC3).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Iconsax.award,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Titre
              const Text(
                'Bientôt disponible',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  'Nous travaillons actuellement sur une nouvelle expérience de défis bien-être pour vous aider à atteindre vos objectifs.',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              // Indicateur de progression (animation)
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: null, // indéterminé
                  backgroundColor: const Color(0xFF7DBBC3).withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7DBBC3),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24),
              // Bouton de retour
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Iconsax.arrow_left_2),
                label: const Text('Retour à l\'accueil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DBBC3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 32),
              // Note de bas de page
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DBBC3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.heart, size: 16, color: Color(0xFF7DBBC3)),
                    SizedBox(width: 8),
                    Text(
                      'Restez connecté, des surprises vous attendent !',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2C3E50)),
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

  @override
  void dispose() {
    // Si vous avez des contrôleurs ou abonnements, libérez-les ici
    super.dispose();
  }
}
