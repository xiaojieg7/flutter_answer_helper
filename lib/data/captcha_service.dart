import 'package:flutter/material.dart';

abstract class CaptchaService {
  Widget buildCaptchaWidget({
    required Function(Map<String, String>) onCaptchaCompleted,
    required Function onCaptchaError,
  });
  
  Future<void> initialize();
  
  Future<void> showCaptcha();
  
  Future<void> hideCaptcha();
  
  Future<void> refreshCaptcha();
  
  void dispose();
}
