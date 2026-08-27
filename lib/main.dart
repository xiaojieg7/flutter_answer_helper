import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'data/database_service_factory.dart';
import 'api/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 优先初始化认证服务，加载本地登录状态
  await AuthService.initialize();
  
  // 初始化数据库服务
  await DatabaseServiceFactory.getInstance().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '答题助手',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(), // 跟随系统亮暗自动切换
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
