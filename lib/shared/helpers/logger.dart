import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../app/config/app_config.dart';
import '../../services/storage_service.dart';

/// Log level enum
enum LogLevel {
  debug(0, '🐛', 'DEBUG'),
  info(1, 'ℹ️', 'INFO'),
  warning(2, '⚠️', 'WARNING'),
  error(3, '❌', 'ERROR'),
  fatal(4, '💀', 'FATAL');

  const LogLevel(this.level, this.emoji, this.name);

  final int level;
  final String emoji;
  final String name;
}

/// Log entry model
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? extra;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.extra,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'tag': tag,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'extra': extra,
    };
  }

  /// Create from JSON
  factory LogEntry.fromJson(Map<string, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      tag: json['tag'],
      error: json['error'],
      stackTrace: json['stackTrace'] != null
          ? StackTrace.fromString(json['stackTrace'])
          : null,
      extra: json['extra'],
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('${level.emoji} ${level.name}');
    if (tag != null) buffer.write(' [$tag]');
    buffer.write(': $message');

    if (error != null) {
      buffer.write('\nError: $error');
    }

    if (stackTrace != null) {
      buffer.write('\nStack Trace:\n$stackTrace');
    }

    if (extra != null && extra!.isNotEmpty) {
      buffer.write('\nExtra: ${jsonEncode(extra)}');
    }

    return buffer.toString();
  }
}

/// Application logger with file persistence and filtering
class AppLogger {
  static AppLogger? _instance;
  static LogLevel _minLevel = LogLevel.debug;
  static bool _enableFileLogging = true;
  static bool _enableConsoleLogging = true;
  static int _maxLogFiles = 10;
  static int _maxLogFileSize = 5 * 1024 * 1024; // 5MB

  final List<LogEntry> _logBuffer = [];
  final StreamController<LogEntry> _logStreamController = StreamController<LogEntry>.broadcast();
  Timer? _flushTimer;
  File? _currentLogFile;

  // Private constructor
  AppLogger._();

  /// Get singleton instance
  static AppLogger get instance {
    _instance ??= AppLogger._();
    return _instance!;
  }

  /// Initialize logger
  static Future<void> init({
    LogLevel minLevel = LogLevel.debug,
    bool enableFileLogging = true,
    bool enableConsoleLogging = true,
    int maxLogFiles = 10,
    int maxLogFileSizeMB = 5,
  }) async {
    _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
    _enableFileLogging = enableFileLogging;
    _enableConsoleLogging = enableConsoleLogging;
    _maxLogFiles = maxLogFiles;
    _maxLogFileSize = maxLogFileSizeMB * 1024 * 1024;

    final logger = instance;
    await logger._initializeFileLogging();
    logger._startPeriodicFlush();

    info('Logger initialized - Level: ${_minLevel.name}');
  }

