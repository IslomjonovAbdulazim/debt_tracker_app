import '../../../core/base/base_model.dart';

/// User entity representing a user in the system
class UserEntity extends BaseModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final UserProfile? profile;
  final UserSettings? settings;
  final UserStatistics? statistics;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.profile,
    this.settings,
    this.statistics,
  });

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get display name (full name or email if names are empty)
  String get displayName {
    final name = fullName.trim();
    return name.isNotEmpty ? name : email;
  }

  /// Get initials for avatar
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last'.isNotEmpty ? '$first$last' : email[0].toUpperCase();
  }

  /// Check if user has complete profile
  bool get hasCompleteProfile {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        isVerified &&
        phoneNumber != null &&
        phoneNumber!.isNotEmpty;
  }

  /// Create from JSON
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: json['last_login_at'] != null || json['lastLoginAt'] != null
          ? DateTime.parse(json['last_login_at'] ?? json['lastLoginAt'])
          : null,
      profile: json['profile'] != null ? UserProfile.fromJson(json['profile']) : null,
      settings: json['settings'] != null ? UserSettings.fromJson(json['settings']) : null,
      statistics: json['statistics'] != null ? UserStatistics.fromJson(json['statistics']) : null,
    );
  }

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'profile': profile?.toJson(),
      'settings': settings?.toJson(),
      'statistics': statistics?.toJson(),
    };
  }

  /// Create copy with modified fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatarUrl,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    UserProfile? profile,
    UserSettings? settings,
    UserStatistics? statistics,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profile: profile ?? this.profile,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    phoneNumber,
    avatarUrl,
    isVerified,
    isActive,
    createdAt,
    updatedAt,
    lastLoginAt,
    profile,
    settings,
    statistics,
  ];
}

/// User profile containing additional information
class UserProfile extends BaseModel {
  final String? bio;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? country;
  final String? timezone;
  final String? language;
  final String? currency;
  final Map<String, dynamic>? preferences;

  const UserProfile({
    this.bio,
    this.dateOfBirth,
    this.address,
    this.city,
    this.country,
    this.timezone,
    this.language,
    this.currency,
    this.preferences,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      bio: json['bio'],
      dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      timezone: json['timezone'],
      language: json['language'],
      currency: json['currency'],
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'date_of_birth': dateOfBirth,
      'address': address,
      'city': city,
      'country': country,
      'timezone': timezone,
      'language': language,
      'currency': currency,
      'preferences': preferences,
    };
  }

  @override
  List<Object?> get props => [
    bio,
    dateOfBirth,
    address,
    city,
    country,
    timezone,
    language,
    currency,
    preferences,
  ];
}

/// User settings for app preferences
class UserSettings extends BaseModel {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool darkMode;
  final String language;
  final String currency;
  final bool biometricEnabled;
  final bool autoBackup;
  final int reminderDays;
  final Map<String, dynamic>? customSettings;

  const UserSettings({
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.darkMode = false,
    this.language = 'en',
    this.currency = 'USD',
    this.biometricEnabled = false,
    this.autoBackup = true,
    this.reminderDays = 3,
    this.customSettings,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notificationsEnabled: json['notifications_enabled'] ?? json['notificationsEnabled'] ?? true,
      emailNotifications: json['email_notifications'] ?? json['emailNotifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? json['pushNotifications'] ?? true,
      darkMode: json['dark_mode'] ?? json['darkMode'] ?? false,
      language: json['language'] ?? 'en',
      currency: json['currency'] ?? 'USD',
      biometricEnabled: json['biometric_enabled'] ?? json['biometricEnabled'] ?? false,
      autoBackup: json['auto_backup'] ?? json['autoBackup'] ?? true,
      reminderDays: json['reminder_days'] ?? json['reminderDays'] ?? 3,
      customSettings: json['custom_settings'] ?? json['customSettings'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'dark_mode': darkMode,
      'language': language,
      'currency': currency,
      'biometric_enabled': biometricEnabled,
      'auto_backup': autoBackup,
      'reminder_days': reminderDays,
      'custom_settings': customSettings,
    };
  }

  @override
  List<Object?> get props => [
    notificationsEnabled,
    emailNotifications,
    pushNotifications,
    darkMode,
    language,
    currency,
    biometricEnabled,
    autoBackup,
    reminderDays,
    customSettings,
  ];
}

/// User statistics for dashboard display
class UserStatistics extends BaseModel {
  final int totalContacts;
  final int totalDebts;
  final int activeDebts;
  final int overdueDebts;
  final double totalAmountOwed;
  final double totalAmountLent;
  final double totalPaid;
  final double totalReceived;
  final DateTime? lastActivity;

  const UserStatistics({
    this.totalContacts = 0,
    this.totalDebts = 0,
    this.activeDebts = 0,
    this.overdueDebts = 0,
    this.totalAmountOwed = 0.0,
    this.totalAmountLent = 0.0,
    this.totalPaid = 0.0,
    this.totalReceived = 0.0,
    this.lastActivity,
  });

  /// Net balance (amount lent - amount owed)
  double get netBalance => totalAmountLent - totalAmountOwed;

  /// Check if user is in debt overall
  bool get isInDebt => netBalance < 0;

  /// Check if user is a creditor overall
  bool get isCreditor => netBalance > 0;

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
        totalContacts: json['total_contacts'] ?? json['totalContacts'] ?? 0,
        totalDebts: json['total_debts'] ?? json['totalDebts'] ?? 0,
        activeDebts: json['active_debts'] ?? json['activeDebts'] ?? 0,
        overdueDebts: json['overdue_debts'] ?? json['overdueDebts'] ?? 0,
        totalAmountOwed: (json['total_amount_owed'] ?? json['totalAmountOwed'] ?? 0).toDouble(),
        totalAmountLent: (json['total_amount_lent'] ?? json['totalAmountLent'] ?? 0).toDouble(),
        totalPaid: (json['total_paid'] ?? json['totalPaid') ?? 0).toDouble(),
    totalReceived: (json['total_received'] ?? json['totalReceived'] ?? 0).toDouble(),
    lastActivity: json['last_activity'] != null || json['lastActivity'] != null
    ? DateTime.parse(json['last_activity'] ?? json['lastActivity'])
    : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'total_contacts': totalContacts,
      'total_debts': totalDebts,
      'active_debts': activeDebts,
      'overdue_debts': overdueDebts,
      'total_amount_owed': totalAmountOwed,
      'total_amount_lent': totalAmountLent,
      'total_paid': totalPaid,
      'total_received': totalReceived,
      'last_activity': lastActivity?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    totalContacts,
    totalDebts,
    activeDebts,
    overdueDebts,
    totalAmountOwed,
    totalAmountLent,
    totalPaid,
    totalReceived,
    lastActivity,
  ];
}