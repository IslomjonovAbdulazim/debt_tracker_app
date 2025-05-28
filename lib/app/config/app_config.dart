import 'package:flutter/foundation.dart';
import '../../core/enums/app_flavor.dart';

/// Application configuration constants and settings
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // App Information
  static const String appName = 'Debt Tracker';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String packageName = 'com.debttracker.app';

  // Environment Configuration
  static AppFlavor get flavor => _flavor;
  static AppFlavor _flavor = AppFlavor.development;

  static void setFlavor(AppFlavor flavor) {
    _flavor = flavor;
  }

  // Debug Configuration
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;
  static bool get isProfileMode => kProfileMode;
  static bool get showDebugBanner => isDebugMode;

  // API Configuration
  static String get baseUrl {
    switch (_flavor) {
      case AppFlavor.development:
        return 'http://10.0.2.2:8080/api'; // Android emulator localhost
      case AppFlavor.staging:
        return 'https://staging-api.debttracker.com/api';
      case AppFlavor.production:
        return 'https://api.debttracker.com/api';
    }
  }

  // Database Configuration
  static String get databaseName => 'debt_tracker.db';
  static int get databaseVersion => 1;

  // Cache Configuration
  static Duration get cacheExpiry => const Duration(hours: 24);
  static int get maxCacheSize => 100; // MB
  static String get cacheDirectory => 'cache';

  // Network Configuration
  static Duration get connectionTimeout => const Duration(seconds: 30);
  static Duration get receiveTimeout => const Duration(seconds: 30);
  static Duration get sendTimeout => const Duration(seconds: 30);
  static int get maxRetryAttempts => 3;

  // Authentication Configuration
  static Duration get tokenExpiry => const Duration(days: 30);
  static Duration get refreshTokenExpiry => const Duration(days: 90);
  static String get authTokenKey => 'auth_token';
  static String get refreshTokenKey => 'refresh_token';

  // Security Configuration
  static String get encryptionKey => _getEncryptionKey();
  static bool get enableBiometrics => true;
  static bool get enablePinLock => true;
  static int get maxLoginAttempts => 5;
  static Duration get lockoutDuration => const Duration(minutes: 15);

  // UI Configuration
  static Duration get animationDuration => const Duration(milliseconds: 300);
  static Duration get splashDuration => const Duration(seconds: 2);
  static double get borderRadius => 12.0;
  static double get defaultPadding => 16.0;
  static double get smallPadding => 8.0;
  static double get largePadding => 24.0;

  // Pagination Configuration
  static int get defaultPageSize => 20;
  static int get maxPageSize => 100;

  // Notification Configuration
  static bool get enablePushNotifications => true;
  static bool get enableLocalNotifications => true;
  static String get fcmTopicPrefix => 'debt_tracker_';

  // File Configuration
  static List<String> get allowedImageExtensions => ['jpg', 'jpeg', 'png', 'gif'];
  static List<String> get allowedDocumentExtensions => ['pdf', 'doc', 'docx'];
  static int get maxFileSize => 10 * 1024 * 1024; // 10MB
  static String get uploadsDirectory => 'uploads';

  // Analytics Configuration
  static bool get enableAnalytics => !isDebugMode;
  static bool get enableCrashlytics => !isDebugMode;
  static bool get enablePerformanceMonitoring => !isDebugMode;

  // Feature Flags
  static bool get enableOfflineMode => true;
  static bool get enableDarkMode => true;
  static bool get enableBiometricAuth => true;
  static bool get enableExportFeature => true;
  static bool get enableBackupFeature => true;
  static bool get enableSyncFeature => true;

  // Validation Rules
  static int get minPasswordLength => 8;
  static int get maxPasswordLength => 128;
  static int get minUsernameLength => 3;
  static int get maxUsernameLength => 50;
  static RegExp get emailRegex => RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  static RegExp get phoneRegex => RegExp(
      r'^\+?[1-9]\d{1,14}$'
  );

  // Currency Configuration
  static String get defaultCurrency => 'USD';
  static List<String> get supportedCurrencies => [
    'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY', 'INR', 'RUB'
  ];

  // Localization Configuration
  static List<String> get supportedLanguages => ['en', 'ru', 'uz'];
  static String get defaultLanguage => 'en';

  // Backup Configuration
  static Duration get autoBackupInterval => const Duration(days: 7);
  static int get maxBackupFiles => 10;
  static String get backupFilePrefix => 'debt_tracker_backup_';

  // Sync Configuration
  static Duration get syncInterval => const Duration(minutes: 15);
  static int get maxSyncRetries => 3;
  static Duration get syncTimeout => const Duration(minutes: 5);

  // Debt Configuration
  static double get maxDebtAmount => 1000000.0; // 1 million
  static double get minDebtAmount => 0.01;
  static int get maxDebtDescriptionLength => 500;
  static Duration get defaultDebtDuration => const Duration(days: 30);

  // Contact Configuration
  static int get maxContactNameLength => 100;
  static int get maxContactNotes => 1000;

  // Search Configuration
  static int get searchMinLength => 2;
  static Duration get searchDebounceDelay => const Duration(milliseconds: 500);
  static int get maxSearchResults => 50;

  /// Get environment-specific encryption key
  static String _getEncryptionKey() {
    switch (_flavor) {
      case AppFlavor.development:
        return 'dev_encryption_key_32_characters_';
      case AppFlavor.staging:
        return 'stg_encryption_key_32_characters_';
      case AppFlavor.production:
        return 'prod_encryption_key_32_characters';
    }
  }

  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    switch (feature.toLowerCase()) {
      case 'offline_mode':
        return enableOfflineMode;
      case 'dark_mode':
        return enableDarkMode;
      case 'biometric_auth':
        return enableBiometricAuth;
      case 'export':
        return enableExportFeature;
      case 'backup':
        return enableBackupFeature;
      case 'sync':
        return enableSyncFeature;
      case 'analytics':
        return enableAnalytics;
      case 'crashlytics':
        return enableCrashlytics;
      case 'performance_monitoring':
        return enablePerformanceMonitoring;
      case 'push_notifications':
        return enablePushNotifications;
      case 'local_notifications':
        return enableLocalNotifications;
      default:
        return false;
    }
  }

  /// Get configuration as Map for debugging
  static Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'flavor': flavor.name,
      'isDebugMode': isDebugMode,
      'baseUrl': baseUrl,
      'databaseName': databaseName,
      'enableOfflineMode': enableOfflineMode,
      'enableDarkMode': enableDarkMode,
      'enableAnalytics': enableAnalytics,
      'supportedLanguages': supportedLanguages,
      'supportedCurrencies': supportedCurrencies,
    };
  }
}