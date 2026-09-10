/// 消息页单条通知条目。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/notification.dart';
import '../../support/widgets/chat_bubble.dart';
import '../../notification/notification_controller.dart';

/// 单条通知条目，内联展示标题与正文内容。
class MessageNotificationTile extends ConsumerWidget {
  const MessageNotificationTile({super.key, required this.item});

  /// 通知数据。
  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final IconData icon = _typeIcon(item.type);
    final Color color = _typeColor(item.type);

    return InkWell(
      onTap: () => unawaited(_handleTap(context, ref)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (item.read)
              const SizedBox(width: 16)
            else
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDC2626),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(right: 12, top: 2),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatChatTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  if (item.content != null && item.content!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.content!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 点击通知：未读先标记已读；标题/正文带 `#工单号` 时跳转工单详情，
  /// 返回后刷新列表（可能已在详情里回复或关闭工单）。
  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    if (!item.read) {
      unawaited(
        ref.read(notificationControllerProvider.notifier).markRead(item.id),
      );
    }
    final int? ticketId = item.relatedTicketId;
    if (ticketId == null) {
      return;
    }
    await Navigator.of(context).pushNamed(
      AppRoutes.ticketDetail,
      arguments: ticketId,
    );
    // 从详情返回后刷新列表，同步已读状态与最新通知。
    unawaited(ref.read(notificationControllerProvider.notifier).refresh());
  }

  /// 类型对应图标：info / success / warning / system。
  static IconData _typeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'system':
        return Icons.notifications_outlined;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  /// 类型对应主题色。
  static Color _typeColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF22C55E);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'system':
        return const Color(0xFFEA580C);
      case 'info':
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
