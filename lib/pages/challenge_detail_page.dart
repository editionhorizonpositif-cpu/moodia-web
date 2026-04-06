// lib/pages/challenge_detail_page.dart
// Version temporaire : "Bientôt disponible"
// Le code original est commenté pour une réactivation ultérieure.

import 'package:flutter/material.dart';
/*import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/challenge_provider.dart';
import '../../models/challenge.dart';
import '../../models/challenge_participation.dart';
import '../../widgets/challenge_status_badge.dart';
import '../../widgets/challenge_progress_bar.dart';
import '../../services/auth_service.dart';*/
import 'package:flutter/services.dart';

class ChallengeDetailPage extends StatefulWidget {
  final int challengeId;

  const ChallengeDetailPage({super.key, required this.challengeId});

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage>
    with TickerProviderStateMixin {
  // ========== CODE ORIGINAL COMMENTÉ ==========
  /*
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  bool _isLoading = false;
  bool _isJoining = false;
  bool _isFavorite = false;
  bool _hasError = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  static const Color _primaryColor = Color(0xFF7DBBC3);
  static const Color _accentColor = Color(0xFF9C27B0);
  static const Color _energyColor = Color(0xFFFF6B6B);
  static const Color _successColor = Color(0xFF4ECDC4);
  static const Color _infoColor = Color(0xFF6C5CE7);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _textLightColor = Color(0xFF7F8C8D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadChallenge();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  Future<void> _loadChallenge() async { ... }
  Future<void> _handleJoin() async { ... }
  void _showSuccessAnimation() { ... }
  Future<void> _handleComplete() async { ... }
  Future<void> _handleLeave() async { ... }
  void _refreshPage() { ... }
  Widget _buildErrorView(bool isSmallScreen) { ... }
  Widget _buildSliverAppBar(Challenge challenge, bool isSmallScreen) { ... }
  Widget _buildSliverTabBar(bool isSmallScreen) { ... }
  Widget _buildLoadingView() { ... }
  Widget _buildDetailsTab(Challenge challenge, bool isSmallScreen) { ... }
  Widget _buildSectionCard(...) { ... }
  Widget _buildInfoSection(Challenge challenge, bool isSmallScreen) { ... }
  Widget _buildInfoRow(...) { ... }
  Widget _buildTagsSection(List<String> tags, bool isSmallScreen) { ... }
  Widget _buildProgressTab(Challenge challenge, bool isSmallScreen) { ... }
  Widget _buildLeaderboardTab(...) { ... }
  Widget _buildBottomBar() { ... }
  Widget _buildBottomBarContent(...) { ... }
  Widget _buildMetricItem(...) { ... }
  Widget _buildProgressStat(...) { ... }
  String _getDifficultyLabel(String difficulty) { ... }
  Color _getDifficultyColor(String difficulty) { ... }
  String _formatDuration(Challenge challenge) { ... }
  String _translateUnit(String unit) { ... }
  String _getRemainingDays(Challenge challenge) { ... }
  Color _getRankColor(int index) { ... }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  */

  // ========== NOUVEAU CONTENU : BIENTÔT DISPONIBLE ==========
  @override
  Widget build(BuildContext context) {
    // Forcer la couleur de la barre d'état
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DBBC3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détail du défi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
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
                      width: 120,
                      height: 120,
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
                        Icons.emoji_events,
                        size: 60,
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
                  'Nous préparons une expérience immersive pour vous aider à suivre vos défis en détail. Revenez bientôt !',
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
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour aux défis'),
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
                    Icon(
                      Icons.construction,
                      size: 16,
                      color: Color(0xFF7DBBC3),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Fonctionnalité en développement',
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
    // Si des contrôleurs sont instanciés, les libérer ici
    super.dispose();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;

  _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 30.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
