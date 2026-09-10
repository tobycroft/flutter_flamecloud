import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket.dart';
import '../ticket_meta.dart';
import 'tag.dart';

/// 单个工单卡片：描述、类型、分类、状态与时间。
///
/// 操作入口不再放三个点，改为长按卡片弹出上下文菜单（菜单锚定在卡片右上角）。
class TicketListCard extends StatelessWidget {
  const TicketListCard({
    required this.ticket,
    required this.onTap,
    required this.onClose,
    required this.onReopen,
    super.key,
  });

  final TicketItem ticket;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final VoidCallback onReopen;

  /// 长按弹出操作菜单，选中后回调对应动作。
  Future<void> _showContextMenu(BuildContext context) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null || !box.attached || !overlay.attached) {
      return;
    }
    // 锚点取卡片右上角，位置与原三个点菜单一致。
    final Offset anchor =
        box.localToGlobal(Offset(box.size.width, 0)) + const Offset(-8, 8);
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(anchor, anchor),
      Offset.zero & overlay.size,
    );

    final bool closed = ticket.status == 3;
    final String? action = await showMenu<String>(
      context: context,
      position: position,
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'detail',
          child: Text('查看详情'),
        ),
        if (closed)
          const PopupMenuItem<String>(
            value: 'reopen',
            child: Text('重启工单'),
          )
        else
          const PopupMenuItem<String>(
            value: 'close',
            child: Text('关闭工单'),
          ),
      ],
    );
    if (action == null) {
      return;
    }
    switch (action) {
      case 'detail':
        onTap();
      case 'close':
        onClose();
      case 'reopen':
        onReopen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        onLongPress: () => unawaited(_showContextMenu(context)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '#${ticket.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TicketListTag(
                    text: TicketMeta.typeText(ticket.ticketType),
                    color: TicketMeta.typeColor(ticket.ticketType),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  TicketListTag(
                    text: TicketMeta.categoryText(ticket.category),
                    color: const Color(0xFF6B7280),
                    filled: false,
                  ),
                  const SizedBox(width: 8),
                  TicketListTag(
                    text: TicketMeta.statusText(ticket.status),
                    color: TicketMeta.statusColor(ticket.status),
                  ),
                  const Spacer(),
                  Text(
                    ticket.displayTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
