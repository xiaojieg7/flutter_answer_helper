import 'http_client.dart';
import 'exceptions.dart';
import 'device_fingerprint_service.dart';

class ApiService {
  static final HttpClient _httpClient = HttpClient();
  
  static Future<Map<String, dynamic>> sendCaptcha({
    required String username,
    required String email,
    required String captchaVerifyParam,
  }) async {
    print('发送邮箱验证码请求: $username, $email');
    
    final response = await _httpClient.post(
      '/user/send-captcha',
      body: {
        'username': username,
        'email': email,
        'captchaVerifyParam': captchaVerifyParam,
      },
    );

    print('发送验证码响应: ${response.statusCode} - ${response.data}');

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else if (response.statusCode == 201) {
      throw CaptchaNeedRefreshException('人机验证未通过，请重新验证');
    } else {
      final message = response.data is Map 
          ? (response.data['message'] ?? '发送验证码失败')
          : '发送验证码失败';
      throw message is String ? message : '发送验证码失败';
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String captcha,
  }) async {
    print('发送注册请求: $username, $email');
    
    final deviceData = await DeviceFingerprintService.getDeviceData();
    
    final response = await _httpClient.post(
      '/user/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
        'captcha': captcha,
        'device_data': deviceData,
      },
    );

    print('注册响应: ${response.statusCode} - ${response.data}');

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      final message = response.data is Map 
          ? (response.data['message'] ?? '注册失败')
          : '注册失败';
      throw message is String ? message : '注册失败';
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    print('发送登录请求: $email');
    
    final deviceData = await DeviceFingerprintService.getDeviceData();
    
    final response = await _httpClient.post(
      '/user/login',
      body: {
        'email': email,
        'password': password,
        'device_data': deviceData,
      },
    );

    print('登录响应: ${response.statusCode} - ${response.data}');

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      final message = response.data is Map 
          ? (response.data['message'] ?? '登录失败')
          : '登录失败';
      throw message is String ? message : '登录失败';
    }
  }

  static Future<Map<String, dynamic>> sendLoginCaptcha({
    required String email,
  }) async {
    print('发送登录验证码请求: $email');
    
    final response = await _httpClient.post(
      '/user/send-login-captcha',
      body: {
        'email': email,
      },
    );

    print('发送登录验证码响应: ${response.statusCode} - ${response.data}');

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      final message = response.data is Map 
          ? (response.data['message'] ?? '发送验证码失败')
          : '发送验证码失败';
      throw message is String ? message : '发送验证码失败';
    }
  }

  static Future<Map<String, dynamic>> addTrustDevice({
    required String account,
    required String verificationCode,
  }) async {
    print('发送添加信任设备请求: $account');
    
    final deviceData = await DeviceFingerprintService.getDeviceData();
    
    final response = await _httpClient.post(
      '/user/add-trust-device',
      body: {
        'account': account,
        'verificationCode': verificationCode,
        'deviceInfo': deviceData,
      },
    );

    print('添加信任设备响应: ${response.statusCode} - ${response.data}');

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      final message = response.data is Map 
          ? (response.data['message'] ?? '验证失败')
          : '验证失败';
      throw message is String ? message : '验证失败';
    }
  }
}
