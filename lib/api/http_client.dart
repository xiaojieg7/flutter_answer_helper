import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'token_service.dart';
import 'exceptions.dart';
import 'auth_service.dart';

enum HttpMethod { get, post, put, delete, patch }

class HttpRequest {
  final String path;
  final HttpMethod method;
  final Map<String, dynamic>? body;
  final Map<String, String>? headers;
  final Map<String, String>? queryParameters;
  final bool requiresAuth;
  
  HttpRequest({
    required this.path,
    this.method = HttpMethod.get,
    this.body,
    this.headers,
    this.queryParameters,
    this.requiresAuth = false,
  });
}

class HttpResponse {
  final int statusCode;
  final dynamic data;
  final Map<String, String> headers;
  
  HttpResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
  });
  
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();
  
  final String _baseUrl = AppConfig.baseUrl;
  final TokenService _tokenService = TokenService();
  
  static const int _tokenExpiredCode = 401;
  static const int _deviceNotTrustCode = 402;
  
  Function(String email, String message)? onDeviceNotTrust;
  
  final List<Function(int statusCode, dynamic response)> _responseInterceptors = [];
  
  void addResponseInterceptor(Function(int statusCode, dynamic response) interceptor) {
    _responseInterceptors.add(interceptor);
  }
  
  void removeResponseInterceptor(Function(int statusCode, dynamic response) interceptor) {
    _responseInterceptors.remove(interceptor);
  }
  
  Future<HttpResponse> request(HttpRequest request) async {
    return _executeRequest(request);
  }
  
  Future<HttpResponse> _executeRequest(HttpRequest request, {bool isRetry = false}) async {
    final uri = _buildUri(request.path, request.queryParameters);
    final headers = _buildHeaders(request);
    
    print('${request.method.name.toUpperCase()} $uri');
    if (request.body != null) {
      print('Request Body: ${jsonEncode(request.body)}');
    }
    
    http.Response response;
    
    try {
      switch (request.method) {
        case HttpMethod.get:
          response = await http.get(uri, headers: headers);
          break;
        case HttpMethod.post:
          response = await http.post(uri, headers: headers, body: jsonEncode(request.body));
          break;
        case HttpMethod.put:
          response = await http.put(uri, headers: headers, body: jsonEncode(request.body));
          break;
        case HttpMethod.delete:
          response = await http.delete(uri, headers: headers, body: jsonEncode(request.body));
          break;
        case HttpMethod.patch:
          response = await http.patch(uri, headers: headers, body: jsonEncode(request.body));
          break;
      }
    } catch (e) {
      print('请求异常: $e');
      throw NetworkException('网络请求失败: $e');
    }
    
    print('Response: ${response.statusCode} - ${response.body}');
    
    dynamic responseData;
    try {
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body);
      }
    } catch (e) {
      responseData = response.body;
    }
    
    for (final interceptor in _responseInterceptors) {
      interceptor(response.statusCode, responseData);
    }
    
    if (response.statusCode == _tokenExpiredCode && request.requiresAuth && !isRetry) {
      print('Token已过期，尝试刷新...');
      final refreshed = await _tokenService.refreshAccessToken();
      if (refreshed) {
        print('Token刷新成功，重试请求');
        return _executeRequest(request, isRetry: true);
      } else {
        print('Token刷新失败');
        throw TokenExpiredException('登录已过期，请重新登录');
      }
    }
    
    if (response.statusCode == _deviceNotTrustCode && responseData is Map) {
      final message = responseData['message'] ?? '新设备需要验证';
      final email = responseData['email'] ?? '';
      
      print('检测到新设备登录，需要验证: $email');
      
      if (onDeviceNotTrust != null) {
        onDeviceNotTrust!(email, message);
      } else {
        throw DeviceNotTrustException(message, email: email);
      }
    }
    
    if (response.statusCode == 200 && responseData is Map) {
      final accessToken = responseData['access_token'];
      if (accessToken != null) {
        final authResponse = AuthResponse.fromJson(responseData.cast<String, dynamic>());
        await AuthService.saveAuth(authResponse);
        _tokenService.setTokens(
          accessToken: accessToken,
          refreshToken: responseData['refresh_token'],
        );
      }
    }
    
    return HttpResponse(
      statusCode: response.statusCode,
      data: responseData,
      headers: response.headers,
    );
  }
  
  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    String url = '$_baseUrl$path';
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final queryString = queryParameters.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url?$queryString';
    }
    return Uri.parse(url);
  }
  
  Map<String, String> _buildHeaders(HttpRequest request) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?request.headers,
    };
    
    if (request.requiresAuth && _tokenService.hasToken) {
      headers['Authorization'] = 'Bearer ${_tokenService.accessToken}';
    }
    
    return headers;
  }
  
  Future<HttpResponse> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) {
    return request(HttpRequest(
      path: path,
      method: HttpMethod.get,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    ));
  }
  
  Future<HttpResponse> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) {
    return request(HttpRequest(
      path: path,
      method: HttpMethod.post,
      body: body,
      requiresAuth: requiresAuth,
    ));
  }
  
  Future<HttpResponse> put(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) {
    return request(HttpRequest(
      path: path,
      method: HttpMethod.put,
      body: body,
      requiresAuth: requiresAuth,
    ));
  }
  
  Future<HttpResponse> delete(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) {
    return request(HttpRequest(
      path: path,
      method: HttpMethod.delete,
      body: body,
      requiresAuth: requiresAuth,
    ));
  }
  
  Future<HttpResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) {
    return request(HttpRequest(
      path: path,
      method: HttpMethod.patch,
      body: body,
      requiresAuth: requiresAuth,
    ));
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}
