/// 消息页「在线客服」会话条目。
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/chat_message.dart';
import '../../support/widgets/chat_bubble.dart';

/// 在线客服会话条目。
class MessageConversationTile extends StatelessWidget {
  const MessageConversationTile({super.key, required this.online,
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
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () =>
            unawaited(Navigator.of(context).pushNamed(AppRoutes.supportChat)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              // 不使用框架 Badge：避免 `!semantics.parentDataDirty` 断言导致整页空白。
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
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
                  if (unread)
                    const Positioned(
                      top: -2,
                      right: -2,
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
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
