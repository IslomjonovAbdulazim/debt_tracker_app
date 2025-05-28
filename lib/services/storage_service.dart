import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/base/base_service.dart';
import '../shared/helpers/logger.dart';
import '../app/config/app_config.dart';

/// Service for managing local storage using SharedPreferences
class StorageService extends BaseService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  // Private constructor
  StorageService._();

  /// Get singleton instance
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Initialize the storage service
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('StorageService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize StorageService', e, stackTrace);
      rethrow;
    }
  }

  /// Check if storage is initialized
  static bool get isInitialized => _prefs != null;

  /// Ensure storage is initialized
  static void _ensureInitialized() {
    if (!isInitialized) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
  }

  // ==================== Basic Operations ====================

  /// Store a string value
  static Future<bool> setString(String key, String value) async {
    try {
      _ensureInitialized();
      final success = await _prefs!.setString(key, value);
      AppLogger.debug('Stored string: $key');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store string: $key', e, stackTrace);
      return false;
    }
  }

  /// Get a string value
  static String? getString(String key) {
    try {
      _ensureInitialized();
      return _prefs!.getString(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get string: $key', e, stackTrace);
      return null;
    }
  }

  /// Store an integer value
  static Future<bool> setInt(String key, int value) async {
    try {
      _ensureInitialized();
      final success = await _prefs!.setInt(key, value);
      AppLogger.debug('Stored int: $key = $value');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store int: $key', e, stackTrace);
      return false;
    }
  }

  /// Get an integer value
  static int? getInt(String key) {
    try {
      _ensureInitialized();
      return _prefs!.getInt(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get int: $key', e, stackTrace);
      return null;
    }
  }

  /// Store a double value
  static Future<bool> setDouble(String key, double value) async {
    try {
      _ensureInitialized();
      final success = await _prefs!.setDouble(key, value);
      AppLogger.debug('Stored double: $key = $value');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store double: $key', e, stackTrace);
      return false;
    }
  }

  /// Get a double value
  static double? getDouble(String key) {
    try {
      _ensureInitialized();
      return _prefs!.getDouble(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get double: $key', e, stackTrace);
      return null;
    }
  }

  /// Store a boolean value
  static Future<bool> setBool(String key, bool value) async {
    try {
      _ensureInitialized();
      final success = await _prefs!.setBool(key, value);
      AppLogger.debug('Stored bool: $key = $value');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store bool: $key', e, stackTrace);
      return false;
    }
  }

  /// Get a boolean value
  static bool? getBool(String key) {
    try {
      _ensureInitialized();
      return _prefs!.getBool(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get bool: $key', e, stackTrace);
      return null;
    }
  }

  /// Store a list of strings
  static Future<bool> setStringList(String key, List<String> value) async {
    try {
      _ensureInitialized();
      final success = await _prefs!.setStringList(key, value);
      AppLogger.debug('Stored string list: $key (${value.length} items)');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store string list: $key', e, stackTrace);
      return false;
    }
  }

  /// Get a list of strings
  static List<String>? getStringList(String key) {
    try {
      _ensureInitialized();
      return _prefs!.getStringList(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get string list: $key', e, stackTrace);
      return null;
    }
  }

  // ==================== JSON Operations ====================

  /// Store an object as JSON
  static Future<bool> setObject(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store object: $key', e, stackTrace);
      return false;
    }
  }

  /// Get an object from JSON
  static Map<String, dynamic>? getObject(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get object: $key', e, stackTrace);
      return null;
    }
  }

  /// Store a list of objects as JSON
  static Future<bool> setObjectList(String key, List<Map<String, dynamic>> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to store object list: $key', e, stackTrace);
      return false;
    }
  }

  /// Get a list of objects from JSON
  static List<Map<String, dynamic>>? getObjectList(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      final decoded = jsonDecode(jsonString) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get object list: $key', e, stackTrace);
      return null;
    }
  }

  // ==================== Advanced Operations ====================

  /// Check if a key exists
  static bool containsKey(String key) {
    try {
      _ensureInitialized();
      return _prefs!.containsKey(key);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check key existence: $key', e, stackTrace);
      return false;
    }
  }

  /// Remove a key
  static Future<bool> remove(String key) async {
    try {
      _ensureInitialized();
      final success = await _prefs!.remove(key);
      AppLogger.debug('Removed key: $key');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to remove key: $key', e, stackTrace);
      return false;
    }
  }

  /// Remove multiple keys
  static Future<bool> removeMultiple(List<String> keys) async {
    try {
      bool allSuccess = true;
      for (final key in keys) {
        final success = await remove(key);
        if (!success) allSuccess = false;
      }
      return allSuccess;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to remove multiple keys', e, stackTrace);
      return false;
    }
  }

  /// Clear all stored data
  static Future<bool> clear() async {
    try {
      _ensureInitialized();
      final success = await _prefs!.clear();
      AppLogger.info('Cleared all storage data');
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear storage', e, stackTrace);
      return false;
    }
  }

  /// Get all keys
  static Set<String> getAllKeys() {
    try {
      _ensureInitialized();
      return _prefs!.getKeys();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get all keys', e, stackTrace);
      return <String>{};
    }
  }

  // ==================== Authentication Storage ====================

  /// Store authentication token
  static Future<bool> setAuthToken(String token) async {
    return await setString(AppConfig.authTokenKey, token);
  }

  /// Get authentication token
  static String? getAuthToken() {
    return getString(AppConfig.authTokenKey);
  }

  /// Store refresh token
  static Future<bool> setRefreshToken(String token) async {
    return await setString(AppConfig.refreshTokenKey, token);
  }

  /// Get refresh token
  static String? getRefreshToken() {
    return getString(AppConfig.refreshTokenKey);
  }

  /// Clear authentication data
  static Future<bool> clearAuthData() async {
    final keys = [
      AppConfig.authTokenKey,
      AppConfig.refreshTokenKey,
      'user_data',
      'is_logged_in',
    ];
    return await removeMultiple(keys);
  }

  // ==================== User Data Storage ====================

  /// Store user data
  static Future<bool> setUserData(Map<String, dynamic> userData) async {
    return await setObject('user_data', userData);
  }

  /// Get user data
  static Map<String, dynamic>? getUserData() {
    return getObject('user_data');
  }

  /// Update user data partially
  static Future<bool> updateUserData(Map<String, dynamic> updates) async {
    try {
      final currentData = getUserData() ?? <String, dynamic>{};
      currentData.addAll(updates);
      return await setUserData(currentData);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user data', e, stackTrace);
      return false;
    }
  }

  // ==================== App Settings Storage ====================

  /// Store app settings
  static Future<bool> setAppSettings(Map<String, dynamic> settings) async {
    return await setObject('app_settings', settings);
  }

  /// Get app settings
  static Map<String, dynamic>? getAppSettings() {
    return getObject('app_settings');
  }

  /// Update app setting
  static Future<bool> updateAppSetting(String key, dynamic value) async {
    try {
      final settings = getAppSettings() ?? <String, dynamic>{};
      settings[key] = value;
      return await setAppSettings(settings);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update app setting: $key', e, stackTrace);
      return false;
    }
  }

  /// Get app setting
  static T? getAppSetting<T>(String key) {
    try {
      final settings = getAppSettings();
      return settings?[key] as T?;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get app setting: $key', e, stackTrace);
      return null;
    }
  }

  // ==================== Cache Management ====================

  /// Store cache data with expiry
  static Future<bool> setCache(String key, dynamic data, {Duration? expiry}) async {
    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiry': expiry?.inMilliseconds,
      };
      return await setObject('cache_$key', cacheData);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set cache: $key', e, stackTrace);
      return false;
    }
  }

  /// Get cache data if not expired
  static T? getCache<T>(String key) {
    try {
      final cacheData = getObject('cache_$key');
      if (cacheData == null) return null;

      final timestamp = cacheData['timestamp'] as int?;
      final expiryMs = cacheData['expiry'] as int?;

      if (timestamp != null && expiryMs != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp + expiryMs);
        if (DateTime.now().isAfter(expiryTime)) {
          // Cache expired, remove it
          remove('cache_$key');
          return null;
        }
      }

      return cacheData['data'] as T?;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache: $key', e, stackTrace);
      return null;
    }
  }

  /// Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    try {
      final allKeys = getAllKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith('cache_')).toList();

      for (final key in cacheKeys) {
        final cacheData = getObject(key);
        if (cacheData == null) continue;

        final timestamp = cacheData['timestamp'] as int?;
        final expiryMs = cacheData['expiry'] as int?;

        if (timestamp != null && expiryMs != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp + expiryMs);
          if (DateTime.now().isAfter(expiryTime)) {
            await remove(key);
          }
        }
      }

      AppLogger.info('Cleared expired cache entries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear expired cache', e, stackTrace);
    }
  }

  /// Clear all cache
  static Future<bool> clearAllCache() async {
    try {
      final allKeys = getAllKeys();
      final cacheKeys = allKeys.where((key) => key.startsWith('cache_')).toList();
      return await removeMultiple(cacheKeys);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear all cache', e, stackTrace);
      return false;
    }
  }

  // ==================== Debug & Utilities ====================

  /// Get storage statistics
  static Map<String, dynamic> getStorageStats() {
    try {
      _ensureInitialized();
      final allKeys = getAllKeys();
      final stats = <String, dynamic>{
        'totalKeys': allKeys.length,
        'authKeys': 0,
        'cacheKeys': 0,
        'userDataKeys': 0,
        'appSettingKeys': 0,
        'otherKeys': 0,
      };

      for (final key in allKeys) {
        if (key.contains('auth') || key.contains('token')) {
          stats['authKeys']++;
        } else if (key.startsWith('cache_')) {
          stats['cacheKeys']++;
        } else if (key.contains('user_data')) {
          stats['userDataKeys']++;
        } else if (key.contains('settings')) {
          stats['appSettingKeys']++;
        } else {
          stats['otherKeys']++;
        }
      }

      return stats;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get storage stats', e, stackTrace);
      return {};
    }
  }

  /// Export all data (for debugging)
  static Map<String, dynamic> exportAllData() {
    try {
      _ensureInitialized();
      final allKeys = getAllKeys();
      final exportData = <String, dynamic>{};

      for (final key in allKeys) {
        // Skip sensitive data in export
        if (key.contains('token') || key.contains('password')) {
          exportData[key] = '***HIDDEN***';
          continue;
        }

        final value = _prefs!.get(key);
        exportData[key] = value;
      }

      return exportData;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export data', e, stackTrace);
      return {};
    }
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}