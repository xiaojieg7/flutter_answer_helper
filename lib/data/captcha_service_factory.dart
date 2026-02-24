import 'package:flutter/foundation.dart';
import 'captcha_service.dart';
import 'platform_captcha_services/android_captcha_service.dart';
import 'platform_captcha_services/web_captcha_service.dart';

class CaptchaServiceFactory {
  static CaptchaService? _instance;

  static CaptchaService getInstance() {
    if (_instance == null) {
      if (kIsWeb) {
        _instance = WebCaptchaService();
      } else {
        _instance = AndroidCaptchaService();
      }
    }
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }
}
