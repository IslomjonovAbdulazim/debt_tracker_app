import 'package:get/get.dart';
import '../../shared/helpers/logger.dart';

/// Base service class with common functionality
abstract class BaseService extends GetxService {
  /// Service initialization flag
  bool _isInitialized = false;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Service name for logging
  String get serviceName => runtimeType.toString();

  @override
  void onInit() {
    super.onInit();
    AppLogger.debug('$serviceName: Initializing...');
    _isInitialized = true;
  }

  @override
  void onReady() {
    super.onReady();
    AppLogger.debug('$serviceName: Ready');
  }

  @override
  void onClose() {
    AppLogger.debug('$serviceName: Closing...');
    _isInitialized = false;
    super.onClose();
  }

  /// Handle service errors
  void handleError(String operation, Object error, [StackTrace? stackTrace]) {
    AppLogger.error('$serviceName - $operation failed', error, stackTrace);
  }

  /// Log service activity
  void logActivity(String activity, [Map<String, dynamic>? data]) {
    AppLogger.debug('$serviceName: $activity', data);
  }

  /// Ensure service is initialized
  void ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('$serviceName is not initialized');
    }
  }
}