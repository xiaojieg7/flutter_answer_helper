import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_service.dart';
import '../api/exceptions.dart';
import '../data/captcha_service.dart';
import '../widgets/captcha_webview.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showCaptcha = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startRegister() {
    print('开始注册流程');
    if (_formKey.currentState!.validate()) {
      print('表单验证通过，显示验证码');
      setState(() {
        _showCaptcha = true;
        _errorMessage = null;
      });
    }
  }

  Future<void> _onCaptchaCompleted(String captchaVerifyParam) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.sendCaptcha(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        captchaVerifyParam: captchaVerifyParam,
      );

      setState(() {
        _showCaptcha = false;
        _isLoading = false;
      });

      context.push(
        '/email-verification',
        extra: {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        },
      );
    } on CaptchaNeedRefreshException catch (e) {
      setState(() {
        _isLoading = false;
        _showCaptcha = false;
        _errorMessage = e.message;
      });
      _refreshCaptcha();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showCaptcha = false;
        _errorMessage = '发送失败：$e';
      });
    }
  }

  void _onCaptchaRefresh(CaptchaRefreshReason reason) {
    print('验证码刷新回调: $reason');
    
    switch (reason) {
      case CaptchaRefreshReason.userClosed:
        setState(() {
          _showCaptcha = false;
          _errorMessage = null;
        });
        break;
      case CaptchaRefreshReason.verifyFailed:
        setState(() {
          _errorMessage = '验证失败，请重新验证';
        });
        _refreshCaptcha();
        break;
      case CaptchaRefreshReason.expired:
        setState(() {
          _errorMessage = '验证码已过期，请重新验证';
        });
        _refreshCaptcha();
        break;
      case CaptchaRefreshReason.loadFailed:
        setState(() {
          _showCaptcha = false;
          _errorMessage = '验证码加载失败，请重试';
        });
        break;
    }
  }

  void _refreshCaptcha() {
    setState(() {
      _showCaptcha = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showCaptcha = true;
        });
      }
    });
  }

  void _onCaptchaError(String error) {
    setState(() {
      _showCaptcha = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '注册',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      '创建账号',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        hintText: '请输入用户名，至少4个字符',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入用户名';
                        }
                        if (value.length < 4) {
                          return '用户名长度至少为4位';
                        }
                        if (!RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9@_&^]+$').hasMatch(value)) {
                          return '用户名只支持中文、英文、数字及@_&^符号';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        hintText: '请输入邮箱地址',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入邮箱';
                        }
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                          return '请输入有效的邮箱地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        hintText: '请输入密码',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        if (value.length < 6) {
                          return '密码长度至少为6位';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '确认密码',
                        hintText: '请再次输入密码',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请确认密码';
                        }
                        if (value != _passwordController.text) {
                          return '两次输入的密码不一致';
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
                      onPressed: _isLoading ? null : _startRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '注册',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('已有账号？'),
                        TextButton(
                          onPressed: () {
                            context.go('/login');
                          },
                          child: const Text('立即登录'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_showCaptcha)
            CaptchaWebview(
              onCaptchaCompleted: _onCaptchaCompleted,
              onCaptchaRefresh: _onCaptchaRefresh,
              onError: _onCaptchaError,
            ),
        ],
      ),
    );
  }
}
