import 'app_config.dart';

/// API configuration and endpoint definitions
class ApiConfig {
  // Private constructor
  ApiConfig._();

  // Base Configuration
  static String get baseUrl => AppConfig.baseUrl;
  static String get apiVersion => 'v1';
  static String get fullBaseUrl => '$baseUrl/$apiVersion';

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': apiVersion,
    'X-Platform': 'mobile',
    'X-App-Version': AppConfig.appVersion,
  };

  // Timeout Configuration
  static Duration get connectTimeout => AppConfig.connectionTimeout;
  static Duration get receiveTimeout => AppConfig.receiveTimeout;
  static Duration get sendTimeout => AppConfig.sendTimeout;

  // Retry Configuration
  static int get maxRetries => AppConfig.maxRetryAttempts;
  static Duration get retryDelay => const Duration(seconds: 1);

  // Authentication Endpoints
  static class AuthEndpoints {
  static const String base = '/auth';
  static const String login = '$base/login';
  static const String register = '$base/register';
  static const String logout = '$base/logout';
  static const String refreshToken = '$base/refresh';
  static const String forgotPassword = '$base/forgot-password';
  static const String resetPassword = '$base/reset-password';
  static const String verifyEmail = '$base/verify-email';
  static const String resendVerification = '$base/resend-verification';
  static const String changePassword = '$base/change-password';
  static const String checkAuth = '$base/check';
  }

  // User Endpoints
  static class UserEndpoints {
  static const String base = '/users';
  static const String profile = '$base/profile';
  static const String updateProfile = '$base/profile';
  static const String deleteAccount = '$base/account';
  static const String uploadAvatar = '$base/avatar';
  static const String settings = '$base/settings';
  static const String preferences = '$base/preferences';
  }

  // Contact Endpoints
  static class ContactEndpoints {
  static const String base = '/contacts';
  static const String list = base;
  static const String create = base;
  static String byId(String id) => '$base/$id';
  static String update(String id) => '$base/$id';
  static String delete(String id) => '$base/$id';
  static const String search = '$base/search';
  static const String import = '$base/import';
  static const String export = '$base/export';
  }

  // Debt Endpoints
  static class DebtEndpoints {
  static const String base = '/debts';
  static const String list = base;
  static const String create = base;
  static String byId(String id) => '$base/$id';
  static String update(String id) => '$base/$id';
  static String delete(String id) => '$base/$id';
  static const String myDebts = '$base/my-debts';
  static const String theirDebts = '$base/their-debts';
  static const String overdue = '$base/overdue';
  static const String summary = '$base/summary';
  static const String statistics = '$base/statistics';
  static String markAsPaid(String id) => '$base/$id/mark-paid';
  static String addPayment(String id) => '$base/$id/payments';
  }

  // Payment Endpoints
  static class PaymentEndpoints {
  static const String base = '/payments';
  static const String list = base;
  static const String create = base;
  static String byId(String id) => '$base/$id';
  static String update(String id) => '$base/$id';
  static String delete(String id) => '$base/$id';
  static const String history = '$base/history';
  static const String summary = '$base/summary';
  static String byDebtId(String debtId) => '$base/debt/$debtId';
  }

  // File Upload Endpoints
  static class FileEndpoints {
  static const String base = '/files';
  static const String upload = '$base/upload';
  static const String download = '$base/download';
  static String byId(String id) => '$base/$id';
  static String delete(String id) => '$base/$id';
  }

  // Sync Endpoints
  static class SyncEndpoints {
  static const String base = '/sync';
  static const String full = '$base/full';
  static const String delta = '$base/delta';
  static const String push = '$base/push';
  static const String pull = '$base/pull';
  static const String status = '$base/status';
  }

  // Backup Endpoints
  static class BackupEndpoints {
  static const String base = '/backup';
  static const String create = '$base/create';
  static const String restore = '$base/restore';
  static const String list = '$base/list';
  static String download(String id) => '$base/$id/download';
  static String delete(String id) => '$base/$id';
  }

  // Notification Endpoints
  static class NotificationEndpoints {
  static const String base = '/notifications';
  static const String list = base;
  static const String register = '$base/register';
  static const String unregister = '$base/unregister';
  static String markAsRead(String id) => '$base/$id/read';
  static const String markAllAsRead = '$base/read-all';
  static const String settings = '$base/settings';
  }

  // Analytics Endpoints
  static class AnalyticsEndpoints {
  static const String base = '/analytics';
  static const String events = '$base/events';
  static const String track = '$base/track';
  static const String report = '$base/report';
  }

  // Health Check Endpoints
  static class HealthEndpoints {
  static const String ping = '/ping';
  static const String health = '/health';
  static const String version = '/version';
  }

  // HTTP Status Codes
  static class StatusCodes {
  // Success
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;

  // Redirection
  static const int notModified = 304;

  // Client Errors
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;

  // Server Errors
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;

  /// Check if status code indicates success
  static bool isSuccess(int statusCode) {
  return statusCode >= 200 && statusCode < 300;
  }

  /// Check if status code indicates client error
  static bool isClientError(int statusCode) {
  return statusCode >= 400 && statusCode < 500;
  }

  /// Check if status code indicates server error
  static bool isServerError(int statusCode) {
  return statusCode >= 500;
  }

  /// Check if status code indicates error
  static bool isError(int statusCode) {
  return statusCode >= 400;
  }
  }

  // Request Parameters
  static class RequestParams {
  static const String page = 'page';
  static const String limit = 'limit';
  static const String search = 'search';
  static const String sortBy = 'sort_by';
  static const String sortOrder = 'sort_order';
  static const String filter = 'filter';
  static const String include = 'include';
  static const String fields = 'fields';
  static const String expand = 'expand';
  }

  // Cache Configuration
  static class CacheConfig {
  static const String cacheControlHeader = 'Cache-Control';
  static const String etagHeader = 'ETag';
  static const String lastModifiedHeader = 'Last-Modified';
  static const String ifNoneMatchHeader = 'If-None-Match';
  static const String ifModifiedSinceHeader = 'If-Modified-Since';

  static const Duration shortCache = Duration(minutes: 5);
  static const Duration mediumCache = Duration(hours: 1);
  static const Duration longCache = Duration(hours: 24);
  }

  // Error Codes
  static class ErrorCodes {
  // Authentication
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String tokenInvalid = 'TOKEN_INVALID';
  static const String accountLocked = 'ACCOUNT_LOCKED';
  static const String emailNotVerified = 'EMAIL_NOT_VERIFIED';

  // Validation
  static const String validationError = 'VALIDATION_ERROR';
  static const String requiredField = 'REQUIRED_FIELD';
  static const String invalidFormat = 'INVALID_FORMAT';
  static const String duplicateEntry = 'DUPLICATE_ENTRY';

  // Resource
  static const String resourceNotFound = 'RESOURCE_NOT_FOUND';
  static const String resourceExists = 'RESOURCE_EXISTS';
  static const String insufficientPermissions = 'INSUFFICIENT_PERMISSIONS';

  // Network
  static const String networkError = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';
  static const String serverError = 'SERVER_ERROR';
  static const String serviceUnavailable = 'SERVICE_UNAVAILABLE';

  // Rate Limiting
  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  static const String quotaExceeded = 'QUOTA_EXCEEDED';
  }

  /// Build full URL from endpoint
  static String buildUrl(String endpoint) {
  if (endpoint.startsWith('http')) {
  return endpoint;
  }

  final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
  return '$fullBaseUrl/$cleanEndpoint';
  }

  /// Build query string from parameters
  static String buildQuery(Map<String, dynamic> params) {
  if (params.isEmpty) return '';

  final queryParams = params.entries
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
      .join('&');

  return queryParams.isNotEmpty ? '?$queryParams' : '';
  }

  /// Get headers with authentication
  static Map<String, String> getAuthHeaders(String? token) {
  final headers = Map<String, String>.from(defaultHeaders);
  if (token != null && token.isNotEmpty) {
  headers['Authorization'] = 'Bearer $token';
  }
  return headers;
  }
}