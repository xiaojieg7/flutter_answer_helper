import 'user_service.dart';
import 'platform_user_services/user_service_stub.dart'
    if (dart.library.io) 'platform_user_services/android_user_service.dart'
    if (dart.library.html) 'platform_user_services/web_user_service.dart';

class UserServiceFactory {
  UserServiceFactory._();

  static UserService getInstance() {
    return UserServiceImpl.getInstance();
  }

  static void resetInstance() {
    UserServiceImpl.resetInstance();
  }
}
