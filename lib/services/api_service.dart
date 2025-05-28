import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../app/config/api_config.dart';
import '../app/config/app_config.dart';
import '../core/exceptions/network_exceptions.dart';
import '../core/base/base_service.dart';
import '../shared/helpers/logger.dart';
import 'storage_service.dart';

/// HTTP API service for making network requests
class ApiService extends BaseService {
  static ApiService? _instance;
  late http.Client _client;
  Timer? _tokenRefreshTimer;

  // Private constructor
  ApiService._() {
    _client = http.Client();
    _setupTokenRefreshTimer();
  }

  /// Get singleton instance
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  /// Setup automatic token refresh
  void _setupTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 30),
          (_) => _refreshTokenIfNeeded(),
    );
  }

  /// Check and refresh token if needed
  Future<void> _refreshTokenIfNeeded() async {
    try {
      final token = StorageService.getAuthToken();
      if (token == null) return;

      // Check if token is about to expire (simplified check)
      final response = await get(
        ApiConfig.AuthEndpoints.checkAuth,
        useAuth: true,
      );

      if (response['status'] == 'token_expired') {
        await _refreshAuthToken();
      }
    } catch (e) {
      AppLogger.error('Token refresh check failed', e);
    }
  }

  /// Refresh authentication token
  Future<void> _refreshAuthToken() async {
    try {
      final refreshToken = StorageService.getRefreshToken();
      if (refreshToken == null) return;

      final response = await post(
        ApiConfig.AuthEndpoints.refreshToken,
        {'refresh_token': refreshToken},
        useAuth: false,
      );

      if (response['success'] == true) {
        await StorageService.setAuthToken(response['data']['access_token']);
        if (response['data']['refresh_token'] != null) {
          await StorageService.setRefreshToken(response['data']['refresh_token']);
        }
      }
    } catch (e) {
      AppLogger.error('Token refresh failed', e);
      // Logout user if refresh fails
      await StorageService.clearAuthData();
    }
  }

  // ==================== HTTP Methods ====================

  /// GET request
  Future<Map<String, dynamic>> get(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        Map<String, String>? headers,
        bool useAuth = true,
        Duration? timeout,
      }) async {
    return _makeRequest(
      'GET',
      endpoint,
      queryParams: queryParams,
      headers: headers,
      useAuth: useAuth,
      timeout: timeout,
    );
  }

  /// POST request
  Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> data, {
        Map<String, String>? headers,
        bool useAuth = true,
        Duration? timeout,
      }) async {
    return _makeRequest(
      'POST',
      endpoint,
      data: data,
      headers: headers,
      useAuth: useAuth,
      timeout: timeout,
    );
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> data, {
        Map<String, String>? headers,
        bool useAuth = true,
        Duration? timeout,
      }) async {
    return _makeRequest(
      'PUT',
      endpoint,
      data: data,
      headers: headers,
      useAuth: useAuth,
      timeout: timeout,
    );
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
      String endpoint,
      Map<String, dynamic> data, {
        Map<String, String>? headers,
        bool useAuth = true,
        Duration? timeout,
      }) async {
    return _makeRequest(
      'PATCH',
      endpoint,
      data: data,
      headers: headers,
      useAuth: useAuth,
      timeout: timeout,
    );
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(
      String endpoint, {
        Map<String, dynamic>? data,
        Map<String, String>? headers,
        bool useAuth = true,
        Duration? timeout,
      }) async {
    return _makeRequest(
      'DELETE',
      endpoint,
      data: data,
      headers: headers,
      useAuth: useAuth,
      timeout: timeout,
    );
  }

  // ==================== Core Request Method ====================

  /// Make HTTP request with retry logic
  Future<Map<String, dynamic>> _makeRequest(
      String method,
      String endpoint, {
        Map<String, dynamic>? data,
        Map<String, dynamic>? queryParams,
        Map<String, String>? headers,
        bool useAuth = true,
        Duration? timeout,
      }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < ApiConfig.maxRetries) {
      try {
        attempts++;

        final response = await _executeRequest(
          method,
          endpoint,
          data: data,
          queryParams: queryParams,
          headers: headers,
          useAuth: useAuth,
          timeout: timeout ?? ApiConfig.receiveTimeout,
        );

        return _handleResponse(response);
      } on NetworkException catch (e) {
        lastException = e;
        AppLogger.warning('Request failed (attempt $attempts): ${e.message}');

        // Don't retry for certain errors
        if (e.type == NetworkExceptionType.unauthorized ||
            e.type == NetworkExceptionType.forbidden ||
            e.type == NetworkExceptionType.notFound ||
            e.type == NetworkExceptionType.validation) {
          break;
        }

        // Wait before retry
        if (attempts < ApiConfig.maxRetries) {
          await Future.delayed(ApiConfig.retryDelay * attempts);
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        AppLogger.error('Request error (attempt $attempts)', e);

        if (attempts < ApiConfig.maxRetries) {
          await Future.delayed(ApiConfig.retryDelay * attempts);
        }
      }
    }

    // All attempts failed
    throw lastException ?? NetworkException(
      message: 'Request failed after $attempts attempts',
      type: NetworkExceptionType.unknown,
    );
  }

  /// Execute single HTTP request
  Future<http.Response> _executeRequest(
      String method,
      String endpoint, {
        Map<String, dynamic>? data,
        Map<String, dynamic>? queryParams,
        Map<String, String>? headers,
        bool useAuth = true,
        required Duration timeout,
      }) async {
    // Build URL
    final url = _buildUrl(endpoint, queryParams);

    // Build headers
    final requestHeaders = _buildHeaders(headers, useAuth);

    // Log request
    AppLogger.debug('$method $url');
    if (data != null && AppConfig.isDebugMode) {
      AppLogger.debug('Request body: ${jsonEncode(data)}');
    }

    // Make request
    late http.Response response;
    final uri = Uri.parse(url);

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: requestHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: requestHeaders,
            body: data != null ? jsonEncode(data) : null,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: requestHeaders,
            body: data != null ? jsonEncode(data) : null,
          ).timeout(timeout);
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: requestHeaders,
            body: data != null ? jsonEncode(data) : null,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await _client.delete(
            uri,
            headers: requestHeaders,
            body: data != null ? jsonEncode(data) : null,
          ).timeout(timeout);
          break;
        default:
          throw NetworkException(
            message: 'Unsupported HTTP method: $method',
            type: NetworkExceptionType.invalidRequest,
          );
      }
    } on TimeoutException {
      throw NetworkException(
        message: 'Request timeout',
        type: NetworkExceptionType.timeout,
      );
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Network error: ${e.message}',
        type: NetworkExceptionType.noConnection,
      );
    } on HttpException catch (e) {
      throw NetworkException(
        message: 'HTTP error: ${e.message}',
        type: NetworkExceptionType.serverError,
      );
    }

    return response;
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    // Log response
    AppLogger.debug('Response ${response.statusCode}: ${response.request?.url}');
    if (AppConfig.isDebugMode && response.body.isNotEmpty) {
      AppLogger.debug('Response body: ${response.body}');
    }

    // Parse response body
    Map<String, dynamic> responseData;
    try {
      responseData = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : {};
    } catch (e) {
      throw NetworkException(
        message: 'Invalid JSON response',
        type: NetworkExceptionType.parseError,
        statusCode: response.statusCode,
      );
    }

    // Handle different status codes
    if (ApiConfig.StatusCodes.isSuccess(response.statusCode)) {
      return responseData;
    }

    // Handle error responses
    final errorMessage = responseData['message'] ??
        responseData['error'] ??
        'Request failed';

    final errorCode = responseData['code'] ??
        responseData['error_code'];

    throw NetworkException(
      message: errorMessage,
      type: _getExceptionType(response.statusCode),
      statusCode: response.statusCode,
      errorCode: errorCode,
      details: responseData,
    );
  }

  /// Get exception type from status code
  NetworkExceptionType _getExceptionType(int statusCode) {
    switch (statusCode) {
      case 400:
        return NetworkExceptionType.badRequest;
      case 401:
        return NetworkExceptionType.unauthorized;
      case 403:
        return NetworkExceptionType.forbidden;
      case 404:
        return NetworkExceptionType.notFound;
      case 409:
        return NetworkExceptionType.conflict;
      case 422:
        return NetworkExceptionType.validation;
      case 429:
        return NetworkExceptionType.rateLimited;
      case 500:
        return NetworkExceptionType.serverError;
      case 502:
      case 503:
      case 504:
        return NetworkExceptionType.serviceUnavailable;
      default:
        return NetworkExceptionType.unknown;
    }
  }

  // ==================== Helper Methods ====================

  /// Build full URL with query parameters
  String _buildUrl(String endpoint, Map<String, dynamic>? queryParams) {
    final baseUrl = ApiConfig.buildUrl(endpoint);
    final queryString = queryParams != null
        ? ApiConfig.buildQuery(queryParams)
        : '';
    return baseUrl + queryString;
  }

  /// Build request headers
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders, bool useAuth) {
    final token = useAuth ? StorageService.getAuthToken() : null;
    final headers = ApiConfig.getAuthHeaders(token);

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  // ==================== File Upload ====================

  /// Upload file
  Future<Map<String, dynamic>> uploadFile(
      String endpoint,
      String filePath,
      String fieldName, {
        Map<String, dynamic>? data,
        Map<String, String>? headers,
        bool useAuth = true,
        void Function(double progress)? onProgress,
      }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      final uri = Uri.parse(url);

      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final requestHeaders = _buildHeaders(headers, useAuth);
      request.headers.addAll(requestHeaders);

      // Add file
      final file = await http.MultipartFile.fromPath(fieldName, filePath);
      request.files.add(file);

      // Add additional data
      if (data != null) {
        data.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }

      AppLogger.debug('Uploading file: $filePath to $url');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      AppLogger.error('File upload failed', e);
      rethrow;
    }
  }

  /// Download file
  Future<List<int>> downloadFile(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        Map<String, String>? headers,
        bool useAuth = true,
        void Function(double progress)? onProgress,
      }) async {
    try {
      final url = _buildUrl(endpoint, queryParams);
      final requestHeaders = _buildHeaders(headers, useAuth);

      AppLogger.debug('Downloading file from: $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      if (!ApiConfig.StatusCodes.isSuccess(response.statusCode)) {
        throw NetworkException(
          message: 'Download failed',
          type: _getExceptionType(response.statusCode),
          statusCode: response.statusCode,
        );
      }

      return response.bodyBytes;
    } catch (e) {
      AppLogger.error('File download failed', e);
      rethrow;
    }
  }

  // ==================== Batch Operations ====================

  /// Execute multiple requests concurrently
  Future<List<Map<String, dynamic>>> batchRequests(
      List<Future<Map<String, dynamic>>> requests, {
        bool failFast = false,
      }) async {
    try {
      if (failFast) {
        return await Future.wait(requests);
      } else {
        final results = await Future.wait(
          requests.map((request) async {
            try {
              return await request;
            } catch (e) {
              AppLogger.error('Batch request failed', e);
              return <String, dynamic>{'error': e.toString()};
            }
          }),
        );
        return results;
      }
    } catch (e) {
      AppLogger.error('Batch requests failed', e);
      rethrow;
    }
  }

  // ==================== Health Check ====================

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await get(
        ApiConfig.HealthEndpoints.health,
        useAuth: false,
        timeout: const Duration(seconds: 10),
      );
      return response['status'] == 'ok' || response['healthy'] == true;
    } catch (e) {
      AppLogger.error('Health check failed', e);
      return false;
    }
  }

  /// Ping server
  Future<Duration?> pingServer() async {
    try {
      final startTime = DateTime.now();
      await get(
        ApiConfig.HealthEndpoints.ping,
        useAuth: false,
        timeout: const Duration(seconds: 5),
      );
      final endTime = DateTime.now();
      return endTime.difference(startTime);
    } catch (e) {
      AppLogger.error('Ping failed', e);
      return null;
    }
  }

  // ==================== Cache Management ====================

  /// Get data with cache support
  Future<Map<String, dynamic>> getCached(
      String endpoint, {
        Map<String, dynamic>? queryParams,
        Duration? cacheExpiry,
        bool forceRefresh = false,
      }) async {
    final cacheKey = _buildCacheKey(endpoint, queryParams);

    // Try to get from cache first
    if (!forceRefresh) {
      final cachedData = StorageService.getCache<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        AppLogger.debug('Cache hit for: $endpoint');
        return cachedData;
      }
    }

    // Fetch from network
    final response = await get(endpoint, queryParams: queryParams);

    // Store in cache
    await StorageService.setCache(
      cacheKey,
      response,
      expiry: cacheExpiry ?? ApiConfig.CacheConfig.mediumCache,
    );

    AppLogger.debug('Cache stored for: $endpoint');
    return response;
  }

  /// Build cache key from endpoint and params
  String _buildCacheKey(String endpoint, Map<String, dynamic>? params) {
    final baseKey = endpoint.replaceAll('/', '_').replaceAll('?', '_');
    if (params == null || params.isEmpty) {
      return baseKey;
    }

    final sortedParams = params.keys.toList()..sort();
    final paramString = sortedParams
        .map((key) => '${key}_${params[key]}')
        .join('_');

    return '${baseKey}_$paramString';
  }

  // ==================== Request Cancellation ====================

  final Map<String, Timer> _pendingRequests = {};

  /// Cancel pending request
  void cancelRequest(String requestId) {
    _pendingRequests[requestId]?.cancel();
    _pendingRequests.remove(requestId);
  }

  /// Cancel all pending requests
  void cancelAllRequests() {
    for (final timer in _pendingRequests.values) {
      timer.cancel();
    }
    _pendingRequests.clear();
  }

  // ==================== Network Status ====================

  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  /// Stream of network connectivity status
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Update network status
  void updateNetworkStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(isOnline);
      AppLogger.info('Network status changed: ${isOnline ? 'online' : 'offline'}');
    }
  }

  // ==================== Request Interceptors ====================

  final List<RequestInterceptor> _requestInterceptors = [];
  final List<ResponseInterceptor> _responseInterceptors = [];

  /// Add request interceptor
  void addRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
  }

  /// Add response interceptor
  void addResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
  }

  /// Apply request interceptors
  Future<void> _applyRequestInterceptors(
      String method,
      String url,
      Map<String, String> headers,
      Map<String, dynamic>? data,
      ) async {
    for (final interceptor in _requestInterceptors) {
      await interceptor.onRequest(method, url, headers, data);
    }
  }

  /// Apply response interceptors
  Future<void> _applyResponseInterceptors(
      http.Response response,
      Map<String, dynamic> data,
      ) async {
    for (final interceptor in _responseInterceptors) {
      await interceptor.onResponse(response, data);
    }
  }

  // ==================== Debug & Monitoring ====================

  /// Get API statistics
  Map<String, dynamic> getApiStats() {
    return {
      'baseUrl': ApiConfig.baseUrl,
      'isOnline': _isOnline,
      'pendingRequests': _pendingRequests.length,
      'requestInterceptors': _requestInterceptors.length,
      'responseInterceptors': _responseInterceptors.length,
      'tokenPresent': StorageService.getAuthToken() != null,
    };
  }

  /// Log API configuration
  void logConfiguration() {
    if (AppConfig.isDebugMode) {
      AppLogger.info('API Configuration:');
      AppLogger.info('Base URL: ${ApiConfig.baseUrl}');
      AppLogger.info('Connect Timeout: ${ApiConfig.connectTimeout}');
      AppLogger.info('Receive Timeout: ${ApiConfig.receiveTimeout}');
      AppLogger.info('Max Retries: ${ApiConfig.maxRetries}');
    }
  }

  // ==================== Cleanup ====================

  @override
  void onClose() {
    _tokenRefreshTimer?.cancel();
    _client.close();
    _connectivityController.close();
    cancelAllRequests();
    super.onClose();
  }
}

