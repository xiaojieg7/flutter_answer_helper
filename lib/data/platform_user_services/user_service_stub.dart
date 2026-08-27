// Stub implementation - overridden by platform-specific implementations
import '../user_service.dart';

class UserServiceImpl {
  static UserService? _instance;

  static UserService getInstance() {
    if (_instance == null) {
      throw UnsupportedError('No platform implementation');
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
