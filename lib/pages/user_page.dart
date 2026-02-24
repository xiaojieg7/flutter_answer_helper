import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/user_service_factory.dart';
import '../data/models/user.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = UserServiceFactory.getInstance();
      _currentUser = await userService.getCurrentUser();
    } catch (e) {
      print('加载用户信息失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final userService = UserServiceFactory.getInstance();
      await userService.logout();
      setState(() {
        _currentUser = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登出成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登出失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? _buildNotLoggedInView()
              : _buildLoggedInView(),
    );
  }

  // 未登录状态的视图
  Widget _buildNotLoggedInView() {
    return Column(
      children: [
        // 上半部分：登录区域（占界面1/4）
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 点击头像跳转到登录界面
                GestureDetector(
                  onTap: () {
                    context.go('/login');
                  },
                  child: const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '点击头像登录',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // 下半部分：功能列表
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('设置'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 跳转到设置页面
                    context.go('/settings');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('帮助与反馈'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 跳转到帮助与反馈页面
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('关于'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 跳转到关于页面
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 已登录状态的视图
  Widget _buildLoggedInView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 用户信息卡片
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 60,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser!.username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentUser!.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '注册时间：${_currentUser!.createdAt.toString().substring(0, 10)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // 功能列表
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('学习历史'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 跳转到学习历史页面
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('设置'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 跳转到设置页面
                    context.go('/settings');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('帮助与反馈'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 跳转到帮助与反馈页面
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('关于'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // 跳转到关于页面
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('登出'),
                  textColor: Colors.red,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}