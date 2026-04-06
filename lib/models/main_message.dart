import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';

class MainMessage {
  final int? id;
  final String type;
  final String title;
  final String message;
  final String? description;
  final String? url;
  final String? icon;
  final String? colorCode;
  final int? priority;
  final bool? isActive;
  final String? targetAudience;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  MainMessage({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    this.description,
    this.url,
    this.icon,
    this.colorCode,
    this.priority,
    this.isActive,
    this.targetAudience,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory MainMessage.fromJson(Map<String, dynamic> json) {
    // Helper function to parse dates
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        // Try multiple date formats
        final formats = [
          'yyyy-MM-dd HH:mm:ss',
          'yyyy-MM-ddTHH:mm:ss',
          'yyyy-MM-dd',
        ];

        for (final format in formats) {
          try {
            final formatter = DateFormat(format);
            return formatter.parse(dateString);
          } catch (_) {
            continue;
          }
        }

        // Fallback to DateTime.parse
        return DateTime.parse(dateString);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur parsing date "$dateString": $e');
        }
        return null;
      }
    }

    return MainMessage(
      id: json['id'] as int?,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      description: json['description']?.toString(),
      url: json['url']?.toString(),
      icon: json['icon']?.toString(),
      colorCode: json['colorCode']?.toString(),
      priority: json['priority'] as int?,
      isActive: json['isActive'] as bool?,
      targetAudience: json['targetAudience']?.toString(),
      startDate: parseDate(json['startDate']?.toString()),
      endDate: parseDate(json['endDate']?.toString()),
      createdAt: parseDate(json['createdAt']?.toString()),
      updatedAt: parseDate(json['updatedAt']?.toString()),
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final format = DateFormat('yyyy-MM-dd HH:mm:ss');
    final map = {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'description': description,
      'url': url,
      'icon': icon,
      'colorCode': colorCode,
      'priority': priority,
      'isActive': isActive,
      'targetAudience': targetAudience,
      'startDate': startDate != null ? format.format(startDate!) : null,
      'endDate': endDate != null ? format.format(endDate!) : null,
      'createdAt': createdAt != null ? format.format(createdAt!) : null,
      'updatedAt': updatedAt != null ? format.format(updatedAt!) : null,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };

    if (kDebugMode) {
      print("🟦 MainMessage JSON: $map");
    }
    return map;
  }

