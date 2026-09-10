import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import 'support_chat_controller.dart';
import 'support_chat_page/error_banner.dart';
import 'support_chat_page/input_bar.dart';
import 'support_chat_page/message_list.dart';
import 'support_chat_page/title.dart';

/// 在线客服聊天页。
///
/// 搬迁自 vue_flamecloud/src/pages/console/UserCenter/ChatPage.vue：
/// 进入时拉取历史消息，消息按自己/客服左右分列，底部输入发送，
/// 新消息到达后自动滚动到底部。
///
/// 各板块实现拆分在 [support_chat_page] 子目录中，本文件只负责组装与
/// 发送、滚动等页面级逻辑。
class SupportChatPage extends ConsumerStatefulWidget {
  const SupportChatPage({super.key});

  @override
  ConsumerState<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends ConsumerState<SupportChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(supportChatControllerProvider.notifier).enterChat());
    });
  }

  @override
  void dispose() {
    ref.read(supportChatControllerProvider.notifier).leaveChat();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SupportChatState state = ref.watch(supportChatControllerProvider);
    final UserInfo? user =
        ref.watch(sessionControllerProvider).asData?.value?.user;

    // 消息数量变化时滚到底部，与 Vue 端 scrollToBottom 行为一致。
    ref.listen<SupportChatState>(
      supportChatControllerProvider,
      (SupportChatState? previous, SupportChatState next) {
        if (previous?.messages.length != next.messages.length) {
          _scrollToBottom();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: SupportChatTitle(online: state.online),
      ),
      body: Column(
        children: <Widget>[
          if (state.errorMessage != null)
            SupportChatErrorBanner(message: state.errorMessage!),
          Expanded(
            child: SupportChatMessageList(
              state: state,
              controller: _scrollController,
              selfName: _selfName(user),
            ),
          ),
          SupportChatInputBar(
            controller: _inputController,
            sending: state.sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  /// 自己的展示名，与 Vue 端 `userName || '我'` 一致。
  String _selfName(UserInfo? user) {
    final String name = user?.displayName ?? '';
    return name.isEmpty ? '我' : name;
  }

  Future<void> _send() async {
    final String text = _inputController.text;
    if (text.trim().isEmpty) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final bool sent =
        await ref.read(supportChatControllerProvider.notifier).send(text);
    if (!mounted || !sent) {
      return;
    }
    _inputController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }
}
