import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_message.dart';
import '../support/support_chat_controller.dart';
import '../support/widgets/chat_bubble.dart';

/// 消息 tab。
///
/// 会话列表页，当前仅有「在线客服」一个会话，点击进入客服聊天页；
/// 有未读客服消息时展示红标，数据与轮询由 SupportChatController 提供。
class MessagePage extends ConsumerWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SupportChatState chat = ref.watch(supportChatControllerProvider);
    final ChatMessage? last =
        chat.messages.isEmpty ? null : chat.messages.last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _ConversationTile(
            online: chat.online,
            unread: chat.unread,
            loading: chat.loading,
            last: last,
          ),
        ],
      ),
    );
  }
}

/// 在线客服会话条目。
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.online,
    required this.unread,
    required this.loading,
    this.last,
  });

  /// 客服是否在线。
  final bool online;

  /// 是否有未读消息。
  final bool unread;

  /// 是否正在加载。
  final bool loading;

  /// 最后一条消息。
  final ChatMessage? last;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.dark500 : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => unawaited(Navigator.of(context).pushNamed(AppRoutes.supportChat)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Badge(
                isLabelVisible: unread,
                smallSize: 10,
                backgroundColor: const Color(0xFFDC2626),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.headphones,
                    color: Color(0xFFEA580C),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Text(
                          '在线客服',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: online
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                        const Spacer(),
                        if (last != null)
                          Text(
                            formatChatTime(last!.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _summary(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 列表副标题：优先最后一条消息，无消息时展示在线状态。
  String _summary() {
    final ChatMessage? message = last;
    if (message != null) {
      final String prefix = message.fromAdmin ? '' : '我：';
      return '$prefix${message.content}';
    }
    if (loading) {
      return '加载中...';
    }
    return online ? '您好，请描述您遇到的问题' : '客服当前离线，请留言';
  }
}
