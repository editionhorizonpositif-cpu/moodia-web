import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../services/subscription_api_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionApiService _apiService;
  final AuthService _authService;
  Subscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;

  // État de paiement
  bool _isPaymentProcessing = false;
  String? _currentOrderId;
  Timer? _paymentCheckTimer;

  // Cache local premium
  bool _cachedPremium = false;

  // Clés SharedPreferences
  static const String _premiumKey = 'user_premium';
  static const String _subscriptionDataKey = 'cached_subscription';
  bool _disposed = false;
  StreamSubscription? _subscriptionStreamSubscription;

  // ✅ CONSTRUCTEUR
  SubscriptionProvider({
    required ApiService apiService,
    required AuthService authService,
  }) : _apiService = SubscriptionApiService(apiService),
       _authService = authService {
    _init();
  }

  // Getters
  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✅ Getter premium avec cache
  bool get isPremium => _currentSubscription?.isActive ?? _cachedPremium;

  bool get isPaymentProcessing => _isPaymentProcessing;
  String? get currentOrderId => _currentOrderId;

  Future<void> _init() async {
    // Écouter les changements du service
    _subscriptionStreamSubscription = _apiService.subscriptionStream.listen((
      subscription,
    ) {
      if (_disposed) return;
      _currentSubscription = subscription;
      _updatePremiumCache(subscription?.isActive ?? false);
      _cacheSubscriptionData(subscription);
      if (!_disposed) notifyListeners();
    });

    // Écouter les changements d'authentification
    _authService.addListener(_onAuthChanged);

    // Charger l'abonnement actuel
    await loadCurrentSubscription();
  }

  void _onAuthChanged() {
    if (_disposed) return;
    if (!_authService.isAuthenticated) {
      // Utilisateur déconnecté, réinitialiser
      _currentSubscription = null;
      _cachedPremium = false;
      _savePremiumToPrefs(false);
      if (!_disposed) notifyListeners();
    }
  }

  // ✅ Mettre à jour le cache premium et synchroniser avec AuthService
  Future<void> _updatePremiumCache(bool isPremium) async {
    _cachedPremium = isPremium;
    await _savePremiumToPrefs(isPremium);
    try {
      await _authService.syncPremiumStatus(isPremium);
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur synchronisation AuthService: $e');
    }
    if (!_disposed) notifyListeners();
  }

  // ✅ Sauvegarder premium dans SharedPreferences
  Future<void> _savePremiumToPrefs(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, isPremium);
      if (kDebugMode) print('✅ Premium sauvegardé: $isPremium');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sauvegarde premium: $e');
    }
  }

  // ✅ Charger premium depuis SharedPreferences
  Future<void> _loadPremiumFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedPremium = prefs.getBool(_premiumKey) ?? false;
      if (kDebugMode) print('📦 Premium chargé: $_cachedPremium');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement premium: $e');
    }
  }

  // ✅ Sauvegarder les données d'abonnement dans le cache
  Future<void> _cacheSubscriptionData(Subscription? subscription) async {
    if (subscription == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionJson = jsonEncode(subscription.toJson());
      await prefs.setString(_subscriptionDataKey, subscriptionJson);
      if (kDebugMode) print('✅ Données abonnement mises en cache');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur cache abonnement: $e');
    }
  }

  // ✅ Charger les données d'abonnement depuis le cache
  Future<Subscription?> _loadSubscriptionFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionJson = prefs.getString(_subscriptionDataKey);

      if (subscriptionJson != null) {
        final Map<String, dynamic> jsonMap = jsonDecode(subscriptionJson);
        final subscription = Subscription.fromJson(jsonMap);
        if (kDebugMode) print('✅ Abonnement chargé depuis cache');
        return subscription;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur chargement cache abonnement: $e');
    }
    return null;
  }

  // ✅ NOUVELLE MÉTHODE: loadCachedSubscription()
  /// Charge les données d'abonnement depuis le cache local
  /// Utilisé en mode hors-ligne ou quand le backend est indisponible
  Future<void> loadCachedSubscription() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      if (kDebugMode) print('📦 Chargement abonnement depuis cache...');

      final cachedSubscription = await _loadSubscriptionFromCache();

      if (cachedSubscription != null) {
        _currentSubscription = cachedSubscription;
        await _updatePremiumCache(cachedSubscription.isActive);
        if (kDebugMode)
          print(
            '✅ Abonnement chargé depuis cache - Premium: ${cachedSubscription.isActive}',
          );
      } else {
        await _loadPremiumFromPrefs();
        if (kDebugMode)
          print(
            'ℹ️ Aucun abonnement en cache, utilisation du statut premium: $_cachedPremium',
          );
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('❌ Erreur loadCachedSubscription: $e');
      await _loadPremiumFromPrefs();
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  // ✅ Vérification statut paiement
  Future<bool> checkPaymentStatus({
    required String orderId,
    required SubscriptionPeriod period,
  }) async {
    if (_disposed) return false;
    try {
      _isPaymentProcessing = true;
      if (!_disposed) notifyListeners();

      final userId = _authService.currentUser?.id;
      if (userId == null) return false;

      final subscription = await _apiService.confirmPayPalSubscription(
        userId: userId,
        period: period,
      );

      if (subscription.isActive) {
        _currentSubscription = subscription;
        await _updatePremiumCache(true);
        await _cacheSubscriptionData(subscription);
        if (!_disposed) notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur checkPaymentStatus: $e');
      return false;
    } finally {
      _isPaymentProcessing = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadCurrentSubscription() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      final userId = _authService.currentUser?.id;

      if (userId != null) {
        _currentSubscription = await _apiService.getLastSubscription(userId);
        await _updatePremiumCache(_currentSubscription?.isActive ?? false);
        await _cacheSubscriptionData(_currentSubscription);
      } else {
        await _loadPremiumFromPrefs();
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('❌ Erreur loadCurrentSubscription: $e');
      await loadCachedSubscription();
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<String?> initiatePayPalPayment({
    required SubscriptionPeriod period,
    required double price,
  }) async {
    if (_disposed) return null;
    _isPaymentProcessing = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      final userId = _authService.currentUser?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final order = await _apiService.createPayPalOrder(
        userId: userId,
        period: period,
        price: price.toStringAsFixed(2),
      );

      _currentOrderId = order.id;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_order_id', order.id);
      await prefs.setString('pending_order_period', period.toString());

      return order.approveUrl;
    } catch (e) {
      _error = e.toString();
      _isPaymentProcessing = false;
      if (!_disposed) notifyListeners();
      return null;
    }
  }

  // ✅ Vérification après retour PayPal
  Future<bool> verifyPaymentAfterReturn({
    required String orderId,
    required SubscriptionPeriod period,
  }) async {
    if (_disposed) return false;
    try {
      _isPaymentProcessing = true;
      if (!_disposed) notifyListeners();

      final userId = _authService.currentUser?.id;
      if (userId == null) return false;

      await Future.delayed(const Duration(seconds: 2));

      final subscription = await _apiService.getLastSubscription(userId);

      if (subscription != null && subscription.isActive) {
        _currentSubscription = subscription;
        await _updatePremiumCache(true);
        await _cacheSubscriptionData(subscription);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_order_id');
        await prefs.remove('pending_order_period');

        if (!_disposed) notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur verifyPaymentAfterReturn: $e');
      return false;
    } finally {
      _isPaymentProcessing = false;
      if (!_disposed) notifyListeners();
    }
  }

  void markPayPalReturned(String orderId) {
    _currentOrderId = orderId;
  }

  Future<void> cancelPayPalPayment() async {
    _paymentCheckTimer?.cancel();
    _isPaymentProcessing = false;
    _currentOrderId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_order_id');
    await prefs.remove('pending_order_period');

    if (!_disposed) notifyListeners();
  }

  Future<void> cancelSubscription() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    if (!_disposed) notifyListeners();

    try {
      final userId = _authService.currentUser?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      _currentSubscription = await _apiService.cancelSubscription(
        userId,
        'PayPal',
      );

      await _updatePremiumCache(false);
      await _cacheSubscriptionData(_currentSubscription);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> refreshSubscription() async {
    await loadCurrentSubscription();
  }

  // ✅ Nettoyer le cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subscriptionDataKey);
      await prefs.remove(_premiumKey);
      _currentSubscription = null;
      _cachedPremium = false;
      if (!_disposed) notifyListeners();
      if (kDebugMode) print('✅ Cache abonnement nettoyé');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur nettoyage cache: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _paymentCheckTimer?.cancel();
    _subscriptionStreamSubscription?.cancel();
    _authService.removeListener(_onAuthChanged);
    _apiService.dispose();
    super.dispose();
  }
}
