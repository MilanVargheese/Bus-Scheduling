import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Backend runs on port 8000.
  // Android emulator should use 10.0.2.2 to reach host.
  static const String _hostLanIp = "10.0.2.2";
  static const int _port = 8000;
  static const bool _useAdbReverse = false;

  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:$_port";
    }
    if (Platform.isAndroid) {
      if (_useAdbReverse) {
        return "http://127.0.0.1:$_port";
      }
      return "http://$_hostLanIp:$_port";
    }
    return "http://127.0.0.1:$_port";
  }

  static Future<http.StreamedResponse> sendWithTimeout(
    http.MultipartRequest request,
  ) async {
    return await request.send().timeout(const Duration(seconds: 60));
  }
}
