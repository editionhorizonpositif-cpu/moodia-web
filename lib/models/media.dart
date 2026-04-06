// lib/models/media.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum MediaType { IMAGE, AUDIO, VIDEO, DOCUMENT, OTHER }

class MediaAsset {
  final int? id;
  final int userId;
  final String originalFilename;
  final String storedFilename;
  final MediaType mediaType;
  final String mimeType;
  final int fileSizeBytes;
  final String checksum;
  final int? durationSeconds;
  final String? resolution;
  final int? bitrateKbps;
  final String? category;
  final String? tags;
  final String? title;
  final String? description;
  final String status;
  final bool isPublic;
  final int downloadCount;
  final int viewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;

  MediaAsset({
    this.id,
    required this.userId,
    required this.originalFilename,
    required this.storedFilename,
    required this.mediaType,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.checksum,
    this.durationSeconds,
    this.resolution,
    this.bitrateKbps,
    this.category,
    this.tags,
    this.title,
    this.description,
    this.status = 'UPLOADED',
    this.isPublic = true,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.createdAt,
    this.updatedAt,
    this.version = 0,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: _parseInt(json['id']),
      userId: _parseInt(json['userId']),
      originalFilename: _parseString(json['originalFilename'], ''),
      storedFilename: _parseString(json['storedFilename'], ''),
      mediaType: _parseMediaType(json['mediaType']),
      mimeType: _parseString(json['mimeType'], 'application/octet-stream'),
      fileSizeBytes: _parseInt(json['fileSizeBytes']),
      checksum: _parseString(json['checksum'], ''),
      durationSeconds: _parseInt(json['durationSeconds']),
      resolution: _parseString(json['resolution']),
      bitrateKbps: _parseInt(json['bitrateKbps']),
      category: _parseString(json['category']),
      tags: _parseString(json['tags']),
      title: _parseString(json['title']),
      description: _parseString(json['description']),
      status: _parseString(json['status'], 'UPLOADED'),
      isPublic: _parseBool(json['isPublic'], true),
      downloadCount: _parseInt(json['downloadCount']),
      viewCount: _parseInt(json['viewCount']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      version: _parseInt(json['version']),
    );
  }

  static MediaType _parseMediaType(dynamic value) {
    if (value == null) return MediaType.OTHER;
    final String type = value.toString().toUpperCase();
    switch (type) {
      case 'IMAGE':
        return MediaType.IMAGE;
      case 'AUDIO':
        return MediaType.AUDIO;
      case 'VIDEO':
        return MediaType.VIDEO;
      case 'DOCUMENT':
        return MediaType.DOCUMENT;
      case 'PDF':
        return MediaType.DOCUMENT;
      default:
        return MediaType.OTHER;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur parsing date: $e');
      }
    }
    return null;
  }

