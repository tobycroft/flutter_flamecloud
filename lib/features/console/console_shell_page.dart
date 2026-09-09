import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_release.dart';
import '../home/home_page.dart';
import '../message/message_page.dart';
import '../profile/profile_page.dart';
import '../service/service_page.dart';
import '../support/support_chat_controller.dart';
import '../update/update_controller.dart';
import '../update/widgets/update_dialog.dart';

/// 控制台外壳页。
///
/// 登录后进入的宿主页面：底部四个 tab（首页/服务/消息/我的）用 IndexedStack
/// 承载以保持各自滚动位置与状态；同时接管原 ConsolePage 的版本检查，
/// 并在进入时启动客服消息轮询，用于「消息」tab 的未读红标。
class ConsoleShellPage extends ConsumerStatefulWidget {
  const ConsoleShellPage({super.key});

  @override
  ConsumerState<ConsoleShellPage> createState() => _ConsoleShellPageState();
}

class _ConsoleShellPageState extends ConsumerState<ConsoleShellPage> {
  /// 当前选中的 tab。
  int _currentIndex = 0;

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
      // 客服消息常驻轮询，底栏「消息」红标依赖它。
      unawaited(ref.read(supportChatControllerProvider.notifier).start());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateCheckState>(
      updateControllerProvider,
      (UpdateCheckState? previous, UpdateCheckState next) {
        final AppRelease? release = next.asData?.value;
        if (release != null) {
          ref.read(updateControllerProvider.notifier).dismiss();
          showUpdateDialog(context, release);
        }
      },
    );

    final bool hasUnread = ref.watch(supportChatControllerProvider).unread;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[
          HomePage(),
          ServicePage(),
          MessagePage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: '服务',
          ),
          BottomNavigationBarItem(
            icon: _MessageIcon(active: false, unread: hasUnread),
            activeIcon: _MessageIcon(active: true, unread: hasUnread),
            label: '消息',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

/// 「消息」tab 图标，有未读客服消息时右上角显示红点。
class _MessageIcon extends StatelessWidget {
  const _MessageIcon({required this.active, required this.unread});

  /// 是否选中态。
  final bool active;

  /// 是否存在未读消息。
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: unread,
      smallSize: 8,
      backgroundColor: const Color(0xFFDC2626),
      child: Icon(active ? Icons.chat_bubble : Icons.chat_bubble_outline),
    );
  }
}
