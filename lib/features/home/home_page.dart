import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';

/// 首页 tab。
///
/// 内容搬迁自原控制台占位页（features/console/console_page.dart），
/// 展示账户概览与常用入口，业务页面按 vue_flamecloud 逐个搬迁后在此补齐。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserInfo? user =
        ref.watch(sessionControllerProvider).asData?.value?.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _AccountCard(user: user),
            const SizedBox(height: 16),
            const _QuickEntries(),
            const SizedBox(height: 24),
            Text(
              '控制台业务页面正在从 vue_flamecloud 搬迁中',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 账户概览卡片，展示头像、昵称与余额。
class _AccountCard extends StatelessWidget {
  const _AccountCard({this.user});

  final UserInfo? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: AppColors.loginButtonGradient,
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.balance != null ? '账户余额 ¥${user!.balance}' : '余额加载中',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initial(UserInfo? user) {
    final String name = user?.displayName ?? '';
    return name.isEmpty ? '火' : name.characters.first.toUpperCase();
  }
}

/// 常用入口，点击后提示功能搬迁进度。
class _QuickEntries extends StatelessWidget {
  const _QuickEntries();

  static const List<_QuickEntry> _entries = <_QuickEntry>[
    _QuickEntry(icon: Icons.dns_outlined, label: '云服务器'),
    _QuickEntry(icon: Icons.hub_outlined, label: '云网络'),
    _QuickEntry(icon: Icons.storage_outlined, label: '云存储'),
    _QuickEntry(icon: Icons.confirmation_number_outlined, label: '工单'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: <Widget>[
        for (final _QuickEntry entry in _entries) ...<Widget>[
          Expanded(
            child: _EntryCard(entry: entry, isDark: isDark),
          ),
          if (entry != _entries.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.isDark});

  final _QuickEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.dark500 : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _comingSoon(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: <Widget>[
              Icon(entry.icon, color: AppColors.flame500, size: 24),
              const SizedBox(height: 8),
              Text(
                entry.label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('该页面正在搬迁中，敬请期待')),
      );
  }
}

/// 入口数据。
class _QuickEntry {
  const _QuickEntry({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
