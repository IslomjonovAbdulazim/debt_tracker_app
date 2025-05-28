import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/config/firebase_config.dart';
import 'app/bindings/initial_binding.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'shared/helpers/logger.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI
  await _configureSystemUI();

  // Initialize core services
  await _initializeServices();

  // Set up error handling
  _setupErrorHandling();

  // Run the app
  runApp(DebtTrackerApp());
}

/// Configure system UI overlays and orientation
Future<void> _configureSystemUI() async {
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/// Initialize essential services
Future<void> _initializeServices() async {
  try {
    // Initialize logger first
    AppLogger.init();
    AppLogger.info('Starting app initialization...');

    // Initialize local storage
    await StorageService.init();
    AppLogger.info('Storage service initialized');

    // Initialize Firebase (if configured)
    await FirebaseConfig.initialize();
    AppLogger.info('Firebase initialized');

    // Initialize notification service
    await NotificationService.initialize();
    AppLogger.info('Notification service initialized');

    // Set up initial bindings
    InitialBinding().dependencies();
    AppLogger.info('Dependencies injected');

    AppLogger.info('App initialization completed successfully');
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize services', e, stackTrace);
    // Continue with app launch even if some services fail
  }
}

/// Set up global error handling
void _setupErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter Error: ${details.exception}',
      details.exception,
      details.stack,
    );

    // In debug mode, also print to console
    if (AppConfig.isDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // Handle Dart errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Platform Error', error, stack);
    return true;
  };
}