import 'network_exceptions.dart';

/// Authentication exception types
enum AuthExceptionType {
  /// Invalid credentials
  invalidCredentials,
  /// Account not found
  accountNotFound,
  /// Account locked
  accountLocked,
  /// Account disabled
  accountDisabled,
  /// Email not verified
  emailNotVerified,
  /// Token expired
  tokenExpired,
  /// Token invalid
  tokenInvalid,
  /// No token available
  noToken,
  /// User not authenticated
  notAuthenticated,
  /// Password too weak
  weakPassword,
  /// Email already exists
  emailExists,
  /// Registration failed
  registrationFailed,
  /// Verification failed
  verificationFailed,
  /// Password reset failed
  passwordResetFailed,
  /// Two-factor authentication required
  twoFactorRequired,
  /// Social login failed
  socialLoginFailed,
  /// Biometric authentication failed
  biometricFailed,
  /// Unknown authentication error
  unknown,
}

/// Authentication exception class
class AuthException implements Exception {
  final String message;
  final AuthExceptionType type;
  final String? errorCode;
  final Map<String, dynamic>? details;
  final Object? originalError;

  const AuthException({
    required this.message,
    required this.type,
    this.errorCode,
    this.details,
    this.originalError,
  });

  /// Create AuthException from generic error
  factory AuthException.fromError(Object error) {
    if (error is AuthException) {
      return error;
    }

    if (error is NetworkException) {
      return _fromNetworkException(error);
    }

    String message = error.toString();
    AuthExceptionType type = AuthExceptionType.unknown;

    // Try to determine type from error message
    if (message.contains('credential') || message.contains('password')) {
      type = AuthExceptionType.invalidCredentials;
    } else if (message.contains('token')) {
      type = AuthExceptionType.tokenInvalid;
    } else if (message.contains('email')) {
      type = AuthExceptionType.emailNotVerified;
    } else if (message.contains('locked')) {
      type = AuthExceptionType.accountLocked;
    }

    return AuthException(
      message: message,
      type: type,
      originalError: error,
    );
  }

  /// Create from NetworkException
  static AuthException _fromNetworkException(NetworkException networkError) {
    AuthExceptionType type;
    String message = networkError.message;

    switch (networkError.type) {
      case NetworkExceptionType.unauthorized:
        if (networkError.errorCode == 'TOKEN_EXPIRED') {
          type = AuthExceptionType.tokenExpired;
        } else if (networkError.errorCode == 'TOKEN_INVALID') {
          type = AuthExceptionType.tokenInvalid;
        } else if (networkError.errorCode == 'INVALID_CREDENTIALS') {
          type = AuthExceptionType.invalidCredentials;
        } else {
          type = AuthExceptionType.notAuthenticated;
        }
        break;
      case NetworkExceptionType.forbidden:
        type = AuthExceptionType.accountLocked;
        break;
      case NetworkExceptionType.notFound:
        type = AuthExceptionType.accountNotFound;
        break;
      case NetworkExceptionType.conflict:
        type = AuthExceptionType.emailExists;
        break;
      case NetworkExceptionType.validation:
      // Check validation details
        if (networkError.details?['field'] == 'password') {
          type = AuthExceptionType.weakPassword;
        } else if (networkError.details?['field'] == 'email') {
          type = AuthExceptionType.emailNotVerified;
        } else {
          type = AuthExceptionType.unknown;
        }
        break;
      default:
        type = AuthExceptionType.unknown;
    }

    return AuthException(
      message: message,
      type: type,
      errorCode: networkError.errorCode,
      details: networkError.details,
      originalError: networkError,
    );
  }

  /// Predefined exceptions
  static const AuthException invalidCredentials = AuthException(
    message: 'Invalid email or password',
    type: AuthExceptionType.invalidCredentials,
  );

  static const AuthException tokenExpired = AuthException(
    message: 'Your session has expired. Please log in again.',
    type: AuthExceptionType.tokenExpired,
  );

  static const AuthException notAuthenticated = AuthException(
    message: 'Please log in to continue',
    type: AuthExceptionType.notAuthenticated,
  );

  static const AuthException emailNotVerified = AuthException(
    message: 'Please verify your email address',
    type: AuthExceptionType.emailNotVerified,
  );

  static const AuthException accountLocked = AuthException(
    message: 'Your account has been locked. Please contact support.',
    type: AuthExceptionType.accountLocked,
  );

  static const AuthException weakPassword = AuthException(
    message: 'Password is too weak. Please choose a stronger password.',
    type: AuthExceptionType.weakPassword,
  );

  static const AuthException emailExists = AuthException(
    message: 'An account with this email already exists',
    type: AuthExceptionType.emailExists,
  );

