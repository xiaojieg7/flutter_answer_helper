import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:3000'; // 替换为实际的服务器域名

  // 注册接口
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required Map<String, String> captcha,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'captcha': captcha,
      }),
    );

    if (response.statusCode == 200) {
      // 成功响应
      return jsonDecode(response.body);
    } else {
      // 失败响应
      throw Exception(jsonDecode(response.body)['message'] ?? '注册失败');
    }
  }

  // 登录接口（预留）
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? '登录失败');
    }
  }
}