import 'dart:async';
import 'package:get/get.dart';
import '../app/config/api_config.dart';
import '../core/base/base_service.dart';
import '../core/exceptions/auth_exceptions.dart';
import '../data/models/entities/user_entity.dart';
import '../data/models/requests/login_request.dart';
import '../data/models/requests/register_request.dart';
import '../data/models/responses/login_response.dart';
import '../shared/helpers/logger.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Authentication service for user management
class AuthService extends BaseService {
  static AuthService? _instance;

  // Stream controllers for auth state
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();
  final StreamController<UserEntity?> _userController = StreamController<UserEntity?>.broadcast();

  // Current user data
  UserEntity? _currentUser;
  String? _currentToken;
  String? _refreshToken;
  Timer? _tokenRefreshTimer;

  // Private constructor
  AuthService._();

  /// Get singleton instance
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  // ==================== Getters ====================

  /// Current authentication state stream
  Stream<AuthState> get authStateStream => _authStateController.stream;

  /// Current user stream
  Stream<UserEntity?> get userStream => _userController.stream;

  /// Current user
  UserEntity? get currentUser => _currentUser;

  /// Current auth token
  String? get currentToken => _currentToken;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentToken != null && _currentUser != null;

  /// Check if user is verified
  bool get isVerified => _currentUser?.isVerified ?? false;

  // ==================== Authentication State ====================

  /// Initialize auth service
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing AuthService');

      // Load saved auth data
      await _loadAuthData();

      // Validate current session
      if (_currentToken != null) {
        await _validateSession();
      }

      // Setup token refresh timer
      _setupTokenRefreshTimer();

