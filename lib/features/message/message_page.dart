import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message.dart';
import '../notification/notification_controller.dart';
import '../support/support_chat_controller.dart';
import 'message_page/conversation_tile.dart';
import 'message_page/notification_section.dart';

/// 消息 tab。
///
/// 顶部为「在线客服」会话（点击进入客服聊天页），其下方直接内联展示
/// 「通知中心」列表，通知内容以列表形式呈现，无需跳转二级页面。
///
/// 各板块实现拆分在 [message_page] 子目录中，本文件只负责组装与刷新逻辑。
class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  @override
  void initState() {
    super.initState();
    // 进入消息 tab 时拉取一次通知列表，置于在线客服下方直接展示。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(ref.read(notificationControllerProvider.notifier).load());
    });
  }

  Future<void> _refresh() async {
    await ref.read(notificationControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final SupportChatState chat = ref.watch(supportChatControllerProvider);
    final ChatMessage? last =
        chat.messages.isEmpty ? null : chat.messages.last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            MessageConversationTile(
              online: chat.online,
              unread: chat.unread,
              loading: chat.loading,
              last: last,
            ),
            const SizedBox(height: 24),
            const MessageNotificationSection(),
          ],
        ),
      ),
    );
  }
}
