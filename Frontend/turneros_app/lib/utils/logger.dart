import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _name = 'Turneros';

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: _name,
        level: 500, // DEBUG level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 800, // INFO level
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 900, // WARNING level
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _name,
      level: 1000, // ERROR level
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void auth(String message, [Object? error, StackTrace? stackTrace]) {
    info('🔐 AUTH: $message', error, stackTrace);
  }

  static void api(String message, [Object? error, StackTrace? stackTrace]) {
    info('🌐 API: $message', error, stackTrace);
  }

  static void firestore(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    info('🔥 FIRESTORE: $message', error, stackTrace);
  }

  static void ui(String message, [Object? error, StackTrace? stackTrace]) {
    debug('🎨 UI: $message', error, stackTrace);
  }
}
