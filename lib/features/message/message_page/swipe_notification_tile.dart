/// 消息页支持左右滑动的通知条目（右滑删除、左滑标记已读）。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/net/api_exception.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../data/models/notification.dart';
import '../../notification/notification_controller.dart';
import 'notification_tile.dart';

/// 支持左右滑动的通知条目：右滑删除、左滑标记已读。
///
/// 删除为不可逆操作（后端按 id 物理删除），滑动超过阈值松手即提交；
/// 标记已读不移除条目，因此该方向确认后回弹、保留在列表中。
class MessageSwipeNotificationTile extends ConsumerWidget {
  const MessageSwipeNotificationTile({super.key, required this.item});

  /// 通知数据。
  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey<int>(item.id),
      direction: DismissDirection.horizontal,
      // 右滑（startToEnd）露出左侧背景 = 删除。
      background: const _MessageSwipeBackground(
        alignment: Alignment.centerLeft,
        color: Color(0xFFDC2626),
        icon: Icons.delete_outline,
        label: '删除',
      ),
      // 左滑（endToStart）露出右侧背景 = 标记已读。
      secondaryBackground: _MessageSwipeBackground(
        alignment: Alignment.centerRight,
        color: const Color(0xFF3B82F6),
        icon: Icons.check_circle_outline,
        label: item.read ? '已读' : '标记已读',
      ),
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 删除交由 onDismissed 统一提交，条目随列表状态自动移除。
          return true;
        }
        await _markRead(context, ref);
        return false;
      },
      onDismissed: (DismissDirection direction) =>
          unawaited(_delete(context, ref)),
      child: Material(
        color: context.surfaces.panel,
        child: MessageNotificationTile(item: item),
      ),
    );
  }

  /// 左滑：未读则标记已读。
  Future<void> _markRead(BuildContext context, WidgetRef ref) async {
    final NotificationController controller =
        ref.read(notificationControllerProvider.notifier);
    if (item.read) {
      _toast(context, '该通知已经是已读状态');
      return;
    }
    await controller.markRead(item.id);
    if (!context.mounted) {
      return;
    }
    _toast(context, '已标记为已读');
  }

  /// 右滑：调用接口删除通知。
  ///
  /// 失败时控制器已回滚本地列表，这里只负责给出提示。
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final NotificationController controller =
        ref.read(notificationControllerProvider.notifier);
    try {
      await controller.delete(item.id);
      if (!context.mounted) {
        return;
      }
      _toast(context, '通知已删除');
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      _toast(context, error.message.isEmpty ? '删除失败' : error.message);
    } on NetworkException catch (error) {
      if (!context.mounted) {
        return;
      }
      _toast(context, error.message);
    } on Exception {
      if (!context.mounted) {
        return;
      }
      _toast(context, '删除失败');
    }
  }

  /// 底部轻提示。
  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 滑动时露出的操作背景。
class _MessageSwipeBackground extends StatelessWidget {
  const _MessageSwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  /// 图标与文案的对齐方向：删除靠左、已读靠右。
  final Alignment alignment;

  /// 背景色。
  final Color color;

  /// 操作图标。
  final IconData icon;

  /// 操作文案。
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
