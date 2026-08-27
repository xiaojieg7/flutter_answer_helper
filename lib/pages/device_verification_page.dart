import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_service.dart';
import '../api/auth_service.dart';

class DeviceVerificationPage extends StatefulWidget {
  final String email;

  const DeviceVerificationPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<DeviceVerificationPage> createState() => _DeviceVerificationPageState();
}

class _DeviceVerificationPageState extends State<DeviceVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _captchaController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingCaptcha = false;
  String? _errorMessage;
  int _countdown = 0;

  static String? _lastEmail;
  static int? _captchaSentTime;
  static const int _captchaCooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _initCountdown();
    if (!_hasCaptchaBeenSentRecently()) {
      _sendLoginCaptcha();
    }
  }

  void _initCountdown() {
    if (_lastEmail == widget.email && _captchaSentTime != null) {
      final elapsed = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(_captchaSentTime!),
      ).inSeconds;
      final remaining = _captchaCooldownSeconds - elapsed;
      if (remaining > 0) {
        _countdown = remaining;
        _startCountdownFromRemaining();
      } else {
        _countdown = 0;
      }
    } else {
      _countdown = 0;
    }
  }

  bool _hasCaptchaBeenSentRecently() {
    if (_lastEmail != widget.email || _captchaSentTime == null) {
      return false;
    }
    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(_captchaSentTime!),
    ).inSeconds;
    return elapsed < _captchaCooldownSeconds;
  }

  @override
  void dispose() {
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _sendLoginCaptcha() async {
    if (_countdown > 0 || _isSendingCaptcha) {
      return;
    }

    setState(() {
      _isSendingCaptcha = true;
      _errorMessage = null;
    });

    try {
      await ApiService.sendLoginCaptcha(email: widget.email);

      if (mounted) {
        _lastEmail = widget.email;
        _captchaSentTime = DateTime.now().millisecondsSinceEpoch;
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送，请查收')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '发送验证码失败：$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCaptcha = false;
        });
      }
    }
  }

  void _startCountdown() {
    setState(() {
      _countdown = _captchaCooldownSeconds;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown <= 0) return false;
      setState(() {
        _countdown--;
      });
      return _countdown > 0;
    });
  }

  void _startCountdownFromRemaining() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown <= 0) return false;
      setState(() {
        _countdown--;
      });
      return _countdown > 0;
    });
  }

  Future<void> _verifyDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.addTrustDevice(
        account: widget.email,
        verificationCode: _captchaController.text.trim(),
      );

      final accessToken = response['access_token'];
      final expiresIn = response['expires_in'];
      final deviceFingerprintWand = response['DeviceFingerprint_wand'];
      final userInfoJson = response['userInfo'];

      if (accessToken != null) {
        final authResponse = AuthResponse.fromJson({
          'access_token': accessToken,
          'expires_in': expiresIn ?? 3600,
          'DeviceFingerprint_wand': deviceFingerprintWand,
          'userInfo': userInfoJson ?? {},
        });

        await AuthService.saveAuth(authResponse);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证成功，正在登录...')),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/user');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '验证失败：$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设备验证',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.devices_outlined,
                size: 80,
                color: Color(0xFF4A90E2),
              ),
              const SizedBox(height: 30),
              const Text(
                '检测到新设备登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '验证码已发送至 ${widget.email}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: _captchaController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  hintText: '请输入6位验证码',
                  border: OutlineInputBorder(),
                ),
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入验证码';
                  }
                  if (value.length != 6) {
                    return '验证码为6位数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              ElevatedButton(
                onPressed: _isLoading ? null : _verifyDevice,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF4A90E2),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '确认验证',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '无法收到验证码？',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _countdown > 0 || _isLoading || _isSendingCaptcha
                        ? null
                        : _sendLoginCaptcha,
                    child: Text(
                      _countdown > 0
                          ? '$_countdown秒后可重新发送'
                          : '重新发送',
                      style: TextStyle(
                        color: _countdown > 0
                            ? const Color(0xFF757575)
                            : const Color(0xFF4A90E2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