// ==================== Interceptor Interfaces ====================

/// Request interceptor interface
abstract class RequestInterceptor {
  Future<void> onRequest(
      String method,
      String url,
      Map<String, String> headers,
      Map<String, dynamic>? data,
      );
}

/// Response interceptor interface
abstract class ResponseInterceptor {
  Future<void> onResponse(
      http.Response response,
      Map<String, dynamic> data,
      );
}

// ==================== Example Interceptors ====================

/// Logging request interceptor
class LoggingRequestInterceptor implements RequestInterceptor {
  @override
  Future<void> onRequest(
      String method,
      String url,
      Map<String, String> headers,
      Map<String, dynamic>? data,
      ) async {
    AppLogger.debug('→ $method $url');
    if (data != null && AppConfig.isDebugMode) {
      AppLogger.debug('→ Body: ${jsonEncode(data)}');
    }
  }
}

/// Logging response interceptor
class LoggingResponseInterceptor implements ResponseInterceptor {
  @override
  Future<void> onResponse(
      http.Response response,
      Map<String, dynamic> data,
      ) async {
    AppLogger.debug('← ${response.statusCode} ${response.request?.url}');
    if (AppConfig.isDebugMode && data.isNotEmpty) {
      AppLogger.debug('← Body: ${jsonEncode(data)}');
    }
  }
}

/// Analytics request interceptor
class AnalyticsRequestInterceptor implements RequestInterceptor {
  @override
  Future<void> onRequest(
      String method,
      String url,
      Map<String, String> headers,
      Map<String, dynamic>? data,
      ) async {
    // Track API requests for analytics
    // Implementation would depend on your analytics service
  }
}

/// Performance monitoring interceptor
class PerformanceInterceptor implements RequestInterceptor, ResponseInterceptor {
  final Map<String, DateTime> _requestTimes = {};

  @override
  Future<void> onRequest(
      String method,
      String url,
      Map<String, String> headers,
      Map<String, dynamic>? data,
      ) async {
    _requestTimes[url] = DateTime.now();
  }

  @override
  Future<void> onResponse(
      http.Response response,
      Map<String, dynamic> data,
      ) async {
    final url = response.request?.url.toString();
    if (url != null && _requestTimes.containsKey(url)) {
      final startTime = _requestTimes.remove(url)!;
      final duration = DateTime.now().difference(startTime);

      if (duration.inMilliseconds > 3000) {
        AppLogger.warning('Slow API request: $url took ${duration.inMilliseconds}ms');
      }
    }
  }
}