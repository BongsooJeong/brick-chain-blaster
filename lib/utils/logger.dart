import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  final String tag;
  
  Logger(this.tag);
  
  void d(String message) {
    _log(LogLevel.debug, message);
  }
  
  void i(String message) {
    _log(LogLevel.info, message);
  }
  
  void w(String message) {
    _log(LogLevel.warning, message);
  }
  
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }
  
  void _log(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    if (!EnvConfig.instance.enableLogging && level == LogLevel.debug) {
      return;
    }
    
    final logPrefix = '[$tag][${_getLevelTag(level)}]';
    
    if (level == LogLevel.error) {
      debugPrint('$logPrefix $message');
      if (error != null) {
        debugPrint('$logPrefix Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$logPrefix StackTrace: $stackTrace');
      }
    } else {
      debugPrint('$logPrefix $message');
    }
  }
  
  String _getLevelTag(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}