import 'captcha_service.dart';
import 'captcha_service_stub.dart'
    if (dart.library.html) 'captcha_service_web.dart'
    if (dart.library.io) 'captcha_service_mobile.dart';

class CaptchaServiceFactory {
  static CaptchaService? _instance;

  static CaptchaService getInstance() {
    _instance ??= createCaptchaService();
    return _instance!;
  }
  
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
  
  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
