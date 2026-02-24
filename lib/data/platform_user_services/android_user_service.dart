import '../user_service.dart';
import '../models/user.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AndroidUserService implements UserService {
  late Database _database;

  @override
  Future<void> initialize() async {
    // 初始化SQLite数据库
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'users.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 创建用户表
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<User> register(String username, String email, String password) async {
    // 插入用户数据
    final id = await _database.insert('users', {
      'username': username,
      'email': email,
      'password': password, // 实际项目中应该加密存储密码
      'created_at': DateTime.now().toIso8601String(),
    });

    // 返回创建的用户
    return User(
      id: id,
      username: username,
      email: email,
      password: password,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<User?> login(String email, String password) async {
    // 查询用户
    final List<Map<String, dynamic>> maps = await _database.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<User?> getCurrentUser() async {
    // 模拟获取当前用户，实际项目中应该存储登录状态
    // 这里简单返回第一个用户
    final List<Map<String, dynamic>> maps = await _database.query('users', limit: 1);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    // 模拟登出，实际项目中应该清除登录状态
  }

  @override
  Future<bool> isLoggedIn() async {
    // 模拟检查登录状态，实际项目中应该检查存储的登录状态
    return await getCurrentUser() != null;
  }

  @override
  Future<User> updateUser(User user) async {
    // 更新用户信息
    await _database.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }

  @override
  Future<void> deleteUser(int userId) async {
    // 删除用户
    await _database.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}