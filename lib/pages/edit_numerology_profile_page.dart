// lib/screens/numerology/edit_numerology_profile_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

import '../../models/numerology_profile.dart';
import '../../services/numerology_api_service.dart';
import '../../services/api_service.dart';
import '../../services/numerology_profile_api_service.dart';

class EditNumerologyProfilePage extends StatefulWidget {
  final NumerologyProfile profile;

  const EditNumerologyProfilePage({super.key, required this.profile});

  @override
  State<EditNumerologyProfilePage> createState() =>
      _EditNumerologyProfilePageState();
}

class _EditNumerologyProfilePageState extends State<EditNumerologyProfilePage>
    with TickerProviderStateMixin {
  // ========== CONTRÔLEURS ==========
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedDate;

  // ========== ÉTATS ==========
  bool _isSubmitting = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _formProgress = 0.0;
  bool _hasChanges = false;

  // ========== ANIMATIONS ==========
  late final AnimationController _floatingController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _confettiController;
  late final AnimationController _warningController;

  // ========== ANIMATIONS NATIVES ==========
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  // ========== FOCUS NODES ==========
  late final FocusNode _fullNameFocusNode;
  late final FocusNode _birthDateFocusNode;

  // ========== DONNÉES ORIGINALES POUR DÉTECTER LES CHANGEMENTS ==========
  late final String _originalFullName;
  late final DateTime _originalBirthDate;

  @override
  void initState() {
    super.initState();

    // Initialiser les données originales
    _originalFullName = widget.profile.fullName;
    _originalBirthDate = widget.profile.birthDate;

    // Initialiser les contrôleurs avec les données existantes
    _fullNameController.text = widget.profile.fullName;
    _selectedDate = widget.profile.birthDate;
    _birthDateController.text = DateFormat.yMMMMd(
      'fr_FR',
    ).format(widget.profile.birthDate);

    // Initialiser les contrôleurs d'animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _warningController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animations natives pour les éléments d'entrée
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeIn),
    );

    _fullNameFocusNode = FocusNode();
    _birthDateFocusNode = FocusNode();

    _setupInputListeners();

    // Démarrer les animations initiales
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _floatingController.forward();
      }
    });
  }

  void _setupInputListeners() {
    _fullNameController.addListener(_updateProgress);
    _birthDateController.addListener(_updateProgress);
    _fullNameController.addListener(_detectChanges);
    _birthDateController.addListener(_detectChanges);
  }

  void _updateProgress() {
    double progress = 0.0;
    if (_fullNameController.text.isNotEmpty) progress += 0.5;
    if (_birthDateController.text.isNotEmpty) progress += 0.5;

    setState(() {
      _formProgress = progress;
    });
  }

  void _detectChanges() {
    final hasNameChanged = _fullNameController.text.trim() != _originalFullName;
    final hasDateChanged = _selectedDate != _originalBirthDate;

    setState(() {
      _hasChanges = hasNameChanged || hasDateChanged;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    HapticFeedback.lightImpact();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B6B9E),
              onPrimary: Colors.white,
              surface: Color(0xFFFAF7FC),
              onSurface: Color(0xFF2C1A3F),
            ),
            dialogBackgroundColor: Colors.white,
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontFamily: 'PlayfairDisplay'),
              titleLarge: TextStyle(fontFamily: 'PlayfairDisplay'),
              bodyLarge: TextStyle(fontFamily: 'OpenSans'),
              bodyMedium: TextStyle(fontFamily: 'OpenSans'),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.mediumImpact();

      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat.yMMMMd('fr_FR').format(picked);
      });

      _confettiController.forward().then((_) => _confettiController.reverse());
      _warningController.forward().then((_) => _warningController.reverse());
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    if (!_hasChanges) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _hasError = false;
      _errorMessage = '';
    });

    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Sauvegarder les nouvelles données localement (pour le cache)
      await prefs.setString(
        'numerology_fullName',
        _fullNameController.text.trim(),
      );
      await prefs.setString(
        'numerology_birthDate',
        _selectedDate!.toIso8601String(),
      );

      // Utiliser l'API pour mettre à jour le profil existant
      final apiService = ApiService();
      final numerologyApiService = NumerologyApiService(apiService);

      // Appel à updateProfile avec l'ID du profil
      final updatedProfile = await numerologyApiService.updateProfile(
        profileId: widget.profile.id!, // ← récupérer l'ID du profil
        userId: userId,
        birthDate: _selectedDate!,
        fullName: _fullNameController.text.trim(),
      );

      // Optionnel : rafraîchir le cache via le service de profil
      final profileApiService = NumerologyProfileApiService(
        numerologyApiService,
      );
      await profileApiService.refreshProfile(userId);

      HapticFeedback.heavyImpact();

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      HapticFeedback.vibrate();

      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isSubmitting = false;
      });
    }
  }

  Future<void> _confirmDiscardChanges() async {
    if (!_hasChanges) {
      Navigator.of(context).pop(false);
      return;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDiscardDialog(),
    );

    if (shouldDiscard == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Widget _buildDiscardDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9E7D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF9E7D),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'MODIFICATIONS NON ENREGISTRÉES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C1A3F),
                fontFamily: 'PlayfairDisplay',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vous avez des modifications en cours. Voulez-vous vraiment quitter sans enregistrer ?',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6D5D82),
                fontFamily: 'OpenSans',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CONTINUER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D8CAE),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9E7D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'QUITTER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFFAF7FC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7FC),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xFF2C1A3F),
              ),
            ),
            onPressed: _confirmDiscardChanges,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: const Text(
            'MODIFIER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B6B9E),
              fontFamily: 'OpenSans',
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // ========== ARRIÈRE-PLAN SACRÉ ANIMÉ ==========
            _buildSacredBackground(),

            // ========== PARTICULES ÉNERGÉTIQUES ==========
            _buildEnergyParticles(),

            // ========== CONTENU PRINCIPAL ==========
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ========== EN-TÊTE SPIRITUEL ==========
                      _buildSacredHeader(),

                      const SizedBox(height: 40),

                      // ========== INDICATEUR DE PROGRÈS ==========
                      _buildProgressIndicator(),

                      const SizedBox(height: 40),

                      // ========== BADGE MODIFICATION ==========
                      if (_hasChanges) _buildChangesBadge(),

                      const SizedBox(height: 24),

                      // ========== FORMULAIRES SACRÉS ==========
                      _buildSacredNameField(),

                      const SizedBox(height: 32),

                      _buildSacredDateField(),

                      const SizedBox(height: 40),

                      // ========== MESSAGE D'ERREUR ÉLÉGANT ==========
                      if (_hasError) _buildErrorCard(),

                      const SizedBox(height: 32),

                      // ========== BOUTON DE MISE À JOUR SUBLIME ==========
                      _buildUpdateButton(),

                      const SizedBox(height: 24),

                      // ========== LIEN D'INFORMATION ==========
                      _buildInfoLink(),

                      const SizedBox(height: 60),

                      // ========== FORMES SACRÉES ==========
                      _buildSacredFooter(),
                    ],
                  ),
                ),
              ),
            ),

            // ========== OVERLAY DE CHARGEMENT ==========
            if (_isSubmitting) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSacredBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              const Color(0xFFFAF7FC),
              const Color(0xFFF5F0FF),
              const Color(0xFFF0EAF8),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _floatingController.value * 5,
                _floatingController.value * 3,
              ),
              child: Opacity(
                opacity: 0.03,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/sacred_mandala.png'),
                      repeat: ImageRepeat.repeat,
                      scale: 3.0,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnergyParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return CustomPaint(
            painter: EnergyParticlesPainter(animation: _pulseController.value),
          );
        },
      ),
    );
  }

  Widget _buildSacredHeader() {
    return Column(
      children: [
        // Icône principale animée
        FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B6B9E), Color(0xFF5D8CAE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B6B9E).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF5D8CAE).withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_pulseController.value * 0.05),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_attributes_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Titre principal avec animation native
        AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
          child: const Text(
            'MODIFIEZ VOTRE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B6B9E),
              fontFamily: 'OpenSans',
              letterSpacing: 4,
            ),
          ),
        ),

        const SizedBox(height: 8),

        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF8B6B9E), Color(0xFF5D8CAE)],
          ).createShader(bounds),
          child: const Text(
            'PROFIL NUMÉROLOGIQUE',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'PlayfairDisplay',
              letterSpacing: 2,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // Sous-titre poétique
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Ajustez les vibrations cosmiques qui définissent votre essence spirituelle',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF6D5D82).withOpacity(0.9),
              fontFamily: 'OpenSans',
              height: 1.6,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // Badges sacrés
        Wrap(
          spacing: 12,
          children: [
            _buildSacredBadge('🔄', 'AJUSTEMENT'),
            _buildSacredBadge('✨', 'ÉVOLUTION'),
            _buildSacredBadge('🌙', 'HARMONIE'),
          ],
        ),
      ],
    );
  }

  Widget _buildSacredBadge(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF8B6B9E).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5D8CAE),
              fontFamily: 'OpenSans',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESSION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6D5D82).withOpacity(0.8),
                fontFamily: 'OpenSans',
                letterSpacing: 1,
              ),
            ),
            Text(
              '${(_formProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8B6B9E),
                fontFamily: 'OpenSans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _formProgress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE5E0F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(_formProgress),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return const Color(0xFF8B6B9E);
    if (progress < 0.7) return const Color(0xFF5D8CAE);
    return const Color(0xFFF6C667);
  }

  Widget _buildChangesBadge() {
    return AnimatedBuilder(
      animation: _warningController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_warningController.value * 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9E7D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFFFF9E7D).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF9E7D),
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'MODIFICATIONS EN COURS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF9E7D),
                    fontFamily: 'OpenSans',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSacredNameField() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(-20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B6B9E).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -10,
            ),
            if (_fullNameFocusNode.hasFocus)
              BoxShadow(
                color: const Color(0xFF8B6B9E).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _fullNameFocusNode.hasFocus
                          ? const Color(0xFF8B6B9E)
                          : const Color(0xFF8B6B9E).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: _fullNameFocusNode.hasFocus
                          ? Colors.white
                          : const Color(0xFF8B6B9E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'NOM COMPLET',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _fullNameFocusNode.hasFocus
                          ? const Color(0xFF8B6B9E)
                          : const Color(0xFF2C1A3F),
                      fontFamily: 'OpenSans',
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _fullNameController,
              focusNode: _fullNameFocusNode,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom complet est essentiel';
                }
                if (value.trim().split(' ').length < 2) {
                  return 'Prénom et nom, séparés par un espace';
                }
                return null;
              },
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2C1A3F),
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Jean Dupont',
                hintStyle: TextStyle(
                  color: const Color(0xFFA5A1B0).withOpacity(0.7),
                  fontFamily: 'OpenSans',
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B6B9E),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                suffixIcon: _fullNameController.text.isNotEmpty
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: IconButton(
                          icon: Icon(
                            _fullNameController.text != _originalFullName
                                ? Icons.edit
                                : Icons.check_circle,
                            color: _fullNameController.text != _originalFullName
                                ? const Color(0xFFFF9E7D)
                                : const Color(0xFF8B6B9E),
                          ),
                          onPressed: () {},
                        ),
                      )
                    : null,
              ),
              onFieldSubmitted: (_) => _birthDateFocusNode.requestFocus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSacredDateField() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D8CAE).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -10,
            ),
            if (_birthDateFocusNode.hasFocus)
              BoxShadow(
                color: const Color(0xFF5D8CAE).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _birthDateFocusNode.hasFocus
                          ? const Color(0xFF5D8CAE)
                          : const Color(0xFF5D8CAE).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cake_rounded,
                      color: _birthDateFocusNode.hasFocus
                          ? Colors.white
                          : const Color(0xFF5D8CAE),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'DATE DE NAISSANCE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _birthDateFocusNode.hasFocus
                          ? const Color(0xFF5D8CAE)
                          : const Color(0xFF2C1A3F),
                      fontFamily: 'OpenSans',
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _birthDateController,
              focusNode: _birthDateFocusNode,
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La date de naissance est requise';
                }
                return null;
              },
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2C1A3F),
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Sélectionnez votre date',
                hintStyle: TextStyle(
                  color: const Color(0xFFA5A1B0).withOpacity(0.7),
                  fontFamily: 'OpenSans',
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF5D8CAE),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                suffixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _selectedDate != _originalBirthDate
                        ? const Color(0xFFFF9E7D).withOpacity(0.1)
                        : (_selectedDate != null
                              ? const Color(0xFF5D8CAE).withOpacity(0.1)
                              : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _selectDate(context),
                    icon: Icon(
                      _selectedDate != _originalBirthDate
                          ? Icons.edit_calendar_rounded
                          : (_selectedDate != null
                                ? Icons.calendar_month_rounded
                                : Icons.calendar_today_rounded),
                      color: _selectedDate != _originalBirthDate
                          ? const Color(0xFFFF9E7D)
                          : (_selectedDate != null
                                ? const Color(0xFF5D8CAE)
                                : const Color(0xFFA5A1B0)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ERREUR DE MODIFICATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                    fontFamily: 'OpenSans',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C1A3F),
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

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        gradient: _hasChanges
            ? const LinearGradient(
                colors: [Color(0xFFFF9E7D), Color(0xFF8B6B9E)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFC0C0C0), Color(0xFFA0A0A0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: _hasChanges
            ? [
                BoxShadow(
                  color: const Color(0xFFFF9E7D).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF8B6B9E).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting || !_hasChanges ? null : _submitForm,
          borderRadius: BorderRadius.circular(35),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: _isSubmitting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.5),
                                  Colors.white,
                                ],
                                stops: [
                                  _shimmerController.value - 0.5,
                                  _shimmerController.value,
                                  _shimmerController.value + 0.5,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'MISE À JOUR EN COURS...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'OpenSans',
                                  letterSpacing: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasChanges
                              ? Icons.save_rounded
                              : Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _hasChanges
                              ? 'METTRE À JOUR MON PROFIL'
                              : 'AUCUNE MODIFICATION',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                            letterSpacing: 2,
                          ),
                        ),
                        if (_hasChanges) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoLink() {
    return TextButton(
      onPressed: _showInfoDialog,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF5D8CAE).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Color(0xFF5D8CAE),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'IMPACT DES MODIFICATIONS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5D8CAE),
              fontFamily: 'OpenSans',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: Color(0xFF5D8CAE),
          ),
        ],
      ),
    );
  }

  Widget _buildSacredFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSacredSymbol('☉', const Color(0xFF8B6B9E)),
            const SizedBox(width: 20),
            _buildSacredSymbol('☽', const Color(0xFF5D8CAE)),
            const SizedBox(width: 20),
            _buildSacredSymbol('♁', const Color(0xFFF6C667)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Chaque modification ajuste votre vibration cosmique',
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF6D5D82).withOpacity(0.7),
            fontFamily: 'OpenSans',
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSacredSymbol(String symbol, Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1 * (1 + _pulseController.value * 0.5)),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Center(
            child: Text(symbol, style: TextStyle(fontSize: 20, color: color)),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.network(
                  'https://assets5.lottiefiles.com/packages/lf20_x1gjdldd.json',
                  width: 120,
                  height: 120,
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
                const SizedBox(height: 24),
                const Text(
                  'MISE À JOUR DE VOTRE PROFIL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C1A3F),
                    fontFamily: 'OpenSans',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Réalignement des énergies cosmiques...',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF6D5D82).withOpacity(0.9),
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: const _EditInfoDialog(),
        );
      },
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _confettiController.dispose();
    _warningController.dispose();
    _fullNameFocusNode.dispose();
    _birthDateFocusNode.dispose();
    _fullNameController.dispose();
    _birthDateController.dispose();
    _fullNameController.removeListener(_updateProgress);
    _birthDateController.removeListener(_updateProgress);
    _fullNameController.removeListener(_detectChanges);
    _birthDateController.removeListener(_detectChanges);
    super.dispose();
  }
}

