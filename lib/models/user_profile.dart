// lib/models/user_profile.dart

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Modèle de profil utilisateur pour Moodia
@immutable
class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? birthDate;
  final String role;
  final bool isPremium;
  final String? avatarUrl;
  final DateTime? memberSince;
  final String initials;
  final String? city;
  final String? bio;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? subscriptionInfo;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.birthDate,
    this.role = 'user',
    this.isPremium = false,
    this.avatarUrl,
    this.memberSince,
    required this.initials,
    this.city,
    this.bio,
    this.preferences,
    this.subscriptionInfo,
  });

  /// Créer un UserProfile vide
  factory UserProfile.empty() {
    return UserProfile(
      id: 0,
      fullName: 'Utilisateur',
      email: '',
      initials: 'U',
    );
  }

  /// Créer depuis JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      role: json['role'] ?? 'user',
      isPremium: json['isPremium'] ?? false,
      avatarUrl: json['avatarUrl'],
      memberSince: json['memberSince'] != null
          ? DateTime.parse(json['memberSince'])
          : null,
      initials: json['initials'] ?? _getInitials(json['fullName'] ?? ''),
      city: json['city'],
      bio: json['bio'],
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'])
          : null,
      subscriptionInfo: json['subscriptionInfo'] != null
          ? Map<String, dynamic>.from(json['subscriptionInfo'])
          : null,
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'birthDate': birthDate?.toIso8601String(),
      'role': role,
      'isPremium': isPremium,
      'avatarUrl': avatarUrl,
      'memberSince': memberSince?.toIso8601String(),
      'initials': initials,
      'city': city,
      'bio': bio,
      'preferences': preferences,
      'subscriptionInfo': subscriptionInfo,
    };
  }

  /// Générer les initiales depuis le nom complet
  static String _getInitials(String fullName) {
    final parts = fullName.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (fullName.isNotEmpty) {
      return fullName.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  /// Formater la date de naissance
  String? get formattedBirthDate {
    if (birthDate == null) return null;
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(birthDate!);
  }

  /// Formater la date d'inscription
  String? get formattedMemberSince {
    if (memberSince == null) return null;
    return DateFormat('MMMM yyyy', 'fr_FR').format(memberSince!);
  }

  /// Formater l'âge
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Formater l'âge avec texte
  String? get formattedAge {
    if (age == null) return null;
    return '$age ans';
  }

  /// Formater le téléphone
  String? get formattedPhone {
    if (phone == null || phone!.isEmpty) return null;

    final digits = phone!.replaceAll(RegExp(r'[^\d+]'), '');

    if (digits.startsWith('+33')) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 5)} '
          '${digits.substring(5, 7)} ${digits.substring(7, 9)} '
          '${digits.substring(9, 11)} ${digits.substring(11)}';
    }

    return phone;
  }

  /// CORRIGÉ : Obtenir la durée en tant que membre
  String get membershipDuration {
    if (memberSince == null) return 'Nouveau membre';

    final now = DateTime.now();
    final duration = now.difference(memberSince!);

    if (duration.inDays >= 365) {
      final years = (duration.inDays / 365).floor();
      return years == 1 ? 'Membre depuis 1 an' : 'Membre depuis $years ans';
    } else if (duration.inDays >= 30) {
      final months = (duration.inDays / 30).floor();
      return months == 1
          ? 'Membre depuis 1 mois'
          : 'Membre depuis $months mois';
    } else if (duration.inDays >= 7) {
      final weeks = (duration.inDays / 7).floor();
      return weeks == 1
          ? 'Membre depuis 1 semaine'
          : 'Membre depuis $weeks semaines';
    } else if (duration.inDays > 0) {
      return duration.inDays == 1
          ? 'Membre depuis 1 jour'
          : 'Membre depuis ${duration.inDays} jours';
    }

    return 'Nouveau membre';
  }

  /// Copier avec modifications
  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? role,
    bool? isPremium,
    String? avatarUrl,
    DateTime? memberSince,
    String? initials,
    String? city,
    String? bio,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? subscriptionInfo,
  }) {
    return UserProfile(
      id: this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      isPremium: isPremium ?? this.isPremium,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberSince: memberSince ?? this.memberSince,
      initials: initials ?? this.initials,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      preferences: preferences ?? this.preferences,
      subscriptionInfo: subscriptionInfo ?? this.subscriptionInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.phone == phone &&
        other.birthDate == birthDate &&
        other.role == role &&
        other.isPremium == isPremium &&
        other.avatarUrl == avatarUrl &&
        other.memberSince == memberSince &&
        other.initials == initials &&
        other.city == city &&
        other.bio == bio &&
        mapEquals(other.preferences, preferences) &&
        mapEquals(other.subscriptionInfo, subscriptionInfo);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fullName,
      email,
      phone,
      birthDate,
      role,
      isPremium,
      avatarUrl,
      memberSince,
      initials,
      city,
      bio,
      Object.hashAll(preferences?.entries ?? []),
      Object.hashAll(subscriptionInfo?.entries ?? []),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, fullName: $fullName, email: $email, '
        'isPremium: $isPremium, role: $role)';
  }

  /// Vérifier si le profil est valide (a les informations minimales)
  bool get isValid =>
      id.toString().isNotEmpty && fullName.isNotEmpty && email.isNotEmpty;

  /// Obtenir les préférences de notification
  bool get notificationsEnabled {
    return preferences?['notifications']?['enabled'] ?? true;
  }

  /// Obtenir le thème préféré
  String get preferredTheme {
    return preferences?['theme'] ?? 'light';
  }

  /// Obtenir la langue préférée
  String get preferredLanguage {
    return preferences?['language'] ?? 'fr';
  }

  /// Obtenir la région préférée
  String get preferredRegion {
    return preferences?['region'] ?? 'FR';
  }

  /// Obtenir les catégories préférées
  List<String> get preferredCategories {
    final categories = preferences?['categories'];
    if (categories is List) {
      return categories.map((c) => c.toString()).toList();
    }
    return [];
  }

  /// Obtenir le niveau d'abonnement
  String get subscriptionLevel {
    return subscriptionInfo?['level'] ?? 'free';
  }

  /// Obtenir la date d'expiration de l'abonnement
  DateTime? get subscriptionExpiry {
    final expiry = subscriptionInfo?['expiry'];
    return expiry != null ? DateTime.parse(expiry) : null;
  }

  /// Vérifier si l'abonnement est actif
  bool get isSubscriptionActive {
    if (subscriptionExpiry == null) return false;
    return DateTime.now().isBefore(subscriptionExpiry!);
  }

  /// Vérifier si l'abonnement expire bientôt (dans les 7 jours)
  bool get isSubscriptionExpiringSoon {
    if (subscriptionExpiry == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = subscriptionExpiry!.difference(now).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  /// Formater la date d'expiration de l'abonnement
  String? get formattedSubscriptionExpiry {
    if (subscriptionExpiry == null) return null;
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(subscriptionExpiry!);
  }

  /// Vérifier si l'utilisateur peut accéder au contenu premium
  bool canAccessPremiumContent(String contentType) {
    if (!isPremium) return false;

    // Vérifier les restrictions par type de contenu
    final restrictions = subscriptionInfo?['restrictions'] ?? {};
    final allowedTypes = restrictions['allowed_content_types'] ?? [];

    return allowedTypes.contains(contentType) || allowedTypes.isEmpty;
  }

  /// Vérifier si l'utilisateur peut télécharger du contenu
  bool get canDownloadContent {
    return isPremium || (subscriptionInfo?['downloads_enabled'] ?? false);
  }

  /// Vérifier si l'utilisateur peut partager du contenu
  bool get canShareContent {
    return isPremium || (subscriptionInfo?['sharing_enabled'] ?? false);
  }

  /// Obtenir la limite de téléchargement
  int get downloadLimit {
    if (isPremium) return -1; // Illimité
    return subscriptionInfo?['download_limit'] ?? 10;
  }

  /// Obtenir les statistiques d'utilisation
  Map<String, dynamic> get usageStats {
    return {
      'sessions_this_month': preferences?['usage']?['sessions_this_month'] ?? 0,
      'total_minutes': preferences?['usage']?['total_minutes'] ?? 0,
      'favorite_category': preferences?['usage']?['favorite_category'],
      'last_active': preferences?['usage']?['last_active'],
    };
  }
}

/// Builder pour créer un UserProfile étape par étape
class UserProfileBuilder {
  int _id = 0;
  String _fullName = '';
  String _email = '';
  String? _phone;
  DateTime? _birthDate;
  String _role = 'user';
  bool _isPremium = false;
  String? _avatarUrl;
  DateTime? _memberSince;
  String _initials = 'U';
  String? _city;
  String? _bio;
  Map<String, dynamic>? _preferences;
  Map<String, dynamic>? _subscriptionInfo;

  UserProfileBuilder();

  UserProfileBuilder setBasicInfo({
    required int id,
    required String fullName,
    required String email,
  }) {
    _id = id;
    _fullName = fullName;
    _email = email;
    _initials = UserProfile._getInitials(fullName);
    return this;
  }

  UserProfileBuilder setContactInfo({
    String? phone,
    DateTime? birthDate,
    String? city,
  }) {
    _phone = phone;
    _birthDate = birthDate;
    _city = city;
    return this;
  }

  UserProfileBuilder setAccountInfo({
    String? role,
    bool? isPremium,
    DateTime? memberSince,
  }) {
    _role = role ?? _role;
    _isPremium = isPremium ?? _isPremium;
    _memberSince = memberSince ?? _memberSince;
    return this;
  }

  UserProfileBuilder setMedia({String? avatarUrl, String? bio}) {
    _avatarUrl = avatarUrl;
    _bio = bio;
    return this;
  }

  UserProfileBuilder setPreferences(Map<String, dynamic> preferences) {
    _preferences = preferences;
    return this;
  }

  UserProfileBuilder setSubscriptionInfo(
    Map<String, dynamic> subscriptionInfo,
  ) {
    _subscriptionInfo = subscriptionInfo;
    return this;
  }

  UserProfile build() {
    return UserProfile(
      id: _id,
      fullName: _fullName,
      email: _email,
      phone: _phone,
      birthDate: _birthDate,
      role: _role,
      isPremium: _isPremium,
      avatarUrl: _avatarUrl,
      memberSince: _memberSince ?? DateTime.now(),
      initials: _initials,
      city: _city,
      bio: _bio,
      preferences: _preferences,
      subscriptionInfo: _subscriptionInfo,
    );
  }
}

/// Extension pour les méthodes utilitaires
extension UserProfileUtils on UserProfile {
  /// Formater le nom pour l'affichage
  String get displayName {
    if (fullName.length > 20) {
      return '${fullName.substring(0, 20)}...';
    }
    return fullName;
  }

  /// Obtenir l'URL de l'avatar ou l'URL par défaut
  String get avatarUrlOrDefault {
    return avatarUrl ??
        'https://ui-avatars.com/api/?name=$initials&background=7DBBC3&color=fff&size=256';
  }

  /// Vérifier si l'utilisateur a complété son profil
  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        email.isNotEmpty &&
        phone?.isNotEmpty == true &&
        birthDate != null &&
        city?.isNotEmpty == true;
  }

  /// Score de complétion du profil (0-100)
  int get profileCompletionScore {
    var score = 0;

    if (fullName.isNotEmpty) score += 25;
    if (email.isNotEmpty) score += 25;
    if (phone?.isNotEmpty == true) score += 15;
    if (birthDate != null) score += 15;
    if (city?.isNotEmpty == true) score += 10;
    if (bio?.isNotEmpty == true) score += 10;

    return score;
  }

  /// Obtenir les prochaines étapes pour compléter le profil
  List<String> get profileCompletionSteps {
    final steps = <String>[];

    if (phone == null || phone!.isEmpty) {
      steps.add('Ajouter un numéro de téléphone');
    }

    if (birthDate == null) {
      steps.add('Ajouter votre date de naissance');
    }

    if (city == null || city!.isEmpty) {
      steps.add('Ajouter votre ville');
    }

    if (bio == null || bio!.isEmpty) {
      steps.add('Ajouter une biographie');
    }

    if (avatarUrl == null) {
      steps.add('Ajouter une photo de profil');
    }

    return steps;
  }

  /// Créer un résumé du profil pour l'affichage
  Map<String, dynamic> get profileSummary {
    return {
      'name': fullName,
      'email': email,
      'phone': formattedPhone ?? 'Non renseigné',
      'age': formattedAge ?? 'Non renseigné',
      'city': city ?? 'Non renseignée',
      'member_since': formattedMemberSince ?? 'Récemment',
      'subscription': isPremium ? 'Premium' : 'Standard',
      'profile_completion': '$profileCompletionScore%',
    };
  }

  /// Valider l'email
  bool get isEmailValid {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  /// Valider le téléphone
  bool get isPhoneValid {
    if (phone == null || phone!.isEmpty) return true;

    final phoneRegex = RegExp(r'^[+0-9\s\-\(\)]{10,20}$');
    final digits = phone!.replaceAll(RegExp(r'[^\d+]'), '');

    return phoneRegex.hasMatch(phone!) && digits.length >= 10;
  }

  /// Obtenir les données pour l'analytics
  Map<String, dynamic> get analyticsData {
    return {
      'user_id': id,
      'user_name': fullName,
      'user_email': email,
      'is_premium': isPremium,
      'role': role,
      'member_since': memberSince?.toIso8601String(),
      'profile_completion': profileCompletionScore,
      'preferred_theme': preferredTheme,
      'preferred_language': preferredLanguage,
    };
  }
}
