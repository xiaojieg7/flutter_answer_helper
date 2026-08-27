import '../user_service.dart';
import '../models/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../api/auth_service.dart';

class UserServiceImpl {
  static UserService? _instance;

  static UserService getInstance() {
    if (_instance == null) {
      _instance = AndroidUserService();
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

class AndroidUserService implements UserService {
  late Database _database;

  @override
  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'users.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
    final id = await _database.insert('users', {
      'username': username,
      'email': email,
      'password': password,
      'created_at': DateTime.now().toIso8601String(),
    });

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
    final authInfo = AuthService.currentUser;
    if (authInfo != null) {
      return User(
        id: 0,
        username: authInfo.username,
        email: authInfo.email,
        password: '',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await AuthService.logout();
  }

  @override
  Future<bool> isLoggedIn() async {
    return AuthService.isLoggedIn;
  }

  @override
  Future<User> updateUser(User user) async {
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
    await _database.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