// ========== DIALOGUE D'INFORMATION POUR MODIFICATION ==========

class _EditInfoDialog extends StatelessWidget {
  const _EditInfoDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9E7D), Color(0xFF8B6B9E)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_attributes_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'IMPACT DES MODIFICATIONS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C1A3F),
                        fontFamily: 'PlayfairDisplay',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF6D5D82),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7FC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E0F0), width: 1.5),
              ),
              child: Column(
                children: [
                  _buildInfoItem(
                    '🔄 Nouvelles données',
                    'Tous vos nombres clés sont recalculés',
                    const Color(0xFFFF9E7D),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    '✨ Énergie renouvelée',
                    'Votre chemin de vie s\'ajuste à votre nouvelle vibration',
                    const Color(0xFF8B6B9E),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    '📅 Cycles actualisés',
                    'Année, mois et jour personnels sont mis à jour',
                    const Color(0xFF5D8CAE),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF9E7D).withOpacity(0.1),
                    const Color(0xFF8B6B9E).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Modifier vos informations personnelles recalcule l\'intégralité de votre profil numérologique pour refléter avec précision votre nouvelle vibration cosmique.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A3863),
                  fontFamily: 'OpenSans',
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
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
                  elevation: 0,
                ),
                child: const Text(
                  'J\'AI COMPRIS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'OpenSans',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'OpenSans',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6D5D82),
                  fontFamily: 'OpenSans',
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========== PAINTER DE PARTICULES ÉNERGÉTIQUES (réutilisé) ==========

class EnergyParticlesPainter extends CustomPainter {
  final double animation;

  EnergyParticlesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B6B9E).withOpacity(0.1 * (1 - animation))
      ..style = PaintingStyle.fill;

    // Dessiner des particules aléatoires
    for (int i = 0; i < 30; i++) {
      final x = (i * 37) % size.width;
      final y = ((i * 73) + animation * 50) % size.height;

      paint.color = const Color(0xFF8B6B9E).withOpacity(0.05 * (1 - animation));
      canvas.drawCircle(Offset(x, y), 2 + animation * 2, paint);

      paint.color = const Color(0xFF5D8CAE).withOpacity(0.03 * (1 - animation));
      canvas.drawCircle(Offset(x + 20, y - 10), 1 + animation, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
