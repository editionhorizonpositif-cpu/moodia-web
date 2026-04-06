// lib/pages/user_challenges_page.dart
// Version temporaire : "Bientôt disponible"
// Le code original est commenté pour une réactivation ultérieure.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/challenge_card.dart';
import '../../routes/route.dart';

class UserChallengesPage extends StatefulWidget {
  const UserChallengesPage({super.key});

  @override
  State<UserChallengesPage> createState() => _UserChallengesPageState();
}

class _UserChallengesPageState extends State<UserChallengesPage>
    with TickerProviderStateMixin {
  // ========== CODE ORIGINAL COMMENTÉ ==========
  /*
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnimations();
    _getUserId();
    _loadUserChallenges();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && mounted) {
        HapticFeedback.selectionClick();
      }
    });
  }

  void _initializeAnimations() { ... }
  void _getUserId() { ... }
  Future<void> _loadUserChallenges() async { ... }
  Future<void> _refreshChallenges() async { ... }
  void _navigateToHome() { ... }
  void _showExitDialog() { ... }
  void _navigateToChallengeSearch() { ... }
  void _navigateToChallengeDetail(int challengeId) { ... }
  void _goBack() { ... }
  @override
  void dispose() { ... }
  List<dynamic> _filterChallenges(List<dynamic> challenges) { ... }
  int _getTotalChallenges(ChallengeProvider provider) { ... }
  Widget _buildStatChip(...) { ... }
  Widget _buildLoadingState() { ... }
  Widget _buildChallengesList(List<dynamic> challenges) { ... }
  Widget _buildEmptyState() { ... }
  // fin du code original
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
          'Mes défis',
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
                        Icons.assignment_rounded,
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
                  'Nous travaillons sur une nouvelle interface pour gérer vos défis personnels. Revenez bientôt pour suivre vos progrès !',
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
                label: const Text('Retour'),
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
