import 'dart:async';

import '../../../core/theme/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_controller.dart';

/// 主题选项数据。
///
/// [mode] 对应的持久化模式；[title] 为设置项名称；
/// [summary] 一句话定位；[description] 为详细说明；
/// 预览色取该主题真实用到的 scaffold / surface / primary 三色，
/// 让用户在不切换的情况下直观看到差别。
class _ThemeOption {
  const _ThemeOption({
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

/// 主题模式设置页。
///
/// 「我的」页主题入口跳转过来的二级页面，逐项说明四种主题的区别，
/// 点击卡片直接切换并持久化。
class ThemeModePage extends ConsumerWidget {
  const ThemeModePage({super.key});

  static const List<_ThemeOption> _options = <_ThemeOption>[
    _ThemeOption(
      mode: AppThemeMode.light,
      icon: Icons.light_mode_outlined,
      title: '浅色',
      summary: '始终浅色界面',
      description: '全程使用浅色主题，背景为品牌浅橙，卡片为纯白。'
          '适合白天或光线充足的环境，与 Web 控制台默认外观一致。',
      background: AppColors.flame50,
      surface: Colors.white,
    ),
    _ThemeOption(
      mode: AppThemeMode.dark,
      icon: Icons.dark_mode_outlined,
      title: '深色',
      summary: '深灰底 + 深蓝黑组件',
      description: '页面底色为中性深灰，卡片、输入框等组件沿用深蓝黑色系，'
          '底色与组件有明显层次。夜间或暗光环境下更护眼，长时间操作不易疲劳。',
      background: AppColors.scaffoldDark,
      surface: AppColors.dark500,
    ),
    _ThemeOption(
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
    _ThemeOption(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeMode current = ref.watch(themeModeControllerProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题模式'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Text(
            '选择 App 的外观主题，设置会保存在本机，下次启动自动生效。',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          for (final _ThemeOption option in _options) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ThemeCard(
                option: option,
                selected: current == option.mode,
                isDark: isDark,
                onTap: () => unawaited(
                  ref
                      .read(themeModeControllerProvider.notifier)
                      .setMode(option.mode),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 单个主题卡片：图标 + 名称 + 说明 + 配色预览。
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.option,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final _ThemeOption option;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color surface = context.surfaces.panel;
    final Color border = selected
        ? AppColors.flame500
        : (context.surfaces.line);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.flame500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      option.icon,
                      size: 18,
                      color: AppColors.flame500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          option.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.summary,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.flame500,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFFD1D5DB),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                option.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              _ThemePreview(option: option),
            ],
          ),
        ),
      ),
    );
  }
}

/// 配色预览：背景、卡片、主色三格，直观呈现该主题的实际用色。
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.option});

  final _ThemeOption option;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _PreviewChip(
          isDark: false,
          color: option.background,
          gradient: option.gradient,
        ),
        const SizedBox(width: 8),
        _PreviewChip(isDark: true, color: option.surface),
        const SizedBox(width: 8),
        const _PreviewChip(isDark: false, color: AppColors.flame500),
      ],
    );
  }
}

/// 单格预览色块。
class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.isDark,
    required this.color,
    this.gradient,
  });

  final bool isDark;
  final Color color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: context.surfaces.line),
        ),
      ),
    );
  }
}
