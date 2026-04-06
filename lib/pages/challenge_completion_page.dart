// lib/pages/challenge_completion_page.dart
// Version temporaire : "Bientôt disponible"
// Le code original est commenté pour une réactivation ultérieure.

import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
//import '../../providers/challenge_provider.dart';
//import '../../models/challenge_request_dtos.dart';

class ChallengeCompletionPage extends StatefulWidget {
  final int challengeId;

  const ChallengeCompletionPage({super.key, required this.challengeId});

  @override
  State<ChallengeCompletionPage> createState() =>
      _ChallengeCompletionPageState();
}

class _ChallengeCompletionPageState extends State<ChallengeCompletionPage> {
  // ========== CODE ORIGINAL COMMENTÉ ==========
  /*
  final _formKey = GlobalKey<FormState>();
  int _rating = 5;
  int? _difficultyRating;
  int? _enjoymentRating;
  int? _moodImprovement;
  int? _confidenceGain;
  int? _stressReduction;
  final _feedbackController = TextEditingController();
  final _learningController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _challengesController = TextEditingController();
  int? _timeInvested;
  int? _daysConsistent;
  int? _daysMissed;
  bool _wouldRecommend = true;
  bool _wouldRepeat = true;
  bool _shareOnFeed = true;
  bool _isPublic = false;
  bool _isMilestone = false;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _feedbackController.dispose();
    _learningController.dispose();
    _achievementsController.dispose();
    _challengesController.dispose();
    super.dispose();
  }

  Future<void> _submitCompletion() async {
    // ... tout le code de soumission ...
  }

  void _showSuccessDialog() { ... }

  Widget _buildRatingStep() { ... }
  Widget _buildImpactStep() { ... }
  Widget _buildFinalStep() { ... }
  Widget _buildSliderField(...) { ... }
  Widget _buildNumberField(...) { ... }
  String _getRatingLabel(int rating) { ... }

  @override
  Widget build(BuildContext context) {
    // ... la méthode build originale ...
  }
  */

  // ========== NOUVEAU CONTENU : BIENTÔT DISPONIBLE ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DBBC3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Compléter le défi',
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
                  'Nous préparons une nouvelle expérience pour vous permettre de suivre et célébrer vos accomplissements. Revenez bientôt !',
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
                onPressed: () => context.pop(),
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
}
