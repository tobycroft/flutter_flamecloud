/// 消息页通知中心区块（标题栏 + 列表卡片 + 加载/空态）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/notification.dart';
import '../../notification/notification_controller.dart';
import 'status_view.dart';
import 'swipe_notification_tile.dart';

/// 通知中心区块，位于在线客服下方，直接以列表展示通知内容。
class MessageNotificationSection extends ConsumerWidget {
  const MessageNotificationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationState state =
        ref.watch(notificationControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _MessageSectionHeader(unread: state.unread),
        const SizedBox(height: 12),
        if (state.loading && state.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.errorMessage != null && state.items.isEmpty)
          MessageStatusView(
            message: state.errorMessage!,
            onRetry: () =>
                ref.read(notificationControllerProvider.notifier).refresh(),
          )
        else if (state.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '暂无通知',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ),
          )
        else
          _MessageNotificationCard(items: state.items),
      ],
    );
  }
}

/// 通知中心标题栏，含未读数量徽标。
class _MessageSectionHeader extends StatelessWidget {
  const _MessageSectionHeader({required this.unread});

  /// 未读数，大于 0 时展示红色徽标。
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Text(
          '通知中心',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        if (unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              unread > 99 ? '99+' : '$unread',
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

/// 通知列表卡片，内部以不可滚动列表平铺，由外层 ListView 统一滚动。
class _MessageNotificationCard extends StatelessWidget {
  const _MessageNotificationCard({required this.items});

  /// 通知项。
  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      // 滑动背景在卡片圆角内绘制，避免左右滑时露出直角背景。
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final bool isLast = index == items.length - 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MessageSwipeNotificationTile(item: items[index]),
              if (!isLast)
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF1F5F9),
                ),
            ],
          );
        },
      ),
    );
  }
}
