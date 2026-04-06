// models/notification.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool seen;
  final DateTime? readAt;
  final int userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String type;
  final String priority;
  final String? actionUrl;
  final String? icon;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.seen,
    this.readAt,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    required this.type,
    required this.priority,
    this.actionUrl,
    this.icon,
    this.metadata,
  });

  // CORRECTION: Méthode fromJson robuste avec valeurs par défaut
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        id: _parseInt(json['id']),
        title: _parseString(json['title']) ?? 'Notification',
        message: _parseString(json['message']) ?? '',
        // CORRECTION: seen peut être absent, null, ou bool
        seen: _parseBool(json['seen']),
        readAt: _parseDateTime(json['readAt']),
        userId: _parseInt(json['userId']),
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        // CORRECTION: type peut être absent, utiliser 'system' par défaut
        type: _parseString(json['type']) ?? 'system',
        // CORRECTION: priority peut être absent, utiliser 'normal' par défaut
        priority: _parseString(json['priority']) ?? 'normal',
        actionUrl: _parseString(json['actionUrl']),
        icon: _parseString(json['icon']),
        metadata: json['metadata'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
      );
    } catch (e) {
      // Fallback minimaliste si tout échoue
      if (kDebugMode) {
        print('❌ Erreur parsing NotificationModel: $e');
      }
      return NotificationModel(
        id: json['id'] is int ? json['id'] as int : 0,
        title: json['title'] is String
            ? json['title'] as String
            : 'Notification',
        message: json['message'] is String ? json['message'] as String : '',
        seen: false,
        userId: json['userId'] is int ? json['userId'] as int : 0,
        type: 'system',
        priority: 'normal',
      );
    }
  }

  // Méthodes helpers pour parsing sécurisé
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isNotEmpty ? value : null;
    return value.toString();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Essayer plusieurs formats
        if (value.contains('T')) {
          return DateTime.parse(value);
        } else {
          // Format sans T (2026-02-06 09:00:09)
          final dateTimeStr = value.replaceAll(' ', 'T');
          return DateTime.parse(dateTimeStr);
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing DateTime: $value - $e');
        }
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'seen': seen,
      'readAt': readAt?.toIso8601String(),
      'userId': userId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'type': type,
      'priority': priority,
      'actionUrl': actionUrl,
      'icon': icon,
      'metadata': metadata,
    };
  }

  // Méthode copyWith
  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    bool? seen,
    DateTime? readAt,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
    String? priority,
    String? actionUrl,
    String? icon,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      seen: seen ?? this.seen,
      readAt: readAt ?? this.readAt,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      actionUrl: actionUrl ?? this.actionUrl,
      icon: icon ?? this.icon,
      metadata: metadata ?? this.metadata,
    );
  }

  // Méthodes utilitaires
  bool get isUnread => !seen;
  bool get hasAction => actionUrl != null && actionUrl!.isNotEmpty;
  DateTime get displayDate => readAt ?? createdAt ?? DateTime.now();
  String get timeAgo => _formatTimeAgo(displayDate);

  bool get isHighPriority => priority.toLowerCase() == 'high';
  String get formattedTime => timeAgo;
  IconData get typeIcon => _getTypeIcon(type);
  String get formattedDate => _getFormattedDate();

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return "Il y a ${difference.inMinutes} min";
    } else if (difference.inHours < 24) {
      return "Il y a ${difference.inHours} h";
    } else if (difference.inDays == 1) {
      return "Hier";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays} j";
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return "Il y a $weeks semaine${weeks > 1 ? 's' : ''}";
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return "Il y a $months mois";
    } else {
      final years = (difference.inDays / 365).floor();
      return "Il y a $years an${years > 1 ? 's' : ''}";
    }
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return Icons.settings;
      case 'reminder':
        return Icons.notifications;
      case 'achievement':
        return Icons.emoji_events;
      case 'info':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  String _getFormattedDate() {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(
      createdAt!.year,
      createdAt!.month,
      createdAt!.day,
    );

    if (notificationDate == today) {
      return "Aujourd'hui à ${DateFormat('HH:mm').format(createdAt!)}";
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return "Hier à ${DateFormat('HH:mm').format(createdAt!)}";
    } else {
      return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(createdAt!);
    }
  }
}

// AJOUTER: Classe pour les statistiques de notifications
class NotificationStatistics {
  final int totalCount;
  final int readCount;
  final int unreadCount;
  final double readPercentage;

  const NotificationStatistics({
    required this.totalCount,
    required this.readCount,
    required this.unreadCount,
    required this.readPercentage,
  });

  factory NotificationStatistics.fromJson(Map<String, dynamic> json) {
    return NotificationStatistics(
      totalCount: json['totalCount'] as int? ?? 0,
      readCount: json['readCount'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
      readPercentage: (json['readPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'readCount': readCount,
      'unreadCount': unreadCount,
      'readPercentage': readPercentage,
    };
  }
}

// AJOUTER: Classe pour la page paginée
class NotificationPage {
  final List<NotificationModel> notifications;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasMore;

  const NotificationPage({
    required this.notifications,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasMore,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] ?? []) as List<dynamic>;
    final notifications = content
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return NotificationPage(
      notifications: notifications,
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      hasMore:
          json['hasMore'] as bool? ??
          ((json['last'] as bool?) == false ||
              (json['page'] as int? ?? 0) <
                  (json['totalPages'] as int? ?? 1) - 1),
    );
  }
}

// Extension pour copier une notification
extension NotificationCopy on NotificationModel {
  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    bool? seen,
    DateTime? readAt,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
    String? priority,
    String? actionUrl,
    String? icon,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      seen: seen ?? this.seen,
      readAt: readAt ?? this.readAt,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      actionUrl: actionUrl ?? this.actionUrl,
      icon: icon ?? this.icon,
      metadata: metadata ?? this.metadata,
    );
  }
}
