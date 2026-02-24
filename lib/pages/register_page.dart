import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/api_service.dart';
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
  Map<String, String>? _captchaData;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    print('开始注册流程');
    if (_formKey.currentState!.validate()) {
      print('表单验证通过');
      // 检查是否已完成验证码
      if (_captchaData == null) {
        print('验证码未完成，准备显示验证码');
        // 显示验证码遮罩层
        setState(() {
          _showCaptcha = true;
        });
        
        // embed模式会自动显示验证码，不需要手动调用showCaptcha方法
        print('验证码组件已显示，使用embed模式自动加载');
        
        
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // 调用服务器注册接口
        await ApiService.register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          captcha: _captchaData!,
        );

        // 注册成功，跳转到登录页面
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功，请登录')),
        );
        context.go('/login');
      } catch (e) {
        setState(() {
          _errorMessage = '注册失败：$e';
          // 清除验证码数据，以便用户可以重新验证
          _captchaData = null;
        });
      } finally {
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
        title: const Text('注册'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
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

                  // 用户名输入框
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
                      // 检查用户名格式，支持中文、英文、数字及@_&^符号
                      if (!RegExp(r'^[\\u4e00-\\u9fa5a-zA-Z0-9@_&^]+$').hasMatch(value)) {
                        return '用户名只支持中文、英文、数字及@_&^符号';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 邮箱输入框
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

                  // 密码输入框
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

                  // 确认密码输入框
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

                  // 错误提示
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // 注册按钮
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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

                  // 跳转到登录页面
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
          
          // 验证码
          if (_showCaptcha)
            CaptchaWebview(
              onCaptchaCompleted: (data) {
                setState(() {
                  _captchaData = data;
                  _showCaptcha = false;
                });
                _register();
              },
              onCaptchaError: () {
                setState(() {
                  _showCaptcha = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('验证码加载失败，请重试')),
                );
              },
            ),
        ],
      ),
    );
  }
}
