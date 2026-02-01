import 'package:flutter/foundation.dart';

/// Centralized logging utility that automatically disables logs in release builds
class AppLogger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('$prefix $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }
}

