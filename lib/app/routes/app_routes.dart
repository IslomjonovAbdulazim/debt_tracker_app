/// Application route constants
class Routes {
  // Private constructor to prevent instantiation
  Routes._();

  // ==================== App Flow Routes ====================

  /// Splash screen - app initialization
  static const String SPLASH = '/splash';

  /// Onboarding flow - first time user experience
  static const String ONBOARDING = '/onboarding';

  // ==================== Authentication Routes ====================

  /// Login screen
  static const String LOGIN = '/login';

  /// Registration screen
  static const String REGISTER = '/register';

  /// Email verification screen
  static const String VERIFY_EMAIL = '/verify-email';

  /// Forgot password screen
  static const String FORGOT_PASSWORD = '/forgot-password';

  /// Reset password screen
  static const String RESET_PASSWORD = '/reset-password';

  // ==================== Main App Routes ====================

  /// Main dashboard/home screen
  static const String DASHBOARD = '/dashboard';

  /// Contact management
  static const String CONTACTS = '/contacts';
  static const String CONTACT_FORM = '/contact-form';
  static const String CONTACT_DETAIL = '/contact-detail';

  /// Debt management
  static const String DEBTS = '/debts';
  static const String DEBT_FORM = '/debt-form';
  static const String DEBT_DETAIL = '/debt-detail';
  static const String DEBT_LIST = '/debt-list';

  /// Payment management
  static const String PAYMENTS = '/payments';
  static const String PAYMENT_FORM = '/payment-form';
  static const String PAYMENT_HISTORY = '/payment-history';

  // ==================== Settings Routes ====================

  /// Main settings screen
  static const String SETTINGS = '/settings';

  /// Profile management
  static const String PROFILE = '/profile';
  static const String EDIT_PROFILE = '/edit-profile';

  /// App preferences
  static const String PREFERENCES = '/preferences';
  static const String THEME_SETTINGS = '/theme-settings';
  static const String LANGUAGE_SETTINGS = '/language-settings';
  static const String NOTIFICATION_SETTINGS = '/notification-settings';

  /// Security settings
  static const String SECURITY = '/security';
  static const String CHANGE_PASSWORD = '/change-password';
  static const String PRIVACY = '/privacy';

  // ==================== Utility Routes ====================

  /// Help and support
  static const String HELP = '/help';
  static const String ABOUT = '/about';
  static const String TERMS = '/terms';
  static const String PRIVACY_POLICY = '/privacy-policy';

  /// Export and backup
  static const String EXPORT = '/export';
  static const String BACKUP = '/backup';

  /// Statistics and reports
  static const String STATISTICS = '/statistics';
  static const String REPORTS = '/reports';

  // ==================== Error Routes ====================

  /// Generic error screen
  static const String ERROR = '/error';

  /// Network error screen
  static const String NETWORK_ERROR = '/network-error';

  /// Not found (404) screen
  static const String NOT_FOUND = '/not-found';

  /// Maintenance screen
  static const String MAINTENANCE = '/maintenance';

  // ==================== Route Parameters ====================

  /// Parameter keys for route arguments
  static class Params {
  static const String ID = 'id';
  static const String CONTACT_ID = 'contactId';
  static const String DEBT_ID = 'debtId';
  static const String PAYMENT_ID = 'paymentId';
  static const String EMAIL = 'email';
  static const String TOKEN = 'token';
  static const String TITLE = 'title';
  static const String MESSAGE = 'message';
  static const String ERROR_TYPE = 'errorType';
  static const String REDIRECT_TO = 'redirectTo';
  static const String MODE = 'mode';
  static const String TYPE = 'type';
  static const String ACTION = 'action';
  }

  // ==================== Route Utilities ====================

  /// Get all public routes (no authentication required)
  static List<String> get publicRoutes => [
  SPLASH,
  ONBOARDING,
  LOGIN,
  REGISTER,
  VERIFY_EMAIL,
  FORGOT_PASSWORD,
  RESET_PASSWORD,
  ERROR,
  NETWORK_ERROR,
  NOT_FOUND,
  MAINTENANCE,
  HELP,
  ABOUT,
  TERMS,
  PRIVACY_POLICY,
  ];

