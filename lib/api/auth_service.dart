import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfo {
  final String userId;
  final String username;
  final String email;
  final int aiPoints;

  UserInfo({
    required this.userId,
    required this.username,
    required this.email,
    required this.aiPoints,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      aiPoints: json['aiPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'aiPoints': aiPoints,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final int expiresIn;
  final String? deviceFingerprintWand;
  final UserInfo userInfo;

  AuthResponse({
    required this.accessToken,
    required this.expiresIn,
    this.deviceFingerprintWand,
    required this.userInfo,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      expiresIn: json['expires_in'] ?? 0,
      deviceFingerprintWand: json['DeviceFingerprint_wand'],
      userInfo: UserInfo.fromJson(json['userInfo'] ?? {}),
    );
  }
}

class AuthService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyUserInfo = 'user_info';
  static const String _keyDeviceId = 'device_id';

  static String? _cachedAccessToken;
  static UserInfo? _cachedUserInfo;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedAccessToken = prefs.getString(_keyAccessToken);
    final json = prefs.getString(_keyUserInfo);
    if (json != null) {
      _cachedUserInfo = UserInfo.fromJson(jsonDecode(json));
    }
    _isInitialized = true;
  }

  static bool get isLoggedIn => _cachedAccessToken != null && _cachedAccessToken!.isNotEmpty;
  static UserInfo? get currentUser => _cachedUserInfo;

  static Future<void> saveAuth(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, auth.accessToken);
    await prefs.setString(_keyUserInfo, jsonEncode(auth.userInfo.toJson()));
    if (auth.deviceFingerprintWand != null) {
      await prefs.setString(_keyDeviceId, auth.deviceFingerprintWand!);
    }
    _cachedAccessToken = auth.accessToken;
    _cachedUserInfo = auth.userInfo;
  }

  static Future<String?> getAccessToken() async {
    await _ensureInitialized();
    return _cachedAccessToken;
  }

  static Future<UserInfo?> getUserInfo() async {
    await _ensureInitialized();
    return _cachedUserInfo;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyUserInfo);
    _cachedAccessToken = null;
    _cachedUserInfo = null;
  }

  static Future<String?> getDeviceId() async {
    await _ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDeviceId);
  }

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
