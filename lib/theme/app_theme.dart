import 'package:flutter/material.dart';

/// 应用设计令牌：与 pencil/answer_helper_design.pen 设计稿保持一致
class AppColors {
  AppColors._();

  // 主色系
  static const Color primary = Color(0xFF2196F3); // 主蓝（按钮/进度/选中）
  static const Color gradientStart = Color(0xFF4A90E2); // 科目卡渐变起始
  static const Color gradientEnd = Color(0xFF357ABD); // 科目卡渐变结束

  // 反馈色
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color errorRed = Color(0xFFF44336);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color selectedBg = Color(0xFFE3F2FD); // 选项选中浅蓝底
  static const Color starAmber = Color(0xFFFFB300); // 收藏星标琥珀色

  // 文字层级
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF757575);
  static const Color textQuaternary = Color(0xFF9E9E9E);

  // 边框与分割
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // 背景
  static const Color pageBg = Color(0xFFF5F7FA); // 首页/列表页背景
  static const Color cardPlainBg = Color(0xFFF5F5F5); // 解析卡等无阴影卡底

  /// 暗色模式下把浅色调映射为暗色调；浅色模式原样返回
  static Color adaptive(BuildContext context, Color light, Color dark) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// 构建浅色主题
ThemeData buildLightTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.gradientEnd,
    onSecondary: Colors.white,
    error: AppColors.errorRed,
    onError: Colors.white,
    background: Colors.white,
    onBackground: AppColors.textPrimary,
    surface: Colors.white,
    onSurface: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 28, // 全局规范：AppBar 标题统一 28 号
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48), // 触控目标 ≥48dp
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// 构建暗色主题（跟随系统切换）
ThemeData buildDarkTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF64B5F6), // 暗色下提亮的蓝
    onPrimary: Color(0xFF00243E),
    secondary: Color(0xFF64B5F6),
    onSecondary: Color(0xFF00243E),
    error: Color(0xFFEF5350),
    onError: Colors.black,
    background: Color(0xFF121212),
    onBackground: Color(0xFFE1E1E1),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE1E1E1),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      foregroundColor: Color(0xFFE1E1E1),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 28, // 全局规范：AppBar 标题统一 28 号
        fontWeight: FontWeight.bold,
        color: Color(0xFFE1E1E1),
      ),
    ),
    dividerTheme: DividerThemeData(color: Colors.grey.shade800),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48), // 触控目标 ≥48dp
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
