import 'dart:async';

import '../../../core/theme/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import '../update/auto_update_setting_controller.dart';

/// 我的 tab。
///
/// 展示账户信息并提供主题切换、退出登录等入口，退出交互搬迁自
/// 原控制台占位页（features/console/console_page.dart）。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserInfo? user =
        ref.watch(sessionControllerProvider).asData?.value?.user;
    final AppThemeMode themeMode = ref.watch(themeModeControllerProvider);
    final bool autoUpdate = ref.watch(autoUpdateSettingProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _ProfileHeader(user: user),
          const SizedBox(height: 16),
          _SwitchTile(
            icon: Icons.system_update_outlined,
            title: '自动更新',
            subtitle: '开启后进入 APP 时自动检查新版本',
            value: autoUpdate,
            onChanged: (bool value) =>
                ref.read(autoUpdateSettingProvider.notifier).setEnabled(value),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.confirmation_number_outlined,
            title: '工单',
            subtitle: '提交与跟踪',
            onTap: () => unawaited(
              Navigator.of(context).pushNamed(AppRoutes.ticketList),
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.key_outlined,
            title: 'AK 管理',
            subtitle: '访问密钥的创建与停用',
            onTap: () => unawaited(
              Navigator.of(context).pushNamed(AppRoutes.akManage),
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.history_outlined,
            title: '操作日志',
            subtitle: '账号下的操作审计记录',
            onTap: () => unawaited(
              Navigator.of(context).pushNamed(AppRoutes.actionLog),
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.brightness_6_outlined,
            title: '主题模式',
            subtitle: _themeName(themeMode),
            onTap: () => unawaited(
              Navigator.of(context).pushNamed(AppRoutes.themeMode),
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
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

/// 账户信息头部。
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.user});

  final UserInfo? user;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.flame500,
            child: Text(
              _initial(user),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user?.displayName ?? '未获取到用户信息',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(user),
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _balanceText(user),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.flame500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '账户余额',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _subtitle(UserInfo? user) {
    final String? uid = user?.uid;
    if (uid != null && uid.isNotEmpty) {
      return 'UID $uid';
    }
    final String? phone = user?.phone;
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }
    return '';
  }

  /// 余额展示文案，未加载到时展示占位符。
  String _balanceText(UserInfo? user) {
    final String? balance = user?.balance;
    if (balance != null && balance.isNotEmpty) {
      return '¥$balance';
    }
    return '--';
  }

  String _initial(UserInfo? user) {
    final String name = user?.displayName ?? '';
    return name.isEmpty ? '火' : name.characters.first.toUpperCase();
  }
}

/// 带开关的设置项。
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.flame500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// 操作项。
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: iconColor ?? AppColors.flame500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
