import 'package:flutter/foundation.dart';

class AppLogger {
  static void error(String message) {
    if (kDebugMode) {
      debugPrint('\x1B[31m[ERROR] $message\x1B[0m');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('\x1B[33m[WARNING] $message\x1B[0m');
    }
  }
}
