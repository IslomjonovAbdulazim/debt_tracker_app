import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'config/app_config.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'translations/app_translations.dart';
import '../services/storage_service.dart';
import '../shared/helpers/logger.dart';

class DebtTrackerApp extends StatelessWidget {
  const DebtTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // App Configuration
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.showDebugBanner,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getInitialThemeMode(),

      // Localization Configuration
      translations: AppTranslations(),
      locale: _getInitialLocale(),
      fallbackLocale: AppTranslations.fallbackLocale,

      // Navigation Configuration
      initialRoute: _getInitialRoute(),
      getPages: AppPages.routes,
      unknownRoute: AppPages.unknownRoute,

      // Routing Configuration
      routingCallback: (routing) {
        AppLogger.info('Navigation: ${routing?.current}');
      },

      // Builder for global configurations
      builder: (context, child) {
        return _AppWrapper(child: child);
      },

      // Default transitions
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),

      // Bindings
      initialBinding: _getInitialBinding(),
    );
  }

  /// Determine initial route based on user state
  String _getInitialRoute() {
    try {
      // Check if user has completed onboarding
      final hasCompletedOnboarding = StorageService.getBool('onboarding_completed') ?? false;
      if (!hasCompletedOnboarding) {
        return Routes.ONBOARDING;
      }

      // Check if user is logged in
      final isLoggedIn = StorageService.getBool('is_logged_in') ?? false;
      final hasValidToken = StorageService.getString('auth_token')?.isNotEmpty ?? false;

      if (isLoggedIn && hasValidToken) {
        return Routes.DASHBOARD;
      } else {
        return Routes.LOGIN;
      }
    } catch (e) {
      AppLogger.error('Error determining initial route', e);
      return Routes.SPLASH;
    }
  }

  /// Get initial theme mode
  ThemeMode _getInitialThemeMode() {
    try {
      final savedTheme = StorageService.getString('theme_mode') ?? 'system';
      switch (savedTheme) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      AppLogger.error('Error getting theme mode', e);
      return ThemeMode.system;
    }
  }

  /// Get initial locale
  Locale _getInitialLocale() {
    try {
      final savedLocale = StorageService.getString('locale');
      if (savedLocale != null) {
        final parts = savedLocale.split('_');
        return Locale(parts[0], parts.length > 1 ? parts[1] : null);
      }
      return Get.deviceLocale ?? AppTranslations.fallbackLocale;
    } catch (e) {
      AppLogger.error('Error getting locale', e);
      return AppTranslations.fallbackLocale;
    }
  }

  /// Get initial binding
  Bindings? _getInitialBinding() {
    // Return null to use individual page bindings
    return null;
  }
}

/// Wrapper widget for global app configurations
class _AppWrapper extends StatelessWidget {
  final Widget? child;

  const _AppWrapper({this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      // Ensure text scaling doesn't break UI
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
        ),
      ),
      child: GestureDetector(
        // Dismiss keyboard when tapping outside
        onTap: () {
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
            currentFocus.focusedChild?.unfocus();
          }
        },
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}