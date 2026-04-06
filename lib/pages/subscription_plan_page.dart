import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import '../services/auth_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_dialog.dart';
import '../widgets/success_snackbar.dart';
import '../theme/app_theme.dart';

class SubscriptionPlanPage extends StatefulWidget {
  const SubscriptionPlanPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  Timer? _verificationTimer;
  bool _isVerifying = false;
  String? _currentOrderId;
  SubscriptionPeriod? _currentPeriod;
  int _verificationAttempts = 0;
  static const int _maxVerificationAttempts = 30;

  // Prix
  static const double monthlyPrice = 4.99;
  static const double yearlyPrice = 49.99;
  static const double yearlyMonthlyEquivalent = 4.17;
  static const double yearlySavings = 16;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndPendingPayment();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verificationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isVerifying) {
      _checkPaymentStatus();
    }
  }

  Future<void> _checkAuthAndPendingPayment() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.isAuthenticated || authService.currentUser == null) {
      _showNotAuthenticatedDialog();
      return;
    }

    await _checkPendingPayment();
  }

  void _showNotAuthenticatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔒 Non connecté'),
        content: const Text(
          'Vous devez être connecté pour accéder aux abonnements.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPendingPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingOrderId = prefs.getString('pending_order_id');
    final pendingPeriodStr = prefs.getString('pending_order_period');

    if (pendingOrderId != null && pendingPeriodStr != null && mounted) {
      _currentOrderId = pendingOrderId;
      _currentPeriod = pendingPeriodStr == 'month'
          ? SubscriptionPeriod.month
          : SubscriptionPeriod.year;

      _isVerifying = true;
      _showPaymentProcessingDialog();
      _startPaymentVerification();
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_currentOrderId == null || _currentPeriod == null) return;

    final provider = Provider.of<SubscriptionProvider>(context, listen: false);

    try {
      final success = await provider.checkPaymentStatus(
        orderId: _currentOrderId!,
        period: _currentPeriod!,
      );

      if (success && mounted) {
        _handlePaymentSuccess();
      }
    } catch (e) {
      debugPrint('Erreur vérification statut: $e');
    }
  }

  Future<void> _initiatePayment(SubscriptionPeriod period, double price) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final provider = Provider.of<SubscriptionProvider>(context, listen: false);

    if (!authService.isAuthenticated || authService.currentUser == null) {
      _showNotAuthenticatedDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final approvalUrl = await provider.initiatePayPalPayment(
        period: period,
        price: price,
      );

      if (approvalUrl != null && mounted) {
        final uri = Uri.parse(approvalUrl);
        final orderId = _extractOrderId(approvalUrl);

        if (await canLaunchUrl(uri)) {
          _verificationAttempts = 0;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_order_id', orderId ?? '');
          await prefs.setString('pending_order_period', period.toString());

          _currentOrderId = orderId;
          _currentPeriod = period;

          await launchUrl(uri, mode: LaunchMode.externalApplication);

          _isVerifying = true;

          if (mounted) {
            _showPaymentProcessingDialog();
            _startPaymentVerification();
          }
        } else {
          throw Exception('Impossible d\'ouvrir PayPal');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(
          context: context,
          title: 'Erreur de paiement',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _extractOrderId(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['token'];
    } catch (e) {
      return null;
    }
  }

  void _showPaymentProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Vérification du paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment, color: Colors.blue, size: 30),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Votre paiement est en cours de vérification.\n'
                'Cette opération peut prendre quelques instants.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                'Tentative $_verificationAttempts/$_maxVerificationAttempts',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _verificationTimer?.cancel();
                _isVerifying = false;

                final provider = Provider.of<SubscriptionProvider>(
                  context,
                  listen: false,
                );
                await provider.cancelPayPalPayment();

                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('pending_order_id');
                await prefs.remove('pending_order_period');

                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Vérifier plus tard'),
            ),
          ],
        ),
      ),
    );
  }

  void _startPaymentVerification() {
    _verificationAttempts = 0;

    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      _verificationAttempts++;

      if (!mounted) {
        timer.cancel();
        return;
      }

      final provider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );

      await provider.refreshSubscription();

      if (provider.isPremium) {
        timer.cancel();
        _isVerifying = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_order_id');
        await prefs.remove('pending_order_period');

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _showSuccessDialog();
        }
        return;
      }

      if (_verificationAttempts >= _maxVerificationAttempts) {
        timer.cancel();
        _isVerifying = false;

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _showPaymentTimeoutDialog();
        }
      }
    });
  }

  void _handlePaymentSuccess() {
    _verificationTimer?.cancel();
    _isVerifying = false;

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _showSuccessDialog();
    }
  }

  void _showPaymentTimeoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ Vérification en attente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'La vérification prend plus de temps que prévu.\n'
              'Votre abonnement devrait être actif sous peu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Voir mon profil'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Félicitations !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Votre abonnement Premium a été activé avec succès !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous avez maintenant accès à tous les contenus exclusifs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accéder au contenu Premium'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final provider = Provider.of<SubscriptionProvider>(context);

    // AuthService n'est utilisé que dans les callbacks, pas dans le build
    // Donc on peut le retirer d'ici si on veut

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LoadingOverlay(
        isLoading: _isLoading || provider.isPaymentProcessing,
        message: provider.isPaymentProcessing
            ? 'Traitement du paiement...'
            : 'Chargement...',
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isLargeScreen),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildHeader(),
                      if (provider.isPremium)
                        _buildActiveSubscriptionCard(
                          provider.currentSubscription,
                        )
                      else
                        _buildPlans(isLargeScreen),
                      _buildBenefitsSection(),
                      _buildFAQSection(),
                      _buildSecurityFooter(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isLargeScreen) {
    return SliverAppBar(
      expandedHeight: isLargeScreen ? 240 : 180,
      pinned: true,
      floating: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "Moodia Premium",
          style: TextStyle(
            fontSize: isLargeScreen ? 24 : 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/pattern.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container();
                    },
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Élevez votre pratique",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
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

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Déverrouillez votre plein potentiel",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  "Accédez à tous les contenus exclusifs et outils avancés",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(Subscription? subscription) {
    if (subscription == null) return const SizedBox();

    final daysRemaining = subscription.daysRemaining;
    final isExpiringSoon = daysRemaining <= 7;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Abonnement actif",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Se termine le ${_formatDate(subscription.endDate)}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: subscription.daysRemaining / 365,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$daysRemaining jours restants",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isExpiringSoon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Bientôt expiré",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              SuccessSnackbar.show(
                context: context,
                message: "Fonctionnalité bientôt disponible",
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text("Gérer mon abonnement"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildPlans(bool isLargeScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (isLargeScreen)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFreePlanCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildMonthlyPlanCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildYearlyPlanCard()),
              ],
            )
          else
            Column(
              children: [
                _buildFreePlanCard(),
                const SizedBox(height: 20),
                _buildMonthlyPlanCard(),
                const SizedBox(height: 20),
                _buildYearlyPlanCard(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFreePlanCard() {
    return _buildPlanCard(
      title: "Gratuit",
      price: "0 €",
      color: Colors.grey.shade600,
      icon: Icons.lock_open_rounded,
      features: [
        "5 méditations guidées",
        "Numérologie de base",
        "Journal quotidien",
        "Support communautaire",
      ],
      onTap: () {
        Navigator.pushReplacementNamed(context, '/home');
      },
      buttonText: "Continuer gratuitement",
    );
  }

  Widget _buildMonthlyPlanCard() {
    return _buildPlanCard(
      title: "Premium Mensuel",
      price: "$monthlyPrice €",
      subPrice: "par mois",
      color: AppTheme.primaryColor,
      icon: Icons.star_rounded,
      features: [
        "Accès illimité à toutes les méditations",
        "Nouvelles séances chaque semaine",
        "Musique HD & sons thérapeutiques",
        "Statistiques détaillées",
        "🔮 Suivi numérologique personnalisé",
        "📅 Méditations adaptées à votre vibration",
        "Support prioritaire",
        "Contenu hors ligne",
      ],
      onTap: () => _initiatePayment(SubscriptionPeriod.month, monthlyPrice),
      buttonText: "S'abonner",
      isRecommended: true,
    );
  }

  Widget _buildYearlyPlanCard() {
    final savings = ((monthlyPrice * 12) - yearlyPrice).toStringAsFixed(2);
    return _buildPlanCard(
      title: "Premium Annuel",
      price: "$yearlyPrice €",
      subPrice: "(${yearlyMonthlyEquivalent.toStringAsFixed(2)}€/mois)",
      color: AppTheme.secondaryColor,
      icon: Icons.workspace_premium_rounded,
      features: [
        "Tous les avantages du Premium Mensuel",
        "Économisez $savings€ par an",
        "Accès prioritaire aux nouveautés",
        "🔮 Analyse annuelle complète",
        "📈 Conseils personnalisés mensuels",
        "2 sessions de coaching par mois",
        "Ateliers en direct exclusifs",
        "Certificat de progression",
      ],
      badge: "ÉCONOMISEZ ${yearlySavings.toStringAsFixed(0)}%",
      onTap: () => _initiatePayment(SubscriptionPeriod.year, yearlyPrice),
      buttonText: "S'abonner",
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    String? subPrice,
    required Color color,
    required IconData icon,
    required List<String> features,
    required VoidCallback onTap,
    String buttonText = "Choisir",
    bool isRecommended = false,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          if (isRecommended)
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 25,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
        ],
        border: Border.all(
          color: isRecommended ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subPrice != null)
                            Text(
                              subPrice,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ce plan inclus :",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onTap,
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (isRecommended)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: const Text(
                  "⭐ RECOMMANDÉ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      {
        'icon': Icons.psychology_rounded,
        'title': 'Méditations exclusives',
        'desc': 'Accédez à une bibliothèque complète de méditations guidées',
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'title': 'Numérologie avancée',
        'desc': 'Analyses détaillées et conseils personnalisés',
      },
      {
        'icon': Icons.insights_rounded,
        'title': 'Suivi de progression',
        'desc': 'Statistiques détaillées sur votre évolution',
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Support prioritaire',
        'desc': 'Assistance dédiée sous 24h',
      },
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              "Pourquoi passer Premium ?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: benefits.length,
            itemBuilder: (context, index) {
              final benefit = benefits[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        benefit['icon'] as IconData,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      benefit['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      benefit['desc'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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

  Widget _buildFAQSection() {
    final faqs = [
      {
        'q': 'Puis-je annuler à tout moment ?',
        'a':
            'Oui, vous pouvez annuler votre abonnement à tout moment depuis les paramètres. L\'accès reste actif jusqu\'à la fin de la période payée.',
      },
      {
        'q': 'Comment fonctionne le paiement ?',
        'a':
            'Nous utilisons PayPal pour des paiements 100% sécurisés. Vos informations bancaires ne sont jamais stockées sur nos serveurs.',
      },
      {
        'q': 'Y a-t-il un engagement ?',
        'a':
            'Aucun engagement ! Vous pouvez résilier quand vous le souhaitez, sans frais supplémentaires.',
      },
      {
        'q': 'Puis-je utiliser l\'app sur plusieurs appareils ?',
        'a':
            'Oui, votre compte fonctionne sur tous vos appareils (mobile, tablette, ordinateur).',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline, color: Colors.blue),
          ),
          title: const Text(
            "Questions fréquentes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          children: faqs.map((faq) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq['q']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    faq['a']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  if (faq != faqs.last) const Divider(height: 24),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            "Paiement 100% sécurisé par PayPal",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
