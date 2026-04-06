// lib/models/numerology_message.dart
class NumerologyMessage {
  final int? id;
  final String type;
  final int vibrationNumber;
  final String message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NumerologyMessage({
    this.id,
    required this.type,
    required this.vibrationNumber,
    required this.message,
    this.createdAt,
    this.updatedAt,
  });

  factory NumerologyMessage.fromJson(Map<String, dynamic> json) {
    return NumerologyMessage(
      id: json['id'] as int?,
      type: json['type'] as String? ?? '',
      vibrationNumber: json['vibrationNumber'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'vibrationNumber': vibrationNumber,
      'message': message,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
