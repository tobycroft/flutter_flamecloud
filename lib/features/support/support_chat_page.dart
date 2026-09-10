import 'dart:async';

import '../../../core/theme/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import 'support_chat_controller.dart';
import 'widgets/chat_bubble.dart';

/// 在线客服聊天页。
///
/// 搬迁自 vue_flamecloud/src/pages/console/UserCenter/ChatPage.vue：
/// 进入时拉取历史消息，消息按自己/客服左右分列，底部输入发送，
/// 新消息到达后自动滚动到底部。
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
        title: _Title(online: state.online),
      ),
      body: Column(
        children: <Widget>[
          if (state.errorMessage != null)
            _ErrorBanner(message: state.errorMessage!),
          Expanded(
            child: _MessageList(
              state: state,
              controller: _scrollController,
              selfName: _selfName(user),
            ),
          ),
          _InputBar(
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

/// 标题区，展示客服在线状态。
class _Title extends StatelessWidget {
  const _Title({required this.online});

  /// 客服是否在线。
  final bool online;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          '在线客服',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online
                    ? const Color(0xFF22C55E)
                    : (isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              online ? '客服在线' : '客服离线',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 消息列表区。
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.state,
    required this.controller,
    required this.selfName,
  });

  final SupportChatState state;
  final ScrollController controller;
  final String selfName;

  @override
  Widget build(BuildContext context) {
    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          state.loading ? '加载中...' : '暂无消息，请描述您遇到的问题',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: state.messages.length,
      itemBuilder: (BuildContext context, int index) {
        return ChatBubble(
          message: state.messages[index],
          selfName: selfName,
        );
      },
    );
  }
}

/// 底部输入区。
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        border: Border(
          top: BorderSide(
            color: context.surfaces.line,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: !sending,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => unawaited(onSend()),
                decoration: const InputDecoration(
                  hintText: '输入您的问题...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 40,
              child: FilledButton(
                onPressed: sending ? null : () => unawaited(onSend()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 顶部错误提示条。
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
      ),
    );
  }
}
