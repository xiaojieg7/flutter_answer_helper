import 'package:flutter/material.dart';
import '../data/captcha_service.dart';
import '../data/captcha_service_factory.dart';

class CaptchaWebview extends StatefulWidget {
  final Function(String) onCaptchaCompleted;
  final Function(CaptchaRefreshReason) onCaptchaRefresh;
  final Function(String) onError;

  const CaptchaWebview({
    Key? key,
    required this.onCaptchaCompleted,
    required this.onCaptchaRefresh,
    required this.onError,
  }) : super(key: key);

  @override
  State<CaptchaWebview> createState() => _CaptchaWebviewState();
}

class _CaptchaWebviewState extends State<CaptchaWebview> {
  final _captchaService = CaptchaServiceFactory.getInstance();

  @override
  void dispose() {
    _captchaService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _captchaService.buildCaptchaWidget(
      onCaptchaCompleted: widget.onCaptchaCompleted,
      onCaptchaRefresh: widget.onCaptchaRefresh,
      onError: widget.onError,
    );
  }
}
