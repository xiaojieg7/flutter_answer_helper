import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'data/database_service_factory.dart';
import 'data/user_service_factory.dart';

void main() async {
  // 确保Flutter绑定完全初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库服务
  await DatabaseServiceFactory.getInstance().initialize();
  // 初始化用户服务
  await UserServiceFactory.getInstance().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '答题助手',
      theme: ThemeData(
        primarySwatch: Colors.blue, // primarySwatch必须是MaterialColor类型，不能是Color
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // 设置AppBar主题为透明
        appBarTheme: AppBarTheme(
          elevation: 0.0, // 移除阴影
          backgroundColor: Colors.transparent, // AppBar背景透明
          surfaceTintColor: Colors.transparent, // 移除Material 3的表面着色
          foregroundColor: Colors.black, // 确保文本和图标可见
        ),
        // 设置状态栏主题
        brightness: Brightness.light, // 使用浅色状态栏
      ),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
