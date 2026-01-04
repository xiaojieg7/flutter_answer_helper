import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithBottomTab extends StatefulWidget {
  final Widget child;

  const ScaffoldWithBottomTab({Key? key, required this.child}) : super(key: key);

  @override
  State<ScaffoldWithBottomTab> createState() => _ScaffoldWithBottomTabState();
}

class _ScaffoldWithBottomTabState extends State<ScaffoldWithBottomTab> {
  // 当前选中的tab索引
  int _currentIndex = 0;

  // tab项定义
  final List<BottomNavigationBarItem> _bottomTabs = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: '首页',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.favorite),
      label: '收藏',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: '设置',
    ),
  ];

  // tab对应的路由
  final List<String> _routes = [
    '/',
    '/favorites',
    '/settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: _bottomTabs,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // 导航到对应的页面
          context.go(_routes[index]);
        },
      ),
    );
  }
}