  MainMessage copyWith({
    int? id,
    String? type,
    String? title,
    String? message,
    String? description,
    String? url,
    String? icon,
    String? colorCode,
    int? priority,
    bool? isActive,
    String? targetAudience,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return MainMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      description: description ?? this.description,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      colorCode: colorCode ?? this.colorCode,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      targetAudience: targetAudience ?? this.targetAudience,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

class UserMessagesResponse {
  final List<MainMessage> messages;
  final int total;
  final String audience;

  // Nouveaux champs pour le format de l'API
  final List<MainMessage>? welcomeMessages;
  final List<MainMessage>? tips;
  final List<MainMessage>? announcements;
  final List<MainMessage>? promotions;

  UserMessagesResponse({
    required this.messages,
    required this.total,
    required this.audience,
    this.welcomeMessages,
    this.tips,
    this.announcements,
    this.promotions,
  });

  factory UserMessagesResponse.fromJson(Map<String, dynamic> json) {
    log('📋 UserMessagesResponse.fromJson appelé', name: 'MainMessage');
    log('🔑 Clés dans JSON: ${json.keys.join(", ")}', name: 'MainMessage');

    // Compter le total de tous les messages
    int totalMessages = 0;
    final allMessages = <MainMessage>[];

    // Extraire les messages par catégorie
    final welcomeMessages = _extractMessages(json, 'welcomeMessages');
    final tips = _extractMessages(json, 'tips');
    final announcements = _extractMessages(json, 'announcements');
    final promotions = _extractMessages(json, 'promotions');

    // Ajouter à la liste globale
    allMessages.addAll(welcomeMessages);
    allMessages.addAll(tips);
    allMessages.addAll(announcements);
    allMessages.addAll(promotions);

    totalMessages = allMessages.length;

    log('📊 Total messages: $totalMessages', name: 'MainMessage');
    log('👋 Welcome messages: ${welcomeMessages.length}', name: 'MainMessage');
    log('💡 Tips: ${tips.length}', name: 'MainMessage');
    log('📣 Announcements: ${announcements.length}', name: 'MainMessage');
    log('🎯 Promotions: ${promotions.length}', name: 'MainMessage');

    // Vérifier l'ancien format pour compatibilité
    if (json.containsKey('messages')) {
      log('📦 Format ancien détecté (clé "messages")', name: 'MainMessage');
      final oldMessages = _extractMessages(json, 'messages');
      allMessages.addAll(oldMessages);
      totalMessages = allMessages.length;
    }

    return UserMessagesResponse(
      messages: allMessages,
      total: json['total'] as int? ?? totalMessages,
      audience: json['audience']?.toString() ?? 'ALL',
      welcomeMessages: welcomeMessages.isNotEmpty ? welcomeMessages : null,
      tips: tips.isNotEmpty ? tips : null,
      announcements: announcements.isNotEmpty ? announcements : null,
      promotions: promotions.isNotEmpty ? promotions : null,
    );
  }

  static List<MainMessage> _extractMessages(
    Map<String, dynamic> json,
    String key,
  ) {
    if (!json.containsKey(key) || json[key] == null) {
      return [];
    }

    final messagesData = json[key];

    if (messagesData is List<dynamic>) {
      return messagesData
          .where((item) => item is Map<String, dynamic>)
          .map((item) => MainMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((message) => message.toJson()).toList(),
      'total': total,
      'audience': audience,
      if (welcomeMessages != null && welcomeMessages!.isNotEmpty)
        'welcomeMessages': welcomeMessages!.map((m) => m.toJson()).toList(),
      if (tips != null && tips!.isNotEmpty)
        'tips': tips!.map((m) => m.toJson()).toList(),
      if (announcements != null && announcements!.isNotEmpty)
        'announcements': announcements!.map((m) => m.toJson()).toList(),
      if (promotions != null && promotions!.isNotEmpty)
        'promotions': promotions!.map((m) => m.toJson()).toList(),
    };
  }

  // Méthodes utilitaires pour accéder facilement aux catégories
  List<MainMessage> getWelcomeMessages() => welcomeMessages ?? [];
  List<MainMessage> getTips() => tips ?? [];
  List<MainMessage> getAnnouncements() => announcements ?? [];
  List<MainMessage> getPromotions() => promotions ?? [];

  // Filtrer par type
  List<MainMessage> filterByType(String type) {
    return messages
        .where((msg) => msg.type.toUpperCase() == type.toUpperCase())
        .toList();
  }

  // Filtrer les messages actifs
  List<MainMessage> getActiveMessages() {
    final now = DateTime.now();
    return messages.where((msg) {
      final isActive = msg.isActive == true;
      final isAfterStart = msg.startDate == null || now.isAfter(msg.startDate!);
      final isBeforeEnd = msg.endDate == null || now.isBefore(msg.endDate!);
      return isActive && isAfterStart && isBeforeEnd;
    }).toList();
  }

  // Statistiques
  Map<String, int> getStatistics() {
    return {
      'total': total,
      'active': getActiveMessages().length,
      'welcome': getWelcomeMessages().length,
      'tips': getTips().length,
      'announcements': getAnnouncements().length,
      'promotions': getPromotions().length,
    };
  }
}

class MainMessageRequest {
  final String type;
  final String title;
  final String message;
  final String? description;
  final String? url;
  final String? icon;
  final String? colorCode;
  final int? priority;
  final bool? isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? targetAudience;

  MainMessageRequest({
    required this.type,
    required this.title,
    required this.message,
    this.description,
    this.url,
    this.icon,
    this.colorCode,
    this.priority,
    this.isActive,
    this.startDate,
    this.endDate,
    this.targetAudience,
  });

  Map<String, dynamic> toJson() {
    final format = DateFormat('yyyy-MM-dd HH:mm:ss');
    final map = {
      'type': type,
      'title': title,
      'message': message,
      if (description != null) 'description': description,
      if (url != null) 'url': url,
      if (icon != null) 'icon': icon,
      if (colorCode != null) 'colorCode': colorCode,
      if (priority != null) 'priority': priority,
      if (isActive != null) 'isActive': isActive,
      if (startDate != null) 'startDate': format.format(startDate!),
      if (endDate != null) 'endDate': format.format(endDate!),
      if (targetAudience != null) 'targetAudience': targetAudience,
    };
    return map;
  }
}

class UpdateMainMessageRequest {
  final String? type;
  final String? title;
  final String? message;
  final String? description;
  final String? url;
  final String? icon;
  final String? colorCode;
  final int? priority;
  final bool? isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? targetAudience;

  UpdateMainMessageRequest({
    this.type,
    this.title,
    this.message,
    this.description,
    this.url,
    this.icon,
    this.colorCode,
    this.priority,
    this.isActive,
    this.startDate,
    this.endDate,
    this.targetAudience,
  });

  Map<String, dynamic> toJson() {
    final format = DateFormat('yyyy-MM-dd HH:mm:ss');
    final map = <String, dynamic>{};
    if (type != null) map['type'] = type;
    if (title != null) map['title'] = title;
    if (message != null) map['message'] = message;
    if (description != null) map['description'] = description;
    if (url != null) map['url'] = url;
    if (icon != null) map['icon'] = icon;
    if (colorCode != null) map['colorCode'] = colorCode;
    if (priority != null) map['priority'] = priority;
    if (isActive != null) map['isActive'] = isActive;
    if (startDate != null) map['startDate'] = format.format(startDate!);
    if (endDate != null) map['endDate'] = format.format(endDate!);
    if (targetAudience != null) map['targetAudience'] = targetAudience;
    return map;
  }
}

// Version simplifiée pour la pagination
class PaginatedResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final int numberOfElements;
  final bool empty;

  PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.numberOfElements,
    required this.empty,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return PaginatedResponse<T>(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJson(item))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      size: json['size'] as int,
      number: json['number'] as int,
      first: json['first'] as bool,
      last: json['last'] as bool,
      numberOfElements: json['numberOfElements'] as int,
      empty: json['empty'] as bool,
    );
  }

  Map<String, dynamic> toJson(T Function(dynamic) toJson) {
    return {
      'content': content.map((item) => toJson(item)).toList(),
      'totalElements': totalElements,
      'totalPages': totalPages,
      'size': size,
      'number': number,
      'first': first,
      'last': last,
      'numberOfElements': numberOfElements,
      'empty': empty,
    };
  }
}

// Classe de débug pour analyser les réponses de l'API
class ApiDebugger {
  static void debugResponse(Map<String, dynamic> json) {
    log('🔍 DEBUG ApiDebugger', name: 'ApiDebugger');
    log('📦 Structure JSON:', name: 'ApiDebugger');

    void printStructure(dynamic value, String indent, String key) {
      if (value is Map<String, dynamic>) {
        log('$indent$key: Map avec ${value.length} clés', name: 'ApiDebugger');
        value.forEach((k, v) {
          printStructure(v, '$indent  ', k);
        });
      } else if (value is List) {
        log(
          '$indent$key: List avec ${value.length} éléments',
          name: 'ApiDebugger',
        );
        if (value.isNotEmpty && value.length <= 3) {
          for (var i = 0; i < value.length; i++) {
            printStructure(value[i], '$indent  ', '[${i}]');
          }
        } else if (value.isNotEmpty) {
          printStructure(value.first, '$indent  ', '[premier élément]');
        }
      } else {
        final stringValue = value?.toString() ?? 'null';
        final truncated = stringValue.length > 50
            ? '${stringValue.substring(0, 50)}...'
            : stringValue;
        log(
          '$indent$key: $truncated (${value?.runtimeType})',
          name: 'ApiDebugger',
        );
      }
    }

    printStructure(json, '', 'root');
  }
}
