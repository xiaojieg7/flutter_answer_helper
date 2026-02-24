import 'package:flutter/foundation.dart';
import 'user_service.dart';
import 'platform_user_services/android_user_service.dart';
import 'platform_user_services/web_user_service.dart';

class UserServiceFactory {
  static UserService? _instance;

  UserServiceFactory._();

  static UserService getInstance() {
    if (_instance == null) {
      if (kIsWeb) {
        _instance = WebUserService();
      } else {
        _instance = AndroidUserService();
      }
    }
    return _instance!;
  }

  static void resetInstance() {
    _instance = null;
  }
}