  static String _parseString(dynamic value, [String? defaultValue]) {
    if (value == null) return defaultValue ?? '';
    if (value is String) return value;
    return value.toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    final map = {
      'userId': userId,
      'originalFilename': originalFilename,
      'storedFilename': storedFilename,
      'mediaType': mediaType.toString().split('.').last,
      'mimeType': mimeType,
      'fileSizeBytes': fileSizeBytes,
      'checksum': checksum,
      'durationSeconds': durationSeconds,
      'resolution': resolution,
      'bitrateKbps': bitrateKbps,
      'category': category,
      'tags': tags,
      'title': title,
      'description': description,
      'status': status,
      'isPublic': isPublic,
      'downloadCount': downloadCount,
      'viewCount': viewCount,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Méthodes utilitaires
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get extension {
    if (originalFilename.lastIndexOf('.') == -1) {
      return '';
    }
    return originalFilename
        .substring(originalFilename.lastIndexOf('.') + 1)
        .toLowerCase();
  }

  bool get isImage => mediaType == MediaType.IMAGE;
  bool get isAudio => mediaType == MediaType.AUDIO;
  bool get isVideo => mediaType == MediaType.VIDEO;
  bool get isDocument => mediaType == MediaType.DOCUMENT;

  String get mediaTypeIcon {
    switch (mediaType) {
      case MediaType.IMAGE:
        return '🖼️';
      case MediaType.AUDIO:
        return '🎵';
      case MediaType.VIDEO:
        return '🎬';
      case MediaType.DOCUMENT:
        return '📄';
      default:
        return '📁';
    }
  }

  IconData get mediaIcon {
    switch (mediaType) {
      case MediaType.IMAGE:
        return Icons.image;
      case MediaType.AUDIO:
        return Icons.audiotrack;
      case MediaType.VIDEO:
        return Icons.videocam;
      case MediaType.DOCUMENT:
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get mediaColor {
    switch (mediaType) {
      case MediaType.IMAGE:
        return Colors.green;
      case MediaType.AUDIO:
        return Colors.blue;
      case MediaType.VIDEO:
        return Colors.purple;
      case MediaType.DOCUMENT:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final duration = Duration(seconds: durationSeconds!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// DTO pour la mise à jour de média
class UpdateMediaRequest {
  final String? title;
  final String? description;
  final String? category;
  final String? tags;
  final bool? isPublic;
  final String? status;

  UpdateMediaRequest({
    this.title,
    this.description,
    this.category,
    this.tags,
    this.isPublic,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (category != null) map['category'] = category;
    if (tags != null) map['tags'] = tags;
    if (isPublic != null) map['isPublic'] = isPublic;
    if (status != null) map['status'] = status;
    return map;
  }
}

// Réponse de l'upload (MIS À JOUR selon la réponse réelle du backend)
class MediaUploadResponse {
  final int mediaId;
  final String status;
  final String message;
  final String? formattedSize;
  final String? downloadUrl;
  final int? estimatedProcessingSeconds;
  final bool processing;
  final bool failed;
  final bool success;

  // Champs optionnels qui peuvent être dans certaines réponses
  final String? originalFilename;
  final String? storedFilename;
  final MediaType? mediaType;
  final String? mimeType;
  final int? fileSizeBytes;
  final String? checksum;
  final int? userId;
  final String? title;
  final String? category;

  MediaUploadResponse({
    required this.mediaId,
    required this.status,
    required this.message,
    this.formattedSize,
    this.downloadUrl,
    this.estimatedProcessingSeconds,
    this.processing = false,
    this.failed = false,
    this.success = true,
    this.originalFilename,
    this.storedFilename,
    this.mediaType,
    this.mimeType,
    this.fileSizeBytes,
    this.checksum,
    this.userId,
    this.title,
    this.category,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    // Debug: afficher les données reçues
    if (kDebugMode) {
      print('📥 === PARSING UPLOAD RESPONSE JSON ===');
      print('📥 Données reçues: $json');
    }

    return MediaUploadResponse(
      mediaId: _parseInt(json['mediaId']),
      status: _parseString(json['status'], 'UPLOADED'),
      message: _parseString(json['message'], ''),
      formattedSize: _parseString(json['formattedSize']),
      downloadUrl: _parseString(json['downloadUrl']),
      estimatedProcessingSeconds: _parseInt(json['estimatedProcessingSeconds']),
      processing: _parseBool(json['processing'], false),
      failed: _parseBool(json['failed'], false),
      success: _parseBool(json['success'], true),
      originalFilename: _parseString(json['originalFilename']),
      storedFilename: _parseString(json['storedFilename']),
      mediaType: _parseMediaType(json['mediaType']),
      mimeType: _parseString(json['mimeType']),
      fileSizeBytes: _parseInt(json['fileSizeBytes']),
      checksum: _parseString(json['checksum']),
      userId: _parseInt(json['userId']),
      title: _parseString(json['title']),
      category: _parseString(json['category']),
    );
  }

  // Méthodes de parsing sécurisées
  static String _parseString(dynamic value, [String? defaultValue]) {
    if (value == null) return defaultValue ?? '';
    if (value is String) return value;
    return value.toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return defaultValue;
  }

  static MediaType? _parseMediaType(dynamic value) {
    if (value == null) return null;
    final String type = value.toString().toUpperCase();
    switch (type) {
      case 'IMAGE':
        return MediaType.IMAGE;
      case 'AUDIO':
        return MediaType.AUDIO;
      case 'VIDEO':
        return MediaType.VIDEO;
      case 'DOCUMENT':
        return MediaType.DOCUMENT;
      case 'PDF':
        return MediaType.DOCUMENT;
      default:
        return MediaType.OTHER;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'status': status,
      'message': message,
      'formattedSize': formattedSize,
      'downloadUrl': downloadUrl,
      'estimatedProcessingSeconds': estimatedProcessingSeconds,
      'processing': processing,
      'failed': failed,
      'success': success,
      if (originalFilename != null) 'originalFilename': originalFilename,
      if (storedFilename != null) 'storedFilename': storedFilename,
      if (mediaType != null) 'mediaType': mediaType.toString(),
      if (mimeType != null) 'mimeType': mimeType,
      if (fileSizeBytes != null) 'fileSizeBytes': fileSizeBytes,
      if (checksum != null) 'checksum': checksum,
      if (userId != null) 'userId': userId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
    };
  }

  MediaAsset toMediaAsset() {
    return MediaAsset(
      id: mediaId,
      userId: userId ?? 0,
      originalFilename: originalFilename ?? 'file_$mediaId',
      storedFilename: storedFilename ?? 'file_$mediaId',
      mediaType: mediaType ?? MediaType.OTHER,
      mimeType: mimeType ?? 'application/octet-stream',
      fileSizeBytes: fileSizeBytes ?? 0,
      checksum: checksum ?? '',
      title: title,
      category: category,
      status: status,
      isPublic: true,
      downloadCount: 0,
      viewCount: 0,
      version: 0,
    );
  }
}

// DTO pour la réponse des médias
class MediaDTO {
  final int id;
  final int userId;
  final String originalFilename;
  final String storedFilename;
  final MediaType mediaType;
  final String mimeType;
  final int fileSizeBytes;
  final String checksum;
  final int? durationSeconds;
  final String? resolution;
  final int? bitrateKbps;
  final String? category;
  final String? tags;
  final String? title;
  final String? description;
  final String status;
  final bool isPublic;
  final int downloadCount;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MediaDTO({
    required this.id,
    required this.userId,
    required this.originalFilename,
    required this.storedFilename,
    required this.mediaType,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.checksum,
    this.durationSeconds,
    this.resolution,
    this.bitrateKbps,
    this.category,
    this.tags,
    this.title,
    this.description,
    required this.status,
    required this.isPublic,
    required this.downloadCount,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaDTO.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('📥 === PARSING MEDIA DTO JSON ===');
      print('📥 Données reçues: $json');
    }

    return MediaDTO(
      id: _parseInt(json['id']),
      userId: _parseInt(json['userId']),
      originalFilename: _parseString(json['originalFilename'], ''),
      storedFilename: _parseString(json['storedFilename'], ''),
      mediaType: _parseMediaType(json['mediaType']),
      mimeType: _parseString(json['mimeType'], 'application/octet-stream'),
      fileSizeBytes: _parseInt(json['fileSizeBytes']),
      checksum: _parseString(json['checksum'], ''),
      durationSeconds: _parseInt(json['durationSeconds']),
      resolution: _parseString(json['resolution']),
      bitrateKbps: _parseInt(json['bitrateKbps']),
      category: _parseString(json['category']),
      tags: _parseString(json['tags']),
      title: _parseString(json['title']),
      description: _parseString(json['description']),
      status: _parseString(json['status'], ''),
      isPublic: _parseBool(json['isPublic'], true),
      downloadCount: _parseInt(json['downloadCount']),
      viewCount: _parseInt(json['viewCount']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static MediaType _parseMediaType(dynamic value) {
    if (value == null) return MediaType.OTHER;
    final String type = value.toString().toUpperCase();
    switch (type) {
      case 'IMAGE':
        return MediaType.IMAGE;
      case 'AUDIO':
        return MediaType.AUDIO;
      case 'VIDEO':
        return MediaType.VIDEO;
      case 'DOCUMENT':
        return MediaType.DOCUMENT;
      default:
        return MediaType.OTHER;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur parsing date MediaDTO: $e');
      }
    }
    return null;
  }

  static String _parseString(dynamic value, [String? defaultValue]) {
    if (value == null) return defaultValue ?? '';
    if (value is String) return value;
    return value.toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return defaultValue;
  }

  MediaAsset toMediaAsset() {
    return MediaAsset(
      id: id,
      userId: userId,
      originalFilename: originalFilename,
      storedFilename: storedFilename,
      mediaType: mediaType,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      checksum: checksum,
      durationSeconds: durationSeconds,
      resolution: resolution,
      bitrateKbps: bitrateKbps,
      category: category,
      tags: tags,
      title: title,
      description: description,
      status: status,
      isPublic: isPublic,
      downloadCount: downloadCount,
      viewCount: viewCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: 0,
    );
  }
}
