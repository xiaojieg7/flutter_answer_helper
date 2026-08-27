import 'package:flutter/material.dart';

enum CaptchaRefreshReason {
  userClosed,
  verifyFailed,
  expired,
  loadFailed,
}

abstract class CaptchaService {
  Widget buildCaptchaWidget({
    required Function(String) onCaptchaCompleted,
    required Function(CaptchaRefreshReason) onCaptchaRefresh,
    required Function(String) onError,
  });
  
  Future<void> initialize();
  
  Future<void> showCaptcha();
  
  Future<void> hideCaptcha();
  
  Future<void> refreshCaptcha();
  
  void dispose();
}
