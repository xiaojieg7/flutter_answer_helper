import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_service.dart';

class EmailVerificationPage extends StatefulWidget {
  final String username;
  final String email;
  final String password;

  const EmailVerificationPage({
    Key? key,
    required this.username,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _captchaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
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

  @override
  void dispose() {
    _captchaController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.register(
        username: widget.username,
        email: widget.email,
        password: widget.password,
        captcha: _captchaController.text.trim(),
      );

      await ApiService.login(
        email: widget.email,
        password: widget.password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功，正在跳转...')),
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '注册失败：$e';
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
        title: const Text('邮箱验证'),
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
                Icons.email_outlined,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),
              Text(
                '验证码已发送至',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
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
              const SizedBox(height: 20),
              
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
                onPressed: _isLoading ? null : _verifyAndRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '完成注册',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '没有收到验证码？',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: _countdown > 0 || _isLoading ? null : () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      _countdown > 0 ? '重新发送($_countdown)' : '返回重发',
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
