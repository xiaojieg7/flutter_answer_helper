import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithBottomTab extends StatefulWidget {
  final Widget child;

  const ScaffoldWithBottomTab({Key? key, required this.child}) : super(key: key);

  @override
  State<ScaffoldWithBottomTab> createState() => _ScaffoldWithBottomTabState();
}

class _ScaffoldWithBottomTabState extends State<ScaffoldWithBottomTab> {
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

  final List<String> _routes = [
    '/',
    '/favorites',
    '/settings',
  ];

  bool _shouldShowBottomBar(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    return _routes.contains(location);
  }

  int _getCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _routes.length; i++) {
      if (location == _routes[i]) {
        return i;
      }
    }
    return 0;
  }

  // 处理滑动切换
  void _handleSwipe(DragEndDetails details, BuildContext context) {
    final int currentIndex = _getCurrentIndex(context);
    
    // 判断滑动方向
    if (details.velocity.pixelsPerSecond.dx > 0) {
      // 右滑，切换到上一个页面
      if (currentIndex > 0) {
        // 传递滑动方向参数，右滑时新页面从右向左滑入
        context.go('${_routes[currentIndex - 1]}?swipe=right');
      }
    } else if (details.velocity.pixelsPerSecond.dx < 0) {
      // 左滑，切换到下一个页面
      if (currentIndex < _routes.length - 1) {
        // 传递滑动方向参数，左滑时新页面从左向右滑入
        context.go('${_routes[currentIndex + 1]}?swipe=left');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showBottomBar = _shouldShowBottomBar(context);
    final int currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: GestureDetector(
        // 只在一级页面添加滑动手势
        onHorizontalDragEnd: showBottomBar ? (details) => _handleSwipe(details, context) : null,
        child: widget.child,
      ),
      bottomNavigationBar: showBottomBar
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              items: _bottomTabs,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                // Tab点击时，根据索引比较确定动画方向
                final bool isForward = index > currentIndex;
                context.go('${_routes[index]}?swipe=${isForward ? 'left' : 'right'}');
              },
            )
          : null,
    );
  }
}
