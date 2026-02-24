import 'models/user.dart';

abstract class UserService {
  // 初始化用户服务
  Future<void> initialize();

  // 用户注册
  Future<User> register(String username, String email, String password);

  // 用户登录
  Future<User?> login(String email, String password);

  // 获取当前登录用户
  Future<User?> getCurrentUser();

  // 用户登出
  Future<void> logout();

  // 检查用户是否已登录
  Future<bool> isLoggedIn();

  // 更新用户信息
  Future<User> updateUser(User user);

  // 删除用户
  Future<void> deleteUser(int userId);
}