      AppLogger.info('AuthService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize AuthService', e, stackTrace);
      await _clearAuthData();
    }
  }

  /// Load authentication data from storage
  Future<void> _loadAuthData() async {
    try {
      _currentToken = StorageService.getAuthToken();
      _refreshToken = StorageService.getRefreshToken();

      final userData = StorageService.getUserData();
      if (userData != null) {
        _currentUser = UserEntity.fromJson(userData);
      }

      AppLogger.debug('Auth data loaded from storage');
      _updateAuthState();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load auth data', e, stackTrace);
    }
  }

  /// Validate current session
  Future<void> _validateSession() async {
    try {
      final response = await ApiService.instance.get(
        ApiConfig.AuthEndpoints.checkAuth,
        useAuth: true,
        timeout: const Duration(seconds: 10),
      );

      if (response['valid'] != true) {
        AppLogger.warning('Session validation failed');
        await _handleInvalidSession();
      } else {
        AppLogger.debug('Session validated successfully');
      }
    } catch (e) {
      AppLogger.error('Session validation error', e);
      await _handleInvalidSession();
    }
  }

  /// Handle invalid session
  Future<void> _handleInvalidSession() async {
    if (_refreshToken != null) {
      final refreshed = await _refreshAuthToken();
      if (!refreshed) {
        await logout();
      }
    } else {
      await logout();
    }
  }

  /// Update authentication state
  void _updateAuthState() {
    AuthState state;

    if (_currentUser == null || _currentToken == null) {
      state = AuthState.unauthenticated;
    } else if (!_currentUser!.isVerified) {
      state = AuthState.unverified;
    } else {
      state = AuthState.authenticated;
    }

    _authStateController.add(state);
    _userController.add(_currentUser);

    AppLogger.debug('Auth state updated: $state');
  }

  // ==================== Login/Register ====================

  /// Login user with email and password
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      AppLogger.info('Attempting login for: ${request.email}');

      final response = await ApiService.instance.post(
        ApiConfig.AuthEndpoints.login,
        request.toJson(),
        useAuth: false,
      );

      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.success) {
        await _saveAuthData(
          loginResponse.token!,
          loginResponse.refreshToken,
          loginResponse.user!,
        );

        AppLogger.info('Login successful for: ${request.email}');
        AppLogger.userAction('login', {'email': request.email});
      }

      return loginResponse;
    } catch (e, stackTrace) {
      AppLogger.error('Login failed for: ${request.email}', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      AppLogger.info('Attempting registration for: ${request.email}');

      final response = await ApiService.instance.post(
        ApiConfig.AuthEndpoints.register,
        request.toJson(),
        useAuth: false,
      );

      if (response['success'] == true) {
        AppLogger.info('Registration successful for: ${request.email}');
        AppLogger.userAction('register', {'email': request.email});
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Registration failed for: ${request.email}', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  /// Verify email with code
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      AppLogger.info('Verifying email for: $email');

      final response = await ApiService.instance.post(
        ApiConfig.AuthEndpoints.verifyEmail,
        {
          'email': email,
          'verification_code': code,
        },
        useAuth: false,
      );

      if (response['success'] == true) {
        // Update current user if it's the same email
        if (_currentUser?.email == email) {
          _currentUser = _currentUser!.copyWith(isVerified: true);
          await StorageService.setUserData(_currentUser!.toJson());
          _updateAuthState();
        }

        AppLogger.info('Email verification successful for: $email');
        AppLogger.userAction('verify_email', {'email': email});
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Email verification failed for: $email', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  /// Resend verification email
  Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      AppLogger.info('Resending verification for: $email');

      final response = await ApiService.instance.post(
        ApiConfig.AuthEndpoints.resendVerification,
        {'email': email},
        useAuth: false,
      );

      if (response['success'] == true) {
        AppLogger.info('Verification email resent for: $email');
        AppLogger.userAction('resend_verification', {'email': email});
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to resend verification for: $email', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  // ==================== Password Management ====================

  /// Request password reset
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      AppLogger.info('Password reset requested for: $email');

      final response = await ApiService.instance.post(
        ApiConfig.AuthEndpoints.forgotPassword,
        {'email': email},
        useAuth: false,
      );

      if (response['success'] == true) {
        AppLogger.info('Password reset email sent for: $email');
        AppLogger.userAction('forgot_password', {'email': email});
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Password reset failed for: $email', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  /// Reset password with token
  Future<Map<String, dynamic>> resetPassword(
      String email,
      String token,
      String newPassword,
      ) async {
    try {
      AppLogger.info('Resetting password for: $email');

      final response = await ApiService.instance.post(
        ApiConfig.AuthEndpoints.resetPassword,
        {
          'email': email,
          'reset_token': token,
          'new_password': newPassword,
        },
        useAuth: false,
      );

      if (response['success'] == true) {
        AppLogger.info('Password reset successful for: $email');
        AppLogger.userAction('reset_password', {'email': email});
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Password reset failed for: $email', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  /// Change password for authenticated user
  Future<Map<String, dynamic>> changePassword(
      String currentPassword,
      String newPassword,
      ) async {
    try {
      _ensureAuthenticated();

      AppLogger.info('Changing password for user: ${_currentUser!.email}');

      final response = await ApiService.instance.post(
        ApiConfig.AuthEndpoints.changePassword,
        {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        useAuth: true,
      );

      if (response['success'] == true) {
        AppLogger.info('Password changed successfully');
        AppLogger.userAction('change_password');
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Password change failed', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  // ==================== Token Management ====================

  /// Refresh authentication token
  Future<bool> _refreshAuthToken() async {
    try {
      if (_refreshToken == null) return false;

      AppLogger.debug('Refreshing auth token');

      final response = await ApiService.instance.post(
        ApiConfig.AuthEndpoints.refreshToken,
        {'refresh_token': _refreshToken},
        useAuth: false,
      );

      if (response['success'] == true) {
        final newToken = response['data']['access_token'];
        final newRefreshToken = response['data']['refresh_token'];

        await _updateTokens(newToken, newRefreshToken);

        AppLogger.debug('Token refreshed successfully');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Token refresh failed', e, stackTrace);
      return false;
    }
  }

  /// Update tokens in memory and storage
  Future<void> _updateTokens(String token, String? refreshToken) async {
    _currentToken = token;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }

    await StorageService.setAuthToken(token);
    if (refreshToken != null) {
      await StorageService.setRefreshToken(refreshToken);
    }

    _setupTokenRefreshTimer();
  }

  /// Setup automatic token refresh timer
  void _setupTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();

    if (_currentToken != null) {
      // Refresh token every 50 minutes (tokens typically expire in 60 minutes)
      _tokenRefreshTimer = Timer.periodic(
        const Duration(minutes: 50),
            (_) => _refreshAuthToken,
      );
    }
  }

  // ==================== User Profile ====================

  /// Get current user profile
  Future<UserEntity> getCurrentUser() async {
    try {
      _ensureAuthenticated();

      final response = await ApiService.instance.get(
        ApiConfig.UserEndpoints.profile,
        useAuth: true,
      );

      final user = UserEntity.fromJson(response['data']);

      // Update cached user
      _currentUser = user;
      await StorageService.setUserData(user.toJson());
      _updateAuthState();

      return user;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get current user', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  /// Update user profile
  Future<UserEntity> updateProfile(Map<String, dynamic> updates) async {
    try {
      _ensureAuthenticated();

      AppLogger.info('Updating user profile');

      final response = await ApiService.instance.put(
        ApiConfig.UserEndpoints.updateProfile,
        updates,
        useAuth: true,
      );

      final user = UserEntity.fromJson(response['data']);

      // Update cached user
      _currentUser = user;
      await StorageService.setUserData(user.toJson());
      _updateAuthState();

      AppLogger.info('Profile updated successfully');
      AppLogger.userAction('update_profile', updates);

      return user;
    } catch (e, stackTrace) {
      AppLogger.error('Profile update failed', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  // ==================== Logout ====================

  /// Logout user
  Future<void> logout() async {
    try {
      AppLogger.info('Logging out user');

      // Call logout endpoint if we have a token
      if (_currentToken != null) {
        try {
          await ApiService.instance.post(
            ApiConfig.AuthEndpoints.logout,
            {},
            useAuth: true,
          );
        } catch (e) {
          // Continue with logout even if API call fails
          AppLogger.warning('Logout API call failed', e);
        }
      }

      // Clear local data
      await _clearAuthData();

      AppLogger.info('User logged out successfully');
      AppLogger.userAction('logout');

    } catch (e, stackTrace) {
      AppLogger.error('Logout error', e, stackTrace);
      // Still clear local data even if there's an error
      await _clearAuthData();
    }
  }

  /// Clear authentication data
  Future<void> _clearAuthData() async {
    // Cancel timers
    _tokenRefreshTimer?.cancel();

    // Clear memory
    _currentUser = null;
    _currentToken = null;
    _refreshToken = null;

    // Clear storage
    await StorageService.clearAuthData();

    // Update state
    _updateAuthState();

    AppLogger.debug('Auth data cleared');
  }

  /// Save authentication data
  Future<void> _saveAuthData(String token, String? refreshToken, UserEntity user) async {
    // Update memory
    _currentToken = token;
    _refreshToken = refreshToken;
    _currentUser = user;

    // Save to storage
    await StorageService.setAuthToken(token);
    if (refreshToken != null) {
      await StorageService.setRefreshToken(refreshToken);
    }
    await StorageService.setUserData(user.toJson());
    await StorageService.setBool('is_logged_in', true);

    // Setup refresh timer
    _setupTokenRefreshTimer();

    // Update state
    _updateAuthState();

    AppLogger.debug('Auth data saved');
  }

  // ==================== Social Authentication ====================

  /// Login with Google
  Future<LoginResponse> loginWithGoogle(String idToken) async {
    try {
      AppLogger.info('Attempting Google login');

      final response = await ApiService.instance.post(
        '${ApiConfig.AuthEndpoints.base}/google',
        {'id_token': idToken},
        useAuth: false,
      );

      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.success) {
        await _saveAuthData(
          loginResponse.token!,
          loginResponse.refreshToken,
          loginResponse.user!,
        );

        AppLogger.info('Google login successful');
        AppLogger.userAction('login_google');
      }

      return loginResponse;
    } catch (e, stackTrace) {
      AppLogger.error('Google login failed', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  /// Login with Facebook
  Future<LoginResponse> loginWithFacebook(String accessToken) async {
    try {
      AppLogger.info('Attempting Facebook login');

      final response = await ApiService.instance.post(
        '${ApiConfig.AuthEndpoints.base}/facebook',
        {'access_token': accessToken},
        useAuth: false,
      );

      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.success) {
        await _saveAuthData(
          loginResponse.token!,
          loginResponse.refreshToken,
          loginResponse.user!,
        );

        AppLogger.info('Facebook login successful');
        AppLogger.userAction('login_facebook');
      }

      return loginResponse;
    } catch (e, stackTrace) {
      AppLogger.error('Facebook login failed', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  // ==================== Account Management ====================

  /// Delete user account
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      _ensureAuthenticated();

      AppLogger.info('Deleting user account');

      final response = await ApiService.instance.delete(
        ApiConfig.UserEndpoints.deleteAccount,
        data: {'password': password},
        useAuth: true,
      );

      if (response['success'] == true) {
        await _clearAuthData();
        AppLogger.info('Account deleted successfully');
        AppLogger.userAction('delete_account');
      }

      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Account deletion failed', e, stackTrace);
      throw AuthException.fromError(e);
    }
  }

  // ==================== Utilities ====================

  /// Ensure user is authenticated
  void _ensureAuthenticated() {
    if (!isAuthenticated) {
      throw const AuthException(
        message: 'User not authenticated',
        type: AuthExceptionType.notAuthenticated,
      );
    }
  }

  /// Check if token is expired (simplified check)
  bool get isTokenExpired {
    // This is a simplified check - in a real app, you'd decode the JWT
    // and check the expiration time
    return _currentToken == null;
  }

  /// Get authentication headers
  Map<String, String> getAuthHeaders() {
    if (_currentToken == null) {
      throw const AuthException(
        message: 'No auth token available',
        type: AuthExceptionType.noToken,
      );
    }

    return {
      'Authorization': 'Bearer $_currentToken',
    };
  }

  // ==================== Cleanup ====================

  @override
  void onClose() {
    _tokenRefreshTimer?.cancel();
    _authStateController.close();
    _userController.close();
    super.onClose();
  }
}

/// Authentication state enum
enum AuthState {
  /// User is not authenticated
  unauthenticated,
  /// User is authenticated but email not verified
  unverified,
  /// User is fully authenticated
  authenticated,
}

/// Extension methods for AuthState
extension AuthStateExtension on AuthState {
  bool get isAuthenticated => this == AuthState.authenticated;
  bool get isUnauthenticated => this == AuthState.unauthenticated;
  bool get isUnverified => this == AuthState.unverified;
}