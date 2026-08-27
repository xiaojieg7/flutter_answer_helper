import 'captcha_service.dart';
import 'platform_captcha_services/web_captcha_service.dart';

/// Web implementation
CaptchaService createCaptchaService() {
  return WebCaptchaService();
}
