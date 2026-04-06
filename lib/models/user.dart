import 'package:flutter/foundation.dart';

@immutable
class User {
  final int? id;
  final String fullName;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? birthDate;
  final String? gender;
  final String? bio;
  final Set<String> roles;
  final bool isPremium;
  final bool isActive;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final String? timezone;
  final String locale;
  final int dailyGoal;
  final int weeklyGoal;
  final bool notificationEnabled;
  final bool pushNotificationEnabled;
  final bool marketingConsent;
  final String? profilePictureUrl;
  final String? websiteUrl;
  final bool accountDeletionRequested;
  final DateTime? deletionRequestedAt;
  final bool dataExportRequested;
  final DateTime? exportRequestedAt;
  final bool twoFactorEnabled;
  final String? emailNotificationFrequency;
  final int streakCount;
  final int currentStreakDays;
  final int bestStreakDays;
  final int totalActivitiesCompleted;
  final int totalTimeMinutes;

  const User({
    this.id,
    required this.fullName,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.bio,
    this.roles = const {},
    this.isPremium = false,
    this.isActive = true,
    this.emailVerified = false,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.timezone,
    this.locale = 'fr_FR',
    this.dailyGoal = 1,
    this.weeklyGoal = 7,
    this.notificationEnabled = true,
    this.pushNotificationEnabled = true,
    this.marketingConsent = false,
    this.profilePictureUrl,
    this.websiteUrl,
    this.accountDeletionRequested = false,
    this.deletionRequestedAt,
    this.dataExportRequested = false,
    this.exportRequestedAt,
    this.twoFactorEnabled = false,
    this.emailNotificationFrequency = 'DAILY',
    this.streakCount = 0,
    this.currentStreakDays = 0,
    this.bestStreakDays = 0,
    this.totalActivitiesCompleted = 0,
    this.totalTimeMinutes = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Convertir les rôles
    Set<String> rolesSet = {};
    if (json['roles'] != null) {
      if (json['roles'] is List) {
        rolesSet = Set<String>.from(
          json['roles'].map<String>((role) => role.toString()),
        );
      } else if (json['roles'] is String) {
        rolesSet = {json['roles']};
      }
    }

    // Parser les dates
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is DateTime) return date;
      if (date is String) return DateTime.tryParse(date);
      return null;
    }

    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      birthDate: parseDate(json['birthDate'] ?? json['birth_date']),
      gender: json['gender'],
      bio: json['bio'],
      roles: rolesSet,
      isPremium: json['isPremium'] ?? json['premium'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      emailVerified: json['emailVerified'] ?? json['email_verified'] ?? false,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      lastLoginAt: parseDate(json['lastLoginAt'] ?? json['last_login_at']),
      timezone: json['timezone'],
      locale: json['locale'] ?? 'fr_FR',
      dailyGoal: json['dailyGoal'] ?? json['daily_goal'] ?? 1,
      weeklyGoal: json['weeklyGoal'] ?? json['weekly_goal'] ?? 7,
      notificationEnabled:
          json['notificationEnabled'] ?? json['notification_enabled'] ?? true,
      pushNotificationEnabled:
          json['pushNotificationEnabled'] ??
          json['push_notification_enabled'] ??
          true,
      marketingConsent:
          json['marketingConsent'] ?? json['marketing_consent'] ?? false,
      profilePictureUrl:
          json['profilePictureUrl'] ?? json['profile_picture_url'],
      websiteUrl: json['websiteUrl'] ?? json['website_url'],
      accountDeletionRequested:
          json['accountDeletionRequested'] ??
          json['account_deletion_requested'] ??
          false,
      deletionRequestedAt: parseDate(
        json['deletionRequestedAt'] ?? json['deletion_requested_at'],
      ),
      dataExportRequested:
          json['dataExportRequested'] ?? json['data_export_requested'] ?? false,
      exportRequestedAt: parseDate(
        json['exportRequestedAt'] ?? json['export_requested_at'],
      ),
      twoFactorEnabled:
          json['twoFactorEnabled'] ?? json['two_factor_enabled'] ?? false,
      emailNotificationFrequency:
          json['emailNotificationFrequency'] ??
          json['email_notification_frequency'] ??
          'DAILY',
      streakCount: json['streakCount'] ?? json['streak_count'] ?? 0,
      currentStreakDays:
          json['currentStreakDays'] ?? json['current_streak_days'] ?? 0,
      bestStreakDays: json['bestStreakDays'] ?? json['best_streak_days'] ?? 0,
      totalActivitiesCompleted:
          json['totalActivitiesCompleted'] ??
          json['total_activities_completed'] ??
          0,
      totalTimeMinutes:
          json['totalTimeMinutes'] ?? json['total_time_minutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'bio': bio,
      'roles': roles.toList(),
      'isPremium': isPremium,
      'isActive': isActive,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'timezone': timezone,
      'locale': locale,
      'dailyGoal': dailyGoal,
      'weeklyGoal': weeklyGoal,
      'notificationEnabled': notificationEnabled,
      'pushNotificationEnabled': pushNotificationEnabled,
      'marketingConsent': marketingConsent,
      'profilePictureUrl': profilePictureUrl,
      'websiteUrl': websiteUrl,
      'accountDeletionRequested': accountDeletionRequested,
      'deletionRequestedAt': deletionRequestedAt?.toIso8601String(),
      'dataExportRequested': dataExportRequested,
      'exportRequestedAt': exportRequestedAt?.toIso8601String(),
      'twoFactorEnabled': twoFactorEnabled,
      'emailNotificationFrequency': emailNotificationFrequency,
      'streakCount': streakCount,
      'currentStreakDays': currentStreakDays,
      'bestStreakDays': bestStreakDays,
      'totalActivitiesCompleted': totalActivitiesCompleted,
      'totalTimeMinutes': totalTimeMinutes,
    };
  }

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (fullName.isNotEmpty) {
      return fullName.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (fullName.isNotEmpty) {
      return fullName;
    } else if (username != null) {
      return username!;
    }
    return email.split('@')[0];
  }

