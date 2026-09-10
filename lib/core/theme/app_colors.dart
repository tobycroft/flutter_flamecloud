import 'package:flutter/material.dart';

/// 品牌色板。
///
/// 与 vue_flamecloud/tailwind.config.js 中的 `flame` 色板保持一致。
class AppColors {
  const AppColors._();

  /// flame 50。
  static const flame50 = Color(0xFFFFF7ED);

  /// flame 100。
  static const flame100 = Color(0xFFFFEDD5);

  /// flame 200。
  static const flame200 = Color(0xFFFED7AA);

  /// flame 300。
  static const flame300 = Color(0xFFFDBA74);

  /// flame 400。
  static const flame400 = Color(0xFFFB923C);

  /// flame 500（品牌主色）。
  static const flame500 = Color(0xFFFF6B35);

  /// flame 600。
  static const flame600 = Color(0xFFEA580C);

  /// flame 700。
  static const flame700 = Color(0xFFC2410C);

  /// flame 800。
  static const flame800 = Color(0xFF9A3412);

  /// flame 900。
  static const flame900 = Color(0xFF7C2D12);

  /// 暗色系 50，与 tailwind `dark.50` 对应。
  static const dark50 = Color(0xFFF8FAFC);

  /// 暗色系 100。
  static const dark100 = Color(0xFFE2E8F0);

  /// 暗色系 200。
  static const dark200 = Color(0xFF1E293B);

  /// 暗色系 300。
  static const dark300 = Color(0xFF1A1F4E);

  /// 暗色系 400。
  static const dark400 = Color(0xFF151A3A);

  /// 暗色系 500。
  static const dark500 = Color(0xFF0F1333);

  /// 暗色系 600。
  static const dark600 = Color(0xFF0A0E27);

  /// 暗色系 700。
  static const dark700 = Color(0xFF080B1F);

  /// 暗色系 800。
  static const dark800 = Color(0xFF060818);

  /// 暗色系 900。
  static const dark900 = Color(0xFF040510);

  /// 深色模式页面底色：中性「非常深的灰」，与组件面的藏青色形成区分。
  static const scaffoldDark = Color(0xFF121212);

  /// OLED 模式组件面（卡片/弹层/底栏），VS Code 风格深灰。
  static const oledPanel = Color(0xFF1F1F1F);

  /// OLED 模式二级容器面（输入框/chip 内层）。
  static const oledInset = Color(0xFF262626);

  /// OLED 模式描边与分隔线。
  static const oledLine = Color(0xFF333333);

  /// Tailwind orange-50，登录页渐变末端。
  static const orange50 = Color(0xFFFFF7ED);

  /// Tailwind orange-500，主按钮渐变末端。
  static const orange500 = Color(0xFFF97316);

  /// 控制台内容区背景（Vue ConsoleLayout 使用 bg-[#f2f4f8]）。
  static const consoleBackground = Color(0xFFF2F4F8);

  /// 主按钮渐变，对应 Tailwind `bg-flame-gradient`。
  static const LinearGradient flameGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [flame500, Color(0xFFFF4444)],
  );

  /// 登录按钮渐变，对应 `from-flame-500 to-orange-500`。
  static const LinearGradient loginButtonGradient = LinearGradient(
    colors: [flame500, orange500],
  );

  /// 登录页浅色背景渐变，对应
  /// `from-flame-50 via-white to-orange-50`。
  static const LinearGradient loginBackgroundLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [flame50, Colors.white, orange50],
  );

  /// 登录页暗色背景渐变，对应 `dark:from-dark-700 dark:to-dark-600`。
  static const LinearGradient loginBackgroundDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [dark700, dark600],
  );
}
