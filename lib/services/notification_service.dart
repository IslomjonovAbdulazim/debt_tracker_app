import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app/config/app_config.dart';
import '../core/base/base_service.dart';
import '../core/enums/notification_type.dart';
import '../shared/helpers/logger.dart';
import 'storage_service.dart';

/// Notification service for local and push notifications
class NotificationService extends BaseService {
  static NotificationService? _instance;

  // Flutter local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream controllers
  final StreamController<NotificationModel> _notificationController = StreamController<NotificationModel>.broadcast();
  final StreamController<String> _notificationClickController = StreamController<String>.broadcast();

  // Notification settings
  bool _isInitialized = false;
  bool _areNotificationsEnabled = true;

  // Private constructor
  NotificationService._();

  /// Get singleton instance
  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  // ==================== Initialization ====================

  /// Initialize notification service
  static Future<void> initialize() async {
    try {
      await instance._initializeLocalNotifications();
      await instance._loadSettings();
      AppLogger.info('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize NotificationService', e, stackTrace);
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationClick,
      );

      if (initialized == true) {
        _isInitialized = true;
        AppLogger.debug('Local notifications initialized');
      } else {
        AppLogger.warning('Local notifications initialization failed');
      }

      // Request permissions
      await _requestPermissions();

    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize local notifications', e, stackTrace);
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

        AppLogger.debug('iOS notification permissions granted: $granted');
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestPermission();

        AppLogger.debug('Android notification permissions granted: $granted');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to request notification permissions', e, stackTrace);
    }
  }

  /// Load notification settings
  Future<void> _loadSettings() async {
    try {
      _areNotificationsEnabled = StorageService.getBool('notifications_enabled') ?? true;
      AppLogger.debug('Notification settings loaded');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load notification settings', e, stackTrace);
    }
  }

  // ==================== Getters ====================

  /// Notification stream
  Stream<NotificationModel> get notificationStream => _notificationController.stream;

  /// Notification click stream
  Stream<String> get notificationClickStream => _notificationClickController.stream;

  /// Check if notifications are initialized
  bool get isInitialized => _isInitialized;

  /// Check if notifications are enabled
  bool get areNotificationsEnabled => _areNotificationsEnabled;

  // ==================== Local Notifications ====================

  /// Show local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.general,
    DateTime? scheduledDate,
    Duration? delay,
  }) async {
    try {
      if (!_isInitialized || !_areNotificationsEnabled) {
        AppLogger.debug('Notifications disabled or not initialized');
        return;
      }

      final notificationDetails = _getNotificationDetails(type);

      if (scheduledDate != null) {
        // Schedule notification for specific date
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          _convertToTZDateTime(scheduledDate),
          notificationDetails,
          payload: payload,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        AppLogger.debug('Notification scheduled for: $scheduledDate');
      } else if (delay != null) {
        // Schedule notification with delay
        await _localNotifications.schedule(
          id,
          title,
          body,
          DateTime.now().add(delay),
          notificationDetails,
          payload: payload,
        );

        AppLogger.debug('Notification scheduled with delay: $delay');
      } else {
        // Show immediate notification
        await _localNotifications.show(
          id,
          title,
          body,
          notificationDetails,
          payload: payload,
        );

        AppLogger.debug('Immediate notification shown');
      }

      // Log notification
      AppLogger.userAction('notification_shown', {
        'id': id,
        'title': title,
        'type': type.name,
      });

    } catch (e, stackTrace) {
      AppLogger.error('Failed to show notification', e, stackTrace);
    }
  }

  /// Get notification details based on type
  NotificationDetails _getNotificationDetails(NotificationType type) {
    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: _getImportance(type),
      priority: _getPriority(type),
      icon: _getNotificationIcon(type),
      color: _getNotificationColor(type),
      enableLights: true,
      enableVibration: true,
      playSound: true,
      groupKey: type.name,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Convert DateTime to TZDateTime (simplified)
  DateTime _convertToTZDateTime(DateTime dateTime) {
    // In a real app, you'd use the timezone package
    return dateTime;
  }

  // ==================== Notification Channels ====================

  /// Get channel ID based on notification type
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.debtReminder:
        return 'debt_reminders';
      case NotificationType.paymentReceived:
        return 'payment_notifications';
      case NotificationType.overdueDebt:
        return 'overdue_debts';
      case NotificationType.general:
      default:
        return 'general_notifications';
    }
  }

  /// Get channel name based on notification type
  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.debtReminder:
        return 'Debt Reminders';
      case NotificationType.paymentReceived:
        return 'Payment Notifications';
      case NotificationType.overdueDebt:
        return 'Overdue Debts';
      case NotificationType.general:
      default:
        return 'General Notifications';
    }
  }

  /// Get channel description based on notification type
  String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.debtReminder:
        return 'Notifications about upcoming debt payments';
      case NotificationType.paymentReceived:
        return 'Notifications when payments are received';
      case NotificationType.overdueDebt:
        return 'Notifications about overdue debts';
      case NotificationType.general:
      default:
        return 'General app notifications';
    }
  }

  /// Get importance level based on notification type
  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.overdueDebt:
        return Importance.high;
      case NotificationType.debtReminder:
      case NotificationType.paymentReceived:
        return Importance.defaultImportance;
      case NotificationType.general:
      default:
        return Importance.low;
    }
  }

  /// Get priority level based on notification type
  Priority _getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.overdueDebt:
        return Priority.high;
      case NotificationType.debtReminder:
      case NotificationType.paymentReceived:
        return Priority.defaultPriority;
      case NotificationType.general:
      default:
        return Priority.low;
    }
  }

  /// Get notification icon based on type
  String? _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.debtReminder:
        return '@drawable/ic_reminder';
      case NotificationType.paymentReceived:
        return '@drawable/ic_payment';
      case NotificationType.overdueDebt:
        return '@drawable/ic_warning';
      case NotificationType.general:
      default:
        return '@drawable/ic_notification';
    }
  }

  /// Get notification color based on type
  Color? _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.overdueDebt:
        return const Color(0xFFFF5252); // Red
      case NotificationType.paymentReceived:
        return const Color(0xFF4CAF50); // Green
      case NotificationType.debtReminder:
        return const Color(0xFF2196F3); // Blue
      case NotificationType.general:
      default:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  // ==================== Debt-Specific Notifications ====================

  /// Show debt reminder notification
  Future<void> showDebtReminder({
    required String debtorName,
    required double amount,
    required DateTime dueDate,
    String? debtId,
  }) async {
    final title = 'Debt Reminder';
    final body = '$debtorName owes you \$${amount.toStringAsFixed(2)}. Due: ${_formatDate(dueDate)}';

    await showNotification(
      id: debtId.hashCode,
      title: title,
      body: body,
      type: NotificationType.debtReminder,
      payload: jsonEncode({
        'type': 'debt_reminder',
        'debt_id': debtId,
        'debtor_name': debtorName,
        'amount': amount,
      }),
    );
  }

  /// Show overdue debt notification
  Future<void> showOverdueDebtNotification({
    required String debtorName,
    required double amount,
    required int daysPastDue,
    String? debtId,
  }) async {
    final title = 'Overdue Debt';
    final body = '$debtorName\'s debt of \$${amount.toStringAsFixed(2)} is $daysPastDue days overdue';

    await showNotification(
      id: debtId.hashCode,
      title: title,
      body: body,
      type: NotificationType.overdueDebt,
      payload: jsonEncode({
        'type': 'overdue_debt',
        'debt_id': debtId,
        'debtor_name': debtorName,
        'amount': amount,
        'days_overdue': daysPastDue,
      }),
    );
  }

  /// Show payment received notification
  Future<void> showPaymentReceived({
    required String payerName,
    required double amount,
    String? debtId,
  }) async {
    final title = 'Payment Received';
    final body = '$payerName paid you \$${amount.toStringAsFixed(2)}';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      type: NotificationType.paymentReceived,
      payload: jsonEncode({
        'type': 'payment_received',
        'debt_id': debtId,
        'payer_name': payerName,
        'amount': amount,
      }),
    );
  }

  // ==================== Scheduled Notifications ====================

  /// Schedule daily debt reminders
  Future<void> scheduleDailyReminders() async {
    try {
      // Cancel existing reminders
      await cancelNotificationsByType(NotificationType.debtReminder);

      // Schedule new reminders (example: every day at 9 AM)
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0);

      // If it's already past 9 AM today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await showNotification(
        id: 999,
        title: 'Daily Debt Check',
        body: 'Time to check your debts and payments',
        type: NotificationType.debtReminder,
        scheduledDate: scheduledDate,
      );

      AppLogger.debug('Daily reminders scheduled');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to schedule daily reminders', e, stackTrace);
    }
  }

