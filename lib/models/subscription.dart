import 'package:flutter/material.dart';

enum SubscriptionStatus {
  active,
  pending,
  cancelled,
  expired,
  failed;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Actif';
      case SubscriptionStatus.pending:
        return 'En attente';
      case SubscriptionStatus.cancelled:
        return 'Annulé';
      case SubscriptionStatus.expired:
        return 'Expiré';
      case SubscriptionStatus.failed:
        return 'Échoué';
    }
  }

  Color get color {
    switch (this) {
      case SubscriptionStatus.active:
        return const Color(0xFF10B981);
      case SubscriptionStatus.pending:
        return const Color(0xFFF59E0B);
      case SubscriptionStatus.cancelled:
        return const Color(0xFFEF4444);
      case SubscriptionStatus.expired:
        return const Color(0xFF6B7280);
      case SubscriptionStatus.failed:
        return const Color(0xFFDC2626);
    }
  }

  // Conversion depuis String
  static SubscriptionStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'PENDING':
        return SubscriptionStatus.pending;
      case 'CANCELLED':
        return SubscriptionStatus.cancelled;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      case 'FAILED':
        return SubscriptionStatus.failed;
      default:
        return SubscriptionStatus.pending;
    }
  }

  // Conversion vers String pour API
  String toApiString() {
    switch (this) {
      case SubscriptionStatus.active:
        return 'ACTIVE';
      case SubscriptionStatus.pending:
        return 'PENDING';
      case SubscriptionStatus.cancelled:
        return 'CANCELLED';
      case SubscriptionStatus.expired:
        return 'EXPIRED';
      case SubscriptionStatus.failed:
        return 'FAILED';
    }
  }
}

enum SubscriptionPeriod {
  month,
  year;

  String get displayName {
    switch (this) {
      case SubscriptionPeriod.month:
        return 'Mensuel';
      case SubscriptionPeriod.year:
        return 'Annuel';
    }
  }

  int get months {
    switch (this) {
      case SubscriptionPeriod.month:
        return 1;
      case SubscriptionPeriod.year:
        return 12;
    }
  }

  // Conversion depuis String
  static SubscriptionPeriod fromString(String period) {
    switch (period.toLowerCase()) {
      case 'month':
        return SubscriptionPeriod.month;
      case 'year':
        return SubscriptionPeriod.year;
      default:
        return SubscriptionPeriod.month;
    }
  }

  // Conversion vers String pour API
  String toApiString() {
    switch (this) {
      case SubscriptionPeriod.month:
        return 'month';
      case SubscriptionPeriod.year:
        return 'year';
    }
  }
}

class Subscription {
  final int? id;
  final int? userId;
  final SubscriptionPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final String provider;
  final DateTime? createdAt;

  Subscription({
    this.id,
    this.userId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.provider,
    this.createdAt,
  });

  // Factory constructor pour créer depuis JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      period: SubscriptionPeriod.fromString(json['period'] ?? 'month'),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      status: SubscriptionStatus.fromString(json['status'] ?? 'PENDING'),
      provider: json['provider'] ?? '',
      createdAt: json['createdAt'] != null
          ? _parseDateTime(json['createdAt'])
          : null,
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'period': period.toApiString(),
      'startDate': _formatDate(startDate),
      'endDate': _formatDate(endDate),
      'status': status.toApiString(),
      'provider': provider,
      'createdAt': createdAt != null ? _formatDateTime(createdAt!) : null,
    };
  }

  // Méthodes utilitaires de parsing
  static DateTime _parseDate(String date) {
    try {
      return DateTime.parse(date).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime _parseDateTime(String date) {
    try {
      return DateTime.parse(date).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  static String _formatDate(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  static String _formatDateTime(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  // Propriétés calculées utiles
  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isPending => status == SubscriptionStatus.pending;
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  int get daysRemaining {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;

  @override
  String toString() {
    return 'Subscription(id: $id, userId: $userId, period: ${period.displayName}, status: ${status.displayName})';
  }
}

class SubscriptionRequest {
  final int userId;
  final SubscriptionPeriod period;
  final String price;
  final String? returnUrl;
  final String? cancelUrl;

  SubscriptionRequest({
    required this.userId,
    required this.period,
    required this.price,
    this.returnUrl,
    this.cancelUrl,
  });

  factory SubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequest(
      userId: json['userId'] as int,
      period: SubscriptionPeriod.fromString(json['period'] ?? 'month'),
      price: json['price'] as String,
      returnUrl: json['returnUrl'] as String?,
      cancelUrl: json['cancelUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'period': period.toApiString(),
      'price': price,
      'returnUrl': returnUrl,
      'cancelUrl': cancelUrl,
    };
  }
}

class PayPalOrderResponse {
  final String id;
  final String status;
  final String approveUrl;
  final DateTime? createdAt;

  PayPalOrderResponse({
    required this.id,
    required this.status,
    required this.approveUrl,
    this.createdAt,
  });

  factory PayPalOrderResponse.fromJson(Map<String, dynamic> json) {
    return PayPalOrderResponse(
      id: json['id'] as String,
      status: json['status'] as String,
      approveUrl: json['approve_url'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'approve_url': approveUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
