// Web implementation of user service
import '../user_service.dart';
import '../models/user.dart';
import '../../api/auth_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserServiceImpl {
  static UserService? _instance;

  static UserService getInstance() {
    if (_instance == null) {
      _instance = WebUserService();
    }
    return _instance!;
  }

  static void setInstance(UserService service) {
    _instance = service;
  }

  static void resetInstance() {
    _instance = null;
  }
}

class WebUserService implements UserService {
  static const String _userKey = 'current_user';
  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<User> register(String username, String email, String password) async {
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch,
      username: username,
      email: email,
      password: password,
      createdAt: DateTime.now(),
    );
    await _saveCurrentUser(user);
    return user;
  }

  @override
  Future<User?> login(String email, String password) async {
    final userInfo = AuthService.currentUser;
    if (userInfo != null) {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch,
        username: userInfo.username,
        email: userInfo.email,
        password: '',
        createdAt: DateTime.now(),
      );
      await _saveCurrentUser(user);
      return user;
    }
    return null;
  }

  @override
  Future<User?> getCurrentUser() async {
    final authInfo = AuthService.currentUser;
    if (authInfo != null) {
      return User(
        id: DateTime.now().millisecondsSinceEpoch,
        username: authInfo.username,
        email: authInfo.email,
        password: '',
        createdAt: DateTime.now(),
      );
    }
    return _getCurrentUserFromPrefs();
  }

  @override
  Future<void> logout() async {
    await AuthService.logout();
    await _clearCurrentUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return AuthService.isLoggedIn;
  }

  @override
  Future<User> updateUser(User user) async {
    await _saveCurrentUser(user);
    return user;
  }

  @override
  Future<void> deleteUser(int userId) async {
    await _clearCurrentUser();
  }

  Future<void> _saveCurrentUser(User user) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  User? _getCurrentUserFromPrefs() {
    final json = _prefs?.getString(_userKey);
    if (json != null) {
      return User.fromMap(jsonDecode(json));
    }
    return null;
  }

  Future<void> _clearCurrentUser() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
