import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_controller.dart';

/// 主题选项数据。
///
/// [mode] 对应的持久化模式；[title] 为设置项名称；
/// [summary] 一句话定位；[description] 为详细说明；
/// 预览色取该主题真实用到的 scaffold / surface / primary 三色，
/// 让用户在不切换的情况下直观看到差别。
class ThemeOption {
  const ThemeOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.summary,
    required this.description,
    required this.background,
    required this.surface,
    this.gradient,
  });

  /// 主题模式。
  final AppThemeMode mode;

  /// 图标。
  final IconData icon;

  /// 名称。
  final String title;

  /// 一句话概括。
  final String summary;

  /// 详细说明。
  final String description;

  /// 预览背景色。
  final Color background;

  /// 预览卡片色。
  final Color surface;

  /// 预览首格渐变，用于「跟随系统」表达两色并存。
  final Gradient? gradient;
}

/// 四种主题选项常量表。
const List<ThemeOption> themeModeOptions = <ThemeOption>[
  ThemeOption(
    mode: AppThemeMode.light,
    icon: Icons.light_mode_outlined,
    title: '浅色',
    summary: '始终浅色界面',
    description: '全程使用浅色主题，背景为品牌浅橙，卡片为纯白。'
        '适合白天或光线充足的环境，与 Web 控制台默认外观一致。',
    background: AppColors.flame50,
    surface: Colors.white,
  ),
  ThemeOption(
    mode: AppThemeMode.dark,
    icon: Icons.dark_mode_outlined,
    title: '深色',
    summary: '深灰底 + 深蓝黑组件',
    description: '页面底色为中性深灰，卡片、输入框等组件沿用深蓝黑色系，'
        '底色与组件有明显层次。夜间或暗光环境下更护眼，长时间操作不易疲劳。',
    background: AppColors.scaffoldDark,
    surface: AppColors.dark500,
  ),
  ThemeOption(
    mode: AppThemeMode.oled,
    icon: Icons.brightness_2_outlined,
    title: 'OLED 纯黑',
    summary: '纯黑底 + 深灰组件',
    description: '底色为纯黑，卡片与输入框改用 VS Code 风格的深灰，'
        'OLED 屏幕对应像素可直接熄灭，更省电且对比清晰。'
        '适合 OLED 屏幕设备或深夜使用。',
    background: Colors.black,
    surface: AppColors.oledPanel,
  ),
  ThemeOption(
    mode: AppThemeMode.system,
    icon: Icons.settings_brightness_outlined,
    title: '跟随系统',
    summary: '自动切换深浅色',
    description: '跟随手机系统的深浅色设置自动切换；系统开启深色时使用深色主题'
        '（深灰底 + 深蓝黑组件），不额外使用 OLED 纯黑。'
        '适合希望与系统外观保持一致的场景。',
    background: AppColors.flame50,
    surface: Colors.white,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[AppColors.flame50, AppColors.dark500],
    ),
  ),
];
