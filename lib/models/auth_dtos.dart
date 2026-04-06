import 'package:flutter/foundation.dart';
import 'user.dart';

@immutable
class SignupRequest {
  final String fullName;
  final String email;
  final String password;
  final String username;

  const SignupRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.username,
  });

  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    return SignupRequest(
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'username': username,
    };
  }
}

@immutable
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

@immutable
class EmailVerificationRequest {
  final String email;
  final String code;

  const EmailVerificationRequest({required this.email, required this.code});

  factory EmailVerificationRequest.fromJson(Map<String, dynamic> json) {
    return EmailVerificationRequest(
      email: json['email'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code};
  }
}

@immutable
class PasswordResetRequest {
  final String token;
  final String newPassword;

  const PasswordResetRequest({required this.token, required this.newPassword});

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequest(
      token: json['token'] as String,
      newPassword: json['newPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'newPassword': newPassword};
  }
}

@immutable
class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;

  const PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  factory PasswordChangeRequest.fromJson(Map<String, dynamic> json) {
    return PasswordChangeRequest(
      currentPassword: json['currentPassword'] as String,
      newPassword: json['newPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'currentPassword': currentPassword, 'newPassword': newPassword};
  }
}

@immutable
class UserUpdateRequest {
  final String? fullName;
  final String? email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? birthDate;
  final String? gender;
  final String? bio;
  final String? timezone;
  final String? locale;
  final int? dailyGoal;
  final int? weeklyGoal;
  final bool? notificationEnabled;
  final bool? pushNotificationEnabled;
  final bool? marketingConsent;
  final String? profilePictureUrl;
  final String? websiteUrl;
  final String? emailNotificationFrequency;

  const UserUpdateRequest({
    this.fullName,
    this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.birthDate,
    this.gender,
    this.bio,
    this.timezone,
    this.locale,
    this.dailyGoal,
    this.weeklyGoal,
    this.notificationEnabled,
    this.pushNotificationEnabled,
    this.marketingConsent,
    this.profilePictureUrl,
    this.websiteUrl,
    this.emailNotificationFrequency,
  });

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserUpdateRequest(
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      birthDate: json['birthDate'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      timezone: json['timezone'] as String?,
      locale: json['locale'] as String?,
      dailyGoal: json['dailyGoal'] as int?,
      weeklyGoal: json['weeklyGoal'] as int?,
      notificationEnabled: json['notificationEnabled'] as bool?,
      pushNotificationEnabled: json['pushNotificationEnabled'] as bool?,
      marketingConsent: json['marketingConsent'] as bool?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      emailNotificationFrequency: json['emailNotificationFrequency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (fullName != null) json['fullName'] = fullName;
    if (email != null) json['email'] = email;
    if (username != null) json['username'] = username;
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (phoneNumber != null) json['phoneNumber'] = phoneNumber;
    if (birthDate != null) json['birthDate'] = birthDate;
    if (gender != null) json['gender'] = gender;
    if (bio != null) json['bio'] = bio;
    if (timezone != null) json['timezone'] = timezone;
    if (locale != null) json['locale'] = locale;
    if (dailyGoal != null) json['dailyGoal'] = dailyGoal;
    if (weeklyGoal != null) json['weeklyGoal'] = weeklyGoal;
    if (notificationEnabled != null)
      json['notificationEnabled'] = notificationEnabled;
    if (pushNotificationEnabled != null)
      json['pushNotificationEnabled'] = pushNotificationEnabled;
    if (marketingConsent != null) json['marketingConsent'] = marketingConsent;
    if (profilePictureUrl != null)
      json['profilePictureUrl'] = profilePictureUrl;
    if (websiteUrl != null) json['websiteUrl'] = websiteUrl;
    if (emailNotificationFrequency != null)
      json['emailNotificationFrequency'] = emailNotificationFrequency;

    return json;
  }
}

@immutable
class AuthResponse {
  final String token;
  final String tokenType;
  final int userId;
  final User user;

  const AuthResponse({
    required this.token,
    required this.tokenType,
    required this.userId,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    print('🔧 AuthResponse.fromJson() appelé avec JSON: ${json.keys.toList()}');

    // Vérifier les champs requis
    if (json['token'] == null) {
      throw FormatException('Token manquant dans la réponse');
    }
    if (json['userId'] == null) {
      throw FormatException('userId manquant dans la réponse');
    }

    // Créer l'objet User à partir des champs dans la réponse
    final user = User.fromJson({
      'id': json['userId'],
      'fullName': json['fullName'] ?? '',
      'email': json['email'] ?? json['username'] ?? '',
      'username': json['username'] ?? json['email'] ?? '',
      'roles': json['roles'] is List ? json['roles'] : ['USER'],
      'premium': json['premium'] ?? false,
      'emailVerified': json['emailVerified'] ?? false,
    });

    return AuthResponse(
      token: json['token'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId'].toString()) ?? 0,
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenType': tokenType,
      'userId': userId,
      'user': user.toJson(),
    };
  }
}