  /// User-friendly error message
  String get userMessage {
    switch (type) {
      case AuthExceptionType.invalidCredentials:
        return 'Invalid email or password. Please try again.';
      case AuthExceptionType.accountNotFound:
        return 'No account found with this email address.';
      case AuthExceptionType.accountLocked:
        return 'Your account has been temporarily locked. Please try again later or contact support.';
      case AuthExceptionType.accountDisabled:
        return 'Your account has been disabled. Please contact support.';
      case AuthExceptionType.emailNotVerified:
        return 'Please verify your email address before continuing.';
      case AuthExceptionType.tokenExpired:
        return 'Your session has expired. Please log in again.';
      case AuthExceptionType.tokenInvalid:
        return 'Authentication failed. Please log in again.';
      case AuthExceptionType.noToken:
        return 'Please log in to continue.';
      case AuthExceptionType.notAuthenticated:
        return 'Please log in to access this feature.';
      case AuthExceptionType.weakPassword:
        return 'Password must be at least 8 characters long and include uppercase, lowercase, numbers, and special characters.';
      case AuthExceptionType.emailExists:
        return 'An account with this email already exists. Please use a different email or try logging in.';
      case AuthExceptionType.registrationFailed:
        return 'Registration failed. Please try again.';
      case AuthExceptionType.verificationFailed:
        return 'Email verification failed. Please check your verification code.';
      case AuthExceptionType.passwordResetFailed:
        return 'Password reset failed. Please try again or contact support.';
      case AuthExceptionType.twoFactorRequired:
        return 'Two-factor authentication is required.';
      case AuthExceptionType.socialLoginFailed:
        return 'Social login failed. Please try again or use email/password.';
      case AuthExceptionType.biometricFailed:
        return 'Biometric authentication failed. Please try again or use your password.';
      case AuthExceptionType.unknown:
      default:
        return message.isNotEmpty ? message : 'An authentication error occurred.';
    }
  }

  /// Check if error requires user action
  bool get requiresUserAction {
    switch (type) {
      case AuthExceptionType.emailNotVerified:
      case AuthExceptionType.tokenExpired:
      case AuthExceptionType.notAuthenticated:
      case AuthExceptionType.invalidCredentials:
      case AuthExceptionType.weakPassword:
      case AuthExceptionType.twoFactorRequired:
        return true;
      case AuthExceptionType.accountLocked:
      case AuthExceptionType.accountDisabled:
      case AuthExceptionType.accountNotFound:
      case AuthExceptionType.tokenInvalid:
      case AuthExceptionType.noToken:
      case AuthExceptionType.emailExists:
      case AuthExceptionType.registrationFailed:
      case AuthExceptionType.verificationFailed:
      case AuthExceptionType.passwordResetFailed:
      case AuthExceptionType.socialLoginFailed:
      case AuthExceptionType.biometricFailed:
      case AuthExceptionType.unknown:
      default:
        return false;
    }
  }

  /// Check if error should redirect to login
  bool get shouldRedirectToLogin {
    switch (type) {
      case AuthExceptionType.tokenExpired:
      case AuthExceptionType.tokenInvalid:
      case AuthExceptionType.noToken:
      case AuthExceptionType.notAuthenticated:
        return true;
      case AuthExceptionType.invalidCredentials:
      case AuthExceptionType.accountNotFound:
      case AuthExceptionType.accountLocked:
      case AuthExceptionType.accountDisabled:
      case AuthExceptionType.emailNotVerified:
      case AuthExceptionType.weakPassword:
      case AuthExceptionType.emailExists:
      case AuthExceptionType.registrationFailed:
      case AuthExceptionType.verificationFailed:
      case AuthExceptionType.passwordResetFailed:
      case AuthExceptionType.twoFactorRequired:
      case AuthExceptionType.socialLoginFailed:
      case AuthExceptionType.biometricFailed:
      case AuthExceptionType.unknown:
      default:
        return false;
    }
  }

  /// Check if error should show verification screen
  bool get shouldShowVerification {
    return type == AuthExceptionType.emailNotVerified;
  }

  /// Check if error is retryable
  bool get isRetryable {
    switch (type) {
      case AuthExceptionType.verificationFailed:
      case AuthExceptionType.passwordResetFailed:
      case AuthExceptionType.socialLoginFailed:
      case AuthExceptionType.biometricFailed:
      case AuthExceptionType.unknown:
        return true;
      case AuthExceptionType.invalidCredentials:
      case AuthExceptionType.accountNotFound:
      case AuthExceptionType.accountLocked:
      case AuthExceptionType.accountDisabled:
      case AuthExceptionType.emailNotVerified:
      case AuthExceptionType.tokenExpired:
      case AuthExceptionType.tokenInvalid:
      case AuthExceptionType.noToken:
      case AuthExceptionType.notAuthenticated:
      case AuthExceptionType.weakPassword:
      case AuthExceptionType.emailExists:
      case AuthExceptionType.registrationFailed:
      case AuthExceptionType.twoFactorRequired:
      default:
        return false;
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('AuthException: $message');

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
      'error_code': errorCode,
      'details': details,
      'user_message': userMessage,
      'requires_user_action': requiresUserAction,
      'should_redirect_to_login': shouldRedirectToLogin,
      'should_show_verification': shouldShowVerification,
      'is_retryable': isRetryable,
    };
  }
}