  bool get isValid => fullName.isNotEmpty && email.isNotEmpty;

  bool get isAdmin => roles.contains('ADMIN');
  bool get isContentCreator => roles.contains('CONTENT_CREATOR') || isAdmin;

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? birthDate,
    String? gender,
    String? bio,
    Set<String>? roles,
    bool? isPremium,
    bool? isActive,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? timezone,
    String? locale,
    int? dailyGoal,
    int? weeklyGoal,
    bool? notificationEnabled,
    bool? pushNotificationEnabled,
    bool? marketingConsent,
    String? profilePictureUrl,
    String? websiteUrl,
    bool? accountDeletionRequested,
    DateTime? deletionRequestedAt,
    bool? dataExportRequested,
    DateTime? exportRequestedAt,
    bool? twoFactorEnabled,
    String? emailNotificationFrequency,
    int? streakCount,
    int? currentStreakDays,
    int? bestStreakDays,
    int? totalActivitiesCompleted,
    int? totalTimeMinutes,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      roles: roles ?? this.roles,
      isPremium: isPremium ?? this.isPremium,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      pushNotificationEnabled:
          pushNotificationEnabled ?? this.pushNotificationEnabled,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      accountDeletionRequested:
          accountDeletionRequested ?? this.accountDeletionRequested,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
      dataExportRequested: dataExportRequested ?? this.dataExportRequested,
      exportRequestedAt: exportRequestedAt ?? this.exportRequestedAt,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      emailNotificationFrequency:
          emailNotificationFrequency ?? this.emailNotificationFrequency,
      streakCount: streakCount ?? this.streakCount,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
      totalActivitiesCompleted:
          totalActivitiesCompleted ?? this.totalActivitiesCompleted,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.username == username &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.phoneNumber == phoneNumber &&
        other.birthDate == birthDate &&
        other.gender == gender &&
        other.bio == bio &&
        setEquals(other.roles, roles) &&
        other.isPremium == isPremium &&
        other.isActive == isActive &&
        other.emailVerified == emailVerified &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastLoginAt == lastLoginAt &&
        other.timezone == timezone &&
        other.locale == locale &&
        other.dailyGoal == dailyGoal &&
        other.weeklyGoal == weeklyGoal &&
        other.notificationEnabled == notificationEnabled &&
        other.pushNotificationEnabled == pushNotificationEnabled &&
        other.marketingConsent == marketingConsent &&
        other.profilePictureUrl == profilePictureUrl &&
        other.websiteUrl == websiteUrl &&
        other.accountDeletionRequested == accountDeletionRequested &&
        other.deletionRequestedAt == deletionRequestedAt &&
        other.dataExportRequested == dataExportRequested &&
        other.exportRequestedAt == exportRequestedAt &&
        other.twoFactorEnabled == twoFactorEnabled &&
        other.emailNotificationFrequency == emailNotificationFrequency &&
        other.streakCount == streakCount &&
        other.currentStreakDays == currentStreakDays &&
        other.bestStreakDays == bestStreakDays &&
        other.totalActivitiesCompleted == totalActivitiesCompleted &&
        other.totalTimeMinutes == totalTimeMinutes;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      fullName,
      email,
      username,
      firstName,
      lastName,
      phoneNumber,
      birthDate,
      gender,
      bio,
      Object.hashAll(roles.toList()),
      isPremium,
      isActive,
      emailVerified,
      createdAt,
      updatedAt,
      lastLoginAt,
      timezone,
      locale,
      dailyGoal,
      weeklyGoal,
      notificationEnabled,
      pushNotificationEnabled,
      marketingConsent,
      profilePictureUrl,
      websiteUrl,
      accountDeletionRequested,
      deletionRequestedAt,
      dataExportRequested,
      exportRequestedAt,
      twoFactorEnabled,
      emailNotificationFrequency,
      streakCount,
      currentStreakDays,
      bestStreakDays,
      totalActivitiesCompleted,
      totalTimeMinutes,
    ]);
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, '
        'username: $username, isPremium: $isPremium, isActive: $isActive, '
        'emailVerified: $emailVerified)';
  }
}
