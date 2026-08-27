import 'captcha_service.dart';
import 'platform_captcha_services/android_captcha_service.dart';

/// Mobile implementation
CaptchaService createCaptchaService() {
  return AndroidCaptchaService();
}
