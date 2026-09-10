/// 客服聊天页消息列表区。
library;

import 'package:flutter/material.dart';

import '../support_chat_controller.dart';
import '../widgets/chat_bubble.dart';

/// 消息列表区。
class SupportChatMessageList extends StatelessWidget {
  const SupportChatMessageList({
    super.key,
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
