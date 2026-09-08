import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../data/models/app_release.dart';
import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import '../update/update_controller.dart';
import '../update/widgets/update_dialog.dart';

/// 控制台占位页。
///
/// 本阶段仅验证「登录 -> 进入控制台 -> 退出登录」链路，
/// 后续按 vue_flamecloud/src/pages/console 逐个搬迁业务页面。
class ConsolePage extends ConsumerStatefulWidget {
  const ConsolePage({super.key});

  @override
  ConsumerState<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends ConsumerState<ConsolePage> {
  /// 避免热重建等场景重复发起检查。
  bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _updateCheckStarted) {
        return;
      }
      _updateCheckStarted = true;
      ref.read(updateControllerProvider.notifier).checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateCheckState>(updateControllerProvider,
        (UpdateCheckState? previous, UpdateCheckState next) {
      final AppRelease? release = next.asData?.value;
      if (release != null) {
        ref.read(updateControllerProvider.notifier).dismiss();
        showUpdateDialog(context, release);
      }
    });

    final UserInfo? user =
        ref.watch(sessionControllerProvider).asData?.value?.user;
    final ThemeMode themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('火焰云控制台'),
        actions: <Widget>[
          IconButton(
            tooltip: '切换主题',
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).toggle(),
            icon: Icon(_themeIcon(themeMode)),
          ),
          IconButton(
            tooltip: '退出登录',
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.flame500,
                child: Text(
                  _initial(user),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? '未获取到用户信息',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (user?.balance != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  '账户余额 ¥${user!.balance}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.flame500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 32),
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
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };

  String _initial(UserInfo? user) {
    final String name = user?.displayName ?? '';
    return name.isEmpty ? '火' : name.characters.first.toUpperCase();
  }

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
