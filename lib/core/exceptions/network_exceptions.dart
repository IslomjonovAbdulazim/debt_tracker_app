/// Network exception types
enum NetworkExceptionType {
  /// No internet connection
  noConnection,
  /// Request timeout
  timeout,
  /// Bad request (400)
  badRequest,
  /// Unauthorized (401)
  unauthorized,
  /// Forbidden (403)
  forbidden,
  /// Not found (404)
  notFound,
  /// Conflict (409)
  conflict,
  /// Validation error (422)
  validation,
  /// Rate limited (429)
  rateLimited,
  /// Server error (500+)
  serverError,
  /// Service unavailable (502, 503, 504)
  serviceUnavailable,
  /// JSON parse error
  parseError,
  /// Invalid request format
  invalidRequest,
  /// Unknown error
  unknown,
}

/// Network exception class
class NetworkException implements Exception {
  final String message;
  final NetworkExceptionType type;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;
  final Object? originalError;

  const NetworkException({
    required this.message,
    required this.type,
    this.statusCode,
    this.errorCode,
    this.details,
    this.originalError,
  });

  /// Create NetworkException from generic error
  factory NetworkException.fromError(Object error) {
    if (error is NetworkException) {
      return error;
    }

    String message = error.toString();
    NetworkExceptionType type = NetworkExceptionType.unknown;

    // Try to determine type from error message
    if (message.contains('timeout') || message.contains('TimeoutException')) {
      type = NetworkExceptionType.timeout;
    } else if (message.contains('network') || message.contains('connection')) {
      type = NetworkExceptionType.noConnection;
    } else if (message.contains('format') || message.contains('parsing')) {
      type = NetworkExceptionType.parseError;
    }

    return NetworkException(
      message: message,
      type: type,
      originalError: error,
    );
  }

  /// User-friendly error message
  String get userMessage {
    switch (type) {
      case NetworkExceptionType.noConnection:
        return 'Please check your internet connection and try again.';
      case NetworkExceptionType.timeout:
        return 'Request timed out. Please try again.';
      case NetworkExceptionType.unauthorized:
        return 'Please log in again to continue.';
      case NetworkExceptionType.forbidden:
        return 'You don\'t have permission to access this resource.';
      case NetworkExceptionType.notFound:
        return 'The requested resource was not found.';
      case NetworkExceptionType.validation:
        return 'Please check your input and try again.';
      case NetworkExceptionType.rateLimited:
        return 'Too many requests. Please wait and try again.';
      case NetworkExceptionType.serverError:
        return 'Server error. Please try again later.';
      case NetworkExceptionType.serviceUnavailable:
        return 'Service is temporarily unavailable. Please try again later.';
      case NetworkExceptionType.parseError:
        return 'Failed to process server response.';
      case NetworkExceptionType.badRequest:
      case NetworkExceptionType.conflict:
      case NetworkExceptionType.invalidRequest:
      case NetworkExceptionType.unknown:
      default:
        return message.isNotEmpty ? message : 'An unexpected error occurred.';
    }
  }

  /// Check if error is retryable
  bool get isRetryable {
    switch (type) {
      case NetworkExceptionType.timeout:
      case NetworkExceptionType.noConnection:
      case NetworkExceptionType.serverError:
      case NetworkExceptionType.serviceUnavailable:
        return true;
      case NetworkExceptionType.unauthorized:
      case NetworkExceptionType.forbidden:
      case NetworkExceptionType.notFound:
      case NetworkExceptionType.badRequest:
      case NetworkExceptionType.conflict:
      case NetworkExceptionType.validation:
      case NetworkExceptionType.rateLimited:
      case NetworkExceptionType.parseError:
      case NetworkExceptionType.invalidRequest:
      case NetworkExceptionType.unknown:
      default:
        return false;
    }
  }

  /// Check if error requires authentication
  bool get requiresAuth {
    return type == NetworkExceptionType.unauthorized;
  }

  @override
  String toString() {
    final buffer = StringBuffer('NetworkException: $message');

    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }

    if (errorCode != null) {
      buffer.write(' (Code: $errorCode)');
    }

    buffer.write(' [Type: $type]');

    return buffer.toString();
  }

  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'type': type.name,
      'status_code': statusCode,
      'error_code': errorCode,
      'details': details,
      'user_message': userMessage,
      'is_retryable': isRetryable,
      'requires_auth': requiresAuth,
    };
  }
}