  /// Get all protected routes (authentication required)
  static List<String> get protectedRoutes => [
  DASHBOARD,
  CONTACTS,
  CONTACT_FORM,
  CONTACT_DETAIL,
  DEBTS,
  DEBT_FORM,
  DEBT_DETAIL,
  DEBT_LIST,
  PAYMENTS,
  PAYMENT_FORM,
  PAYMENT_HISTORY,
  SETTINGS,
  PROFILE,
  EDIT_PROFILE,
  PREFERENCES,
  THEME_SETTINGS,
  LANGUAGE_SETTINGS,
  NOTIFICATION_SETTINGS,
  SECURITY,
  CHANGE_PASSWORD,
  PRIVACY,
  EXPORT,
  BACKUP,
  STATISTICS,
  REPORTS,
  ];

  /// Check if route is public (no auth required)
  static bool isPublicRoute(String route) {
  return publicRoutes.contains(route);
  }

  /// Check if route is protected (auth required)
  static bool isProtectedRoute(String route) {
  return protectedRoutes.contains(route);
  }

  /// Get initial route based on app state
  static String getInitialRoute({
  bool isFirstLaunch = false,
  bool isAuthenticated = false,
  bool isEmailVerified = true,
  }) {
  if (isFirstLaunch) {
  return ONBOARDING;
  }

  if (!isAuthenticated) {
  return LOGIN;
  }

  if (!isEmailVerified) {
  return VERIFY_EMAIL;
  }

  return DASHBOARD;
  }

  /// Build route with parameters
  static String buildRoute(String route, [Map<String, String>? params]) {
  if (params == null || params.isEmpty) {
  return route;
  }

  String result = route;
  final queryParams = <String>[];

  params.forEach((key, value) {
  if (result.contains(':$key')) {
  // Replace path parameters
  result = result.replaceAll(':$key', value);
  } else {
  // Add as query parameter
  queryParams.add('$key=${Uri.encodeComponent(value)}');
  }
  });

  if (queryParams.isNotEmpty) {
  result += '?${queryParams.join('&')}';
  }

  return result;
  }

  /// Extract route name from full path
  static String extractRouteName(String fullPath) {
  // Remove query parameters
  final uri = Uri.parse(fullPath);
  return uri.path;
  }

  /// Get parent route
  static String? getParentRoute(String route) {
  final segments = route.split('/');
  if (segments.length <= 2) return null;

  segments.removeLast();
  return segments.join('/');
  }

  /// Check if route has parameters
  static bool hasParameters(String route) {
  return route.contains(':') || route.contains('?');
  }

  /// Get breadcrumb trail for route
  static List<String> getBreadcrumbs(String route) {
  final segments = route.split('/').where((s) => s.isNotEmpty).toList();
  final breadcrumbs = <String>[];

  String currentPath = '';
  for (final segment in segments) {
  currentPath += '/$segment';
  breadcrumbs.add(currentPath);
  }

  return breadcrumbs;
  }
}

/// Route group utility class
class RouteGroups {
  /// Authentication related routes
  static const List<String> auth = [
    Routes.LOGIN,
    Routes.REGISTER,
    Routes.VERIFY_EMAIL,
    Routes.FORGOT_PASSWORD,
    Routes.RESET_PASSWORD,
  ];

  /// Contact management routes
  static const List<String> contacts = [
    Routes.CONTACTS,
    Routes.CONTACT_FORM,
    Routes.CONTACT_DETAIL,
  ];

  /// Debt management routes
  static const List<String> debts = [
    Routes.DEBTS,
    Routes.DEBT_FORM,
    Routes.DEBT_DETAIL,
    Routes.DEBT_LIST,
  ];

  /// Payment management routes
  static const List<String> payments = [
    Routes.PAYMENTS,
    Routes.PAYMENT_FORM,
    Routes.PAYMENT_HISTORY,
  ];

  /// Settings related routes
  static const List<String> settings = [
    Routes.SETTINGS,
    Routes.PROFILE,
    Routes.EDIT_PROFILE,
    Routes.PREFERENCES,
    Routes.THEME_SETTINGS,
    Routes.LANGUAGE_SETTINGS,
    Routes.NOTIFICATION_SETTINGS,
    Routes.SECURITY,
    Routes.CHANGE_PASSWORD,
    Routes.PRIVACY,
  ];

  /// Utility and info routes
  static const List<String> utilities = [
    Routes.HELP,
    Routes.ABOUT,
    Routes.TERMS,
    Routes.PRIVACY_POLICY,
    Routes.EXPORT,
    Routes.BACKUP,
    Routes.STATISTICS,
    Routes.REPORTS,
  ];

  /// Error handling routes
  static const List<String> errors = [
    Routes.ERROR,
    Routes.NETWORK_ERROR,
    Routes.NOT_FOUND,
    Routes.MAINTENANCE,
  ];

  /// Check if route belongs to a group
  static bool isInGroup(String route, List<String> group) {
    return group.contains(route);
  }

  /// Get group name for route
  static String? getGroupName(String route) {
    if (isInGroup(route, auth)) return 'Authentication';
    if (isInGroup(route, contacts)) return 'Contacts';
    if (isInGroup(route, debts)) return 'Debts';
    if (isInGroup(route, payments)) return 'Payments';
    if (isInGroup(route, settings)) return 'Settings';
    if (isInGroup(route, utilities)) return 'Utilities';
    if (isInGroup(route, errors)) return 'Errors';
    return null;
  }
}

/// Route metadata for enhanced navigation
class RouteMetadata {
  final String title;
  final String? description;
  final IconData? icon;
  final bool requiresAuth;
  final bool showInNavigation;
  final List<String> permissions;
  final String? parentRoute;

  const RouteMetadata({
    required this.title,
    this.description,
    this.icon,
    this.requiresAuth = false,
    this.showInNavigation = true,
    this.permissions = const [],
    this.parentRoute,
  });
}

/// Route definitions with metadata
class RouteDefinitions {
  static const Map<String, RouteMetadata> _definitions = {
    Routes.DASHBOARD: RouteMetadata(
      title: 'Dashboard',
      description: 'Overview of your debts and payments',
      requiresAuth: true,
      showInNavigation: true,
    ),
    Routes.CONTACTS: RouteMetadata(
      title: 'Contacts',
      description: 'Manage your contacts',
      requiresAuth: true,
      showInNavigation: true,
    ),
    Routes.DEBTS: RouteMetadata(
      title: 'Debts',
      description: 'Manage your debts',
      requiresAuth: true,
      showInNavigation: true,
    ),
    Routes.PAYMENTS: RouteMetadata(
      title: 'Payments',
      description: 'View payment history',
      requiresAuth: true,
      showInNavigation: true,
    ),
    Routes.SETTINGS: RouteMetadata(
      title: 'Settings',
      description: 'App settings and preferences',
      requiresAuth: true,
      showInNavigation: true,
    ),
    Routes.LOGIN: RouteMetadata(
      title: 'Login',
      description: 'Sign in to your account',
      requiresAuth: false,
      showInNavigation: false,
    ),
    Routes.REGISTER: RouteMetadata(
      title: 'Register',
      description: 'Create a new account',
      requiresAuth: false,
      showInNavigation: false,
    ),
  };

  /// Get metadata for route
  static RouteMetadata? getMetadata(String route) {
    return _definitions[route];
  }

  /// Get title for route
  static String getTitle(String route) {
    return _definitions[route]?.title ?? 'Unknown';
  }

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    return _definitions[route]?.requiresAuth ?? true;
  }

  /// Check if route should show in navigation
  static bool showInNavigation(String route) {
    return _definitions[route]?.showInNavigation ?? false;
  }

  /// Get all navigation routes
  static List<String> getNavigationRoutes() {
    return _definitions.entries
        .where((entry) => entry.value.showInNavigation)
        .map((entry) => entry.key)
        .toList();
  }
}