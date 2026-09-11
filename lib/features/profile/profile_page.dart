import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import '../update/auto_update_setting_controller.dart';
import 'profile_page/action_tile.dart';
import 'profile_page/profile_header.dart';
import 'profile_page/switch_tile.dart';

/// 我的 tab。
///
/// 展示账户信息并提供主题切换、退出登录等入口，退出交互搬迁自
/// 原控制台占位页（features/console/console_page.dart）。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserInfo? user = ref
        .watch(sessionControllerProvider)
        .asData
        ?.value
        ?.user;
    final AppThemeMode themeMode = ref.watch(themeModeControllerProvider);
    final bool autoUpdate = ref.watch(autoUpdateSettingProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ProfileHeader(
            user: user,
            onTap: () => unawaited(
              Navigator.of(context).pushNamed(AppRoutes.fundManage),
            ),
          ),
          const SizedBox(height: 16),
          ProfileSwitchTile(
            icon: Icons.system_update_outlined,
            title: '自动更新',
            subtitle: '开启后进入 APP 时自动检查新版本',
            value: autoUpdate,
            onChanged: (bool value) =>
                ref.read(autoUpdateSettingProvider.notifier).setEnabled(value),
          ),
          const SizedBox(height: 12),
          ProfileActionTile(
            icon: Icons.account_balance_wallet_outlined,
            title: '资金管理',
            subtitle: '余额、充值订单与流水',
            onTap: () => unawaited(
              Navigator.of(context).pushNamed(AppRoutes.fundManage),
            ),
          ),
          const SizedBox(height: 12),
          ProfileActionTile(
            icon: Icons.confirmation_number_outlined,
            title: '工单',
            subtitle: '提交与跟踪',
            onTap: () => unawaited(
              Navigator.of(context).pushNamed(AppRoutes.ticketList),
            ),
          ),
          const SizedBox(height: 12),
          ProfileActionTile(
            icon: Icons.key_outlined,
            title: 'AK 管理',
            subtitle: '访问密钥的创建与停用',
            onTap: () =>
                unawaited(Navigator.of(context).pushNamed(AppRoutes.akManage)),
          ),
          const SizedBox(height: 12),
          ProfileActionTile(
            icon: Icons.history_outlined,
            title: '操作日志',
            subtitle: '账号下的操作审计记录',
            onTap: () =>
                unawaited(Navigator.of(context).pushNamed(AppRoutes.actionLog)),
          ),
          const SizedBox(height: 12),
          ProfileActionTile(
            icon: Icons.brightness_6_outlined,
            title: '主题模式',
            subtitle: _themeName(themeMode),
            onTap: () =>
                unawaited(Navigator.of(context).pushNamed(AppRoutes.themeMode)),
          ),
          const SizedBox(height: 12),
          ProfileActionTile(
            icon: Icons.logout_outlined,
            title: '退出登录',
            iconColor: const Color(0xFFDC2626),
            titleColor: const Color(0xFFDC2626),
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 24),
          Text(
            '火焰云 · 控制台业务搬迁中',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  String _themeName(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => '浅色',
    AppThemeMode.dark => '深色',
    AppThemeMode.oled => 'OLED',
    AppThemeMode.system => '跟随系统',
  };

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }
    await ref.read(sessionControllerProvider.notifier).logout();
  }
}
