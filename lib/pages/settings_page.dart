import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  // 清除缓存
  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清除')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('清除缓存'),
            subtitle: const Text('清除所有题库和学习记录'),
            onTap: () => _clearCache(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('答题助手 v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '答题助手',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 答题助手',
              );
            },
          ),
        ],
      ),
    );
  }
}
