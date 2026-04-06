import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import 'api_service.dart';

class SubscriptionApiService {
  final ApiService _apiService;
  static const String _baseEndpoint = 'subscription';
  static const String _paypalEndpoint = 'paypal';

  // Événements pour notifier les changements d'abonnement
  final _subscriptionController = StreamController<Subscription?>.broadcast();
  Stream<Subscription?> get subscriptionStream =>
      _subscriptionController.stream;

  Subscription? _currentSubscription;
  Subscription? get currentSubscription => _currentSubscription;

  SubscriptionApiService(this._apiService);

  Future<void> dispose() {
    return _subscriptionController.close();
  }

  Future<Map<String, String>> _getHeadersWithUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        if (kDebugMode) print('⚠️ UserId non trouvé dans SharedPreferences');
        return await _apiService.getHeaders();
      }

      if (kDebugMode) print('👤 Utilisation du userId: $userId');
      return await _apiService.getHeadersWithUserId(userId);
    } catch (e) {
      if (kDebugMode) print('❌ Erreur _getHeadersWithUserId: $e');
      return await _apiService.getHeaders();
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      if (response.body.isEmpty) return 'Erreur inconnue';

      final jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ??
            jsonBody['error'] ??
            jsonBody['detail'] ??
            'Erreur serveur (${response.statusCode})';
      }
      return 'Erreur: ${response.statusCode}';
    } catch (e) {
      return 'Erreur de communication';
    }
  }

  Future<PayPalOrderResponse> createPayPalOrder({
    required int userId,
    required SubscriptionPeriod period,
    required String price,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    try {
      if (kDebugMode) {
        print('💰 CRÉATION COMMANDE PAYPAL');
        print('📊 UserId: $userId');
        print('📊 Period: ${period.displayName}');
        print('📊 Price: $price');
      }

      final url =
          Uri.parse(
            '${ApiService.baseUrl}/$_paypalEndpoint/create-order',
          ).replace(
            queryParameters: {
              'userId': userId.toString(),
              'period': period.toApiString(),
              'price': price,
            },
          );

      final headers = await _getHeadersWithUserId();

      if (kDebugMode) {
        print('📤 GET $url');
        if (headers.containsKey('X-User-Id')) {
          print('👤 X-User-Id envoyé: ${headers['X-User-Id']}');
        }
      }

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('📥 Status: ${response.statusCode}');
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception(
          'Erreur création commande (${response.statusCode}): $errorMsg',
        );
      }

      // La réponse est l'URL d'approbation
      final approveUrl = utf8.decode(response.bodyBytes);

      // Extraire l'ID de commande de l'URL
      final orderId = _extractOrderIdFromUrl(approveUrl);

      return PayPalOrderResponse(
        id: orderId ?? 'unknown',
        status: 'CREATED',
        approveUrl: approveUrl,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur createPayPalOrder: $e');
      rethrow;
    }
  }

  String? _extractOrderIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // PayPal utilise souvent 'token' comme paramètre pour l'ID de commande
      return uri.queryParameters['token'] ??
          uri.queryParameters['orderId'] ??
          uri.pathSegments.lastWhere(
            (segment) => segment.isNotEmpty && segment.length > 10,
            orElse: () => '',
          );
    } catch (e) {
      return null;
    }
  }

  Future<Subscription> confirmPayPalSubscription({
    required int userId,
    required SubscriptionPeriod period,
  }) async {
    try {
      if (kDebugMode) {
        print('✅ CONFIRMATION ABONNEMENT PAYPAL');
        print('📊 UserId: $userId');
        print('📊 Period: ${period.displayName}');
      }

      final url = Uri.parse('${ApiService.baseUrl}/$_paypalEndpoint/confirm')
          .replace(
            queryParameters: {
              'userId': userId.toString(),
              'period': period.toApiString(),
            },
          );

      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception(
          'Erreur confirmation (${response.statusCode}): $errorMsg',
        );
      }

      // Récupérer la dernière souscription pour confirmer
      final subscription = await getLastSubscription(userId);

      // Mettre à jour le cache et notifier
      _currentSubscription = subscription;
      _subscriptionController.add(subscription);

      // Mettre à jour le statut premium dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('premium', true);
      await prefs.setString('premium_since', DateTime.now().toIso8601String());

      return subscription!;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur confirmPayPalSubscription: $e');
      rethrow;
    }
  }

  Future<List<Subscription>> getUserSubscriptions(int userId) async {
    try {
      if (kDebugMode) print('📋 RÉCUPÉRATION ABONNEMENTS: $userId');

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/by_user/$userId',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception(
          'Erreur récupération (${response.statusCode}): $errorMsg',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      if (jsonResponse is List) {
        final subscriptions = jsonResponse
            .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
            .toList();

        // Mettre à jour l'abonnement actuel
        if (subscriptions.isNotEmpty) {
          _currentSubscription = subscriptions.last;
          _subscriptionController.add(_currentSubscription);
        }

        return subscriptions;
      }

      return [];
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getUserSubscriptions: $e');
      rethrow;
    }
  }

  Future<Subscription?> getLastSubscription(int userId) async {
    try {
      if (kDebugMode) print('📋 DERNIER ABONNEMENT: $userId');

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/last/by_user/$userId',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception(
          'Erreur récupération (${response.statusCode}): $errorMsg',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final subscription = Subscription.fromJson(jsonResponse);

      _currentSubscription = subscription;
      _subscriptionController.add(subscription);

      return subscription;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getLastSubscription: $e');
      return null;
    }
  }

  Future<Subscription> cancelSubscription(int userId, String provider) async {
    try {
      if (kDebugMode) print('🚫 ANNULATION ABONNEMENT: $userId');

      final url = Uri.parse(
        '${ApiService.baseUrl}/$_baseEndpoint/cancel-subscription/$userId/$provider',
      );
      final headers = await _getHeadersWithUserId();

      final response = await http.post(url, headers: headers);

      if (response.statusCode >= 400) {
        final errorMsg = _parseErrorMessage(response);
        throw Exception(
          'Erreur annulation (${response.statusCode}): $errorMsg',
        );
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final subscription = Subscription.fromJson(jsonResponse);

      _currentSubscription = subscription;
      _subscriptionController.add(subscription);

      return subscription;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur cancelSubscription: $e');
      rethrow;
    }
  }

  Future<bool> checkPremiumStatus(int userId) async {
    try {
      final subscription = await getLastSubscription(userId);
      final isPremium = subscription?.isActive ?? false;

      // Mettre à jour SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('premium', isPremium);

      return isPremium;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur checkPremiumStatus: $e');
      return false;
    }
  }
}
