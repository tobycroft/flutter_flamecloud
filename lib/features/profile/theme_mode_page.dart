import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_mode_controller.dart';
import 'theme_mode_page/theme_card.dart';
import 'theme_mode_page/theme_options.dart';

/// 主题模式设置页。
///
/// 「我的」页主题入口跳转过来的二级页面，逐项说明四种主题的区别，
/// 点击卡片直接切换并持久化。
class ThemeModePage extends ConsumerWidget {
  const ThemeModePage({super.key});

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
          for (final ThemeOption option in themeModeOptions) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ThemeModeCard(
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
