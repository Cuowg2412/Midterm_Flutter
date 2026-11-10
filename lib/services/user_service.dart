import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class UserService {
  // Lấy danh sách người dùng
  static Future<List<UserModel>> getUsers() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users'),
      headers: AuthService.authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      final err =
          _extractError(response.body, 'Không thể tải danh sách người dùng');
      throw Exception(err);
    }
  }

  // Thêm người dùng
  static Future<void> addUser(UserModel user) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users'),
      headers: AuthService.authHeaders,
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception(
          _extractError(response.body, 'Không thể thêm người dùng'));
    }
  }

  // Cập nhật người dùng
  static Future<void> updateUser(UserModel user) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/users/${user.id}'),
      headers: AuthService.authHeaders,
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
          _extractError(response.body, 'Không thể cập nhật người dùng'));
    }
  }

  // Xóa 1 người dùng
  static Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/users/$userId'),
      headers: AuthService.authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception(
          _extractError(response.body, 'Không thể xóa người dùng'));
    }
  }

  // Xóa nhiều người dùng cùng lúc
  static Future<int> deleteUsersBatch(List<String> ids) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/batch-delete'),
      headers: AuthService.authHeaders,
      body: jsonEncode({'ids': ids}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['deletedCount'] as num?)?.toInt() ?? ids.length;
    } else {
      throw Exception(
          _extractError(response.body, 'Không thể xóa hàng loạt người dùng'));
    }
  }

  // Xuất JSON chuẩn 4 trường
  static Future<String> exportUsersJson() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/export'),
      headers: AuthService.authHeaders,
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } else {
      throw Exception(_extractError(response.body, 'Không thể xuất dữ liệu'));
    }
  }

  // Upload hình ảnh
  static Future<String?> uploadImage(
      Uint8List imageBytes, String fileName) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/upload');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer ${AuthService.token}';

    final ext = fileName.split('.').last.toLowerCase();
    final subtype = ext == 'jpg'
        ? 'jpeg'
        : (['jpeg', 'png', 'gif', 'webp'].contains(ext) ? ext : 'png');

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: fileName,
      contentType: MediaType('image', subtype),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imageUrl'];
    }
    throw Exception(_extractError(response.body, 'Lỗi upload hình ảnh'));
  }

  // Lấy full URL hình ảnh
  static String getImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${ApiConfig.uploadUrl}$path';
  }

  static String _extractError(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return fallback;
  }
}