  /// Initialize file logging
  Future<void> _initializeFileLogging() async {
    if (!_enableFileLogging) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${appDir.path}/logs');

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      await _rotateLogFiles();

      final logFileName = 'app_${DateTime.now().toIso8601String().split('T')[0]}.log';
      _currentLogFile = File('${logsDir.path}/$logFileName');

    } catch (e) {
      debugPrint('Failed to initialize file logging: $e');
    }
  }

  /// Rotate log files to maintain max count
  Future<void> _rotateLogFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${appDir.path}/logs');

      if (!await logsDir.exists()) return;

      final logFiles = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      logFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Delete excess files
      if (logFiles.length >= _maxLogFiles) {
        for (int i = _maxLogFiles - 1; i < logFiles.length; i++) {
          await logFiles[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to rotate log files: $e');
    }
  }

  /// Start periodic log flush to file
  void _startPeriodicFlush() {
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushLogs();
    });
  }

  /// Flush logs to file
  Future<void> _flushLogs() async {
    if (!_enableFileLogging || _currentLogFile == null || _logBuffer.isEmpty) {
      return;
    }

    try {
      // Check if log file is too large
      if (await _currentLogFile!.exists()) {
        final size = await _currentLogFile!.length();
        if (size > _maxLogFileSize) {
          await _rotateCurrentLogFile();
        }
      }

      // Write buffered logs
      final logEntries = List<LogEntry>.from(_logBuffer);
      _logBuffer.clear();

      final logText = logEntries.map((entry) => entry.toString()).join('\n') + '\n';
      await _currentLogFile!.writeAsString(logText, mode: FileMode.append);

    } catch (e) {
      debugPrint('Failed to flush logs: $e');
    }
  }

  /// Rotate current log file
  Future<void> _rotateCurrentLogFile() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final oldPath = _currentLogFile!.path;
      final newPath = oldPath.replaceAll('.log', '_$timestamp.log');

      await _currentLogFile!.rename(newPath);

      // Create new log file
      _currentLogFile = File(oldPath);

    } catch (e) {
      debugPrint('Failed to rotate log file: $e');
    }
  }

  /// Log with specific level
  static void log(
      LogLevel level,
      String message, {
        String? tag,
        Object? error,
        StackTrace? stackTrace,
        Map<String, dynamic>? extra,
      }) {
    if (level.level < _minLevel.level) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      extra: extra,
    );

    instance._processLogEntry(entry);
  }

  /// Process log entry
  void _processLogEntry(LogEntry entry) {
    // Add to stream
    _logStreamController.add(entry);

    // Console logging
    if (_enableConsoleLogging) {
      _logToConsole(entry);
    }

    // File logging
    if (_enableFileLogging) {
      _logBuffer.add(entry);
    }

    // Store critical errors
    if (entry.level.level >= LogLevel.error.level) {
      _storeCriticalError(entry);
    }
  }

  /// Log to console with colors
  void _logToConsole(LogEntry entry) {
    final output = _formatConsoleOutput(entry);

    if (entry.level.level >= LogLevel.error.level) {
      debugPrint('\x1B[31m$output\x1B[0m'); // Red for errors
    } else if (entry.level == LogLevel.warning) {
      debugPrint('\x1B[33m$output\x1B[0m'); // Yellow for warnings
    } else if (entry.level == LogLevel.info) {
      debugPrint('\x1B[36m$output\x1B[0m'); // Cyan for info
    } else {
      debugPrint(output); // Default for debug
    }
  }

  /// Format console output
  String _formatConsoleOutput(LogEntry entry) {
    final time = entry.timestamp.toLocal().toString().substring(11, 19);
    final tag = entry.tag != null ? '[${entry.tag}] ' : '';

    return '$time ${entry.level.emoji} $tag${entry.message}';
  }

  /// Store critical errors for crash reporting
  void _storeCriticalError(LogEntry entry) {
    try {
      final errors = StorageService.getObjectList('critical_errors') ?? [];
      errors.add(entry.toJson());

      // Keep only last 50 errors
      if (errors.length > 50) {
        errors.removeRange(0, errors.length - 50);
      }

      StorageService.setObjectList('critical_errors', errors);
    } catch (e) {
      debugPrint('Failed to store critical error: $e');
    }
  }

  // ==================== Convenience Methods ====================

  /// Log debug message
  static void debug(String message, [String? tag]) {
    log(LogLevel.debug, message, tag: tag);
  }

  /// Log info message
  static void info(String message, [String? tag]) {
    log(LogLevel.info, message, tag: tag);
  }

  /// Log warning message
  static void warning(String message, [String? tag]) {
    log(LogLevel.warning, message, tag: tag);
  }

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log fatal error
  static void fatal(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    log(LogLevel.fatal, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  // ==================== Advanced Features ====================

  /// Log with structured data
  static void structured(
      LogLevel level,
      String message,
      Map<String, dynamic> data, {
        String? tag,
      }) {
    log(level, message, extra: data, tag: tag);
  }

  /// Log API request
  static void apiRequest(String method, String url, {Map<String, dynamic>? data}) {
    structured(LogLevel.debug, 'API Request: $method $url', {
      'method': method,
      'url': url,
      'data': data,
    }, tag: 'API');
  }

  /// Log API response
  static void apiResponse(String url, int statusCode, {dynamic data}) {
    structured(LogLevel.debug, 'API Response: $statusCode $url', {
      'url': url,
      'statusCode': statusCode,
      'data': data,
    }, tag: 'API');
  }

  /// Log user action
  static void userAction(String action, {Map<String, dynamic>? context}) {
    structured(LogLevel.info, 'User Action: $action', {
      'action': action,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    }, tag: 'USER');
  }

  /// Log performance metric
  static void performance(String operation, Duration duration, {Map<String, dynamic>? details}) {
    structured(LogLevel.debug, 'Performance: $operation took ${duration.inMilliseconds}ms', {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'details': details,
    }, tag: 'PERF');
  }

  // ==================== Log Management ====================

  /// Get log stream
  static Stream<LogEntry> get logStream => instance._logStreamController.stream;

  /// Get recent logs
  static List<LogEntry> getRecentLogs([int count = 100]) {
    return instance._logBuffer.take(count).toList();
  }

  /// Get critical errors
  static List<Map<String, dynamic>> getCriticalErrors() {
    return StorageService.getObjectList('critical_errors') ?? [];
  }

  /// Clear critical errors
  static Future<void> clearCriticalErrors() async {
    await StorageService.remove('critical_errors');
  }

  /// Export logs
  static Future<String?> exportLogs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${appDir.path}/logs');

      if (!await logsDir.exists()) return null;

      final logFiles = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      final buffer = StringBuffer();
      buffer.writeln('=== App Logs Export ===');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('App Version: ${AppConfig.appVersion}');
      buffer.writeln('Build: ${AppConfig.buildNumber}');
      buffer.writeln('Environment: ${AppConfig.flavor.name}');
      buffer.writeln('');

      for (final file in logFiles) {
        buffer.writeln('=== ${file.path.split('/').last} ===');
        final content = await file.readAsString();
        buffer.writeln(content);
        buffer.writeln('');
      }

      return buffer.toString();
    } catch (e) {
      error('Failed to export logs', e);
      return null;
    }
  }

  /// Get log statistics
  static Map<String, dynamic> getLogStats() {
    final instance = AppLogger.instance;
    return {
      'bufferSize': instance._logBuffer.length,
      'minLevel': _minLevel.name,
      'fileLoggingEnabled': _enableFileLogging,
      'consoleLoggingEnabled': _enableConsoleLogging,
      'maxLogFiles': _maxLogFiles,
      'maxLogFileSize': _maxLogFileSize,
      'currentLogFile': instance._currentLogFile?.path,
    };
  }

  /// Set log level
  static void setLogLevel(LogLevel level) {
    _minLevel = level;
    info('Log level changed to: ${level.name}');
  }

  /// Enable/disable file logging
  static Future<void> setFileLogging(bool enabled) async {
    _enableFileLogging = enabled;
    if (enabled) {
      await instance._initializeFileLogging();
    }
    info('File logging ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable/disable console logging
  static void setConsoleLogging(bool enabled) {
    _enableConsoleLogging = enabled;
    info('Console logging ${enabled ? 'enabled' : 'disabled'}');
  }

  // ==================== Cleanup ====================

  /// Dispose logger
  static Future<void> dispose() async {
    final instance = AppLogger.instance;
    instance._flushTimer?.cancel();
    await instance._flushLogs();
    await instance._logStreamController.close();
    _instance = null;
  }
}