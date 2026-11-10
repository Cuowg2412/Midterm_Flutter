import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const _tokenKey = 'auth_jwt_token';
  static const _emailKey = 'auth_user_email';
  static const _hotenKey = 'auth_user_hoten';

  static String? _token;
  static String? _currentUserEmail;
  static String? _currentUserHoten;

  static String? get token => _token;
  static String? get currentUserEmail => _currentUserEmail;
  static String? get currentUserHoten => _currentUserHoten;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // Khôi phục phiên đăng nhập khi F5 Web hoặc mở lại app
  static Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      _currentUserEmail = prefs.getString(_emailKey);
      _currentUserHoten = prefs.getString(_hotenKey);
    } catch (_) {}
  }

  static Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString(_tokenKey, _token!);
      if (_currentUserEmail != null) {
        await prefs.setString(_emailKey, _currentUserEmail!);
      }
      if (_currentUserHoten != null) {
        await prefs.setString(_hotenKey, _currentUserHoten!);
      }
    } catch (_) {}
  }

  // Đăng nhập
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'matkhau': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _token = data['token'];
      _currentUserEmail = data['user']?['email'];
      _currentUserHoten = data['user']?['hoten'];
      await _saveSession();
      return {
        'success': true,
        'message': data['message'] ?? 'Đăng nhập thành công'
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Đăng nhập thất bại'
      };
    }
  }

  // Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register(
      String email, String matkhau, String hoten) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'matkhau': matkhau,
        'hoten': hoten,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {
        'success': true,
        'message': data['message'] ?? 'Đăng ký thành công'
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Đăng ký thất bại'
      };
    }
  }

  // Đăng xuất
  static Future<void> logout() async {
    _token = null;
    _currentUserEmail = null;
    _currentUserHoten = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_hotenKey);
    } catch (_) {}
  }

  // Header có token
  static Map<String, String> get authHeaders {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }
}
