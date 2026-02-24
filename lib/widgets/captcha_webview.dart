import 'package:flutter/material.dart';
import '../data/captcha_service_factory.dart';

class CaptchaWebview extends StatefulWidget {
  final Function(Map<String, String>) onCaptchaCompleted;
  final Function onCaptchaError;

  const CaptchaWebview({
    Key? key,
    required this.onCaptchaCompleted,
    required this.onCaptchaError,
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
      onCaptchaError: widget.onCaptchaError,
    );
  }
}
