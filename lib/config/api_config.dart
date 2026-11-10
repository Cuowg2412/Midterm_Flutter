import 'package:flutter/foundation.dart';

class ApiConfig {
  static String? _customServerUrl;

  /// Đặt URL server tùy chỉnh (ví dụ: http://192.168.1.10:3000 khi chạy trên điện thoại thật)
  static void setCustomServerUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      _customServerUrl = null;
    } else {
      var normalized = url.trim();
      if (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      _customServerUrl = normalized;
    }
  }

  static String get serverUrl {
    if (_customServerUrl != null) {
      return _customServerUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator ánh xạ 10.0.2.2 tới localhost của máy host
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get baseUrl => '$serverUrl/api';

  static String get uploadUrl => serverUrl;
}
