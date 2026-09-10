import 'dart:async';

import '../../../core/theme/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/notification.dart';
import '../notification/notification_controller.dart';
import '../support/support_chat_controller.dart';
import '../support/widgets/chat_bubble.dart';

/// 消息 tab。
///
/// 顶部为「在线客服」会话（点击进入客服聊天页），其下方直接内联展示
/// 「通知中心」列表，通知内容以列表形式呈现，无需跳转二级页面。
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
            _ConversationTile(
              online: chat.online,
              unread: chat.unread,
              loading: chat.loading,
              last: last,
            ),
            const SizedBox(height: 24),
            const _NotificationSection(),
          ],
        ),
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

/// 通知中心区块，位于在线客服下方，直接以列表展示通知内容。
class _NotificationSection extends ConsumerWidget {
  const _NotificationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationState state =
        ref.watch(notificationControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(unread: state.unread),
        const SizedBox(height: 12),
        if (state.loading && state.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.errorMessage != null && state.items.isEmpty)
          _StatusView(
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
          _NotificationCard(items: state.items),
      ],
    );
  }
}

/// 通知中心标题栏，含未读数量徽标。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.unread});

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
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.items});

  /// 通知项。
  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final bool isLast = index == items.length - 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _NotificationTile(item: items[index]),
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

/// 单条通知条目，内联展示标题与正文内容。
class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

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

/// 通知加载失败/空态视图，失败时提供重试入口。
class _StatusView extends StatelessWidget {
  const _StatusView({required this.message, required this.onRetry});

  /// 提示文案。
  final String message;

  /// 重试回调。
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: <Widget>[
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => unawaited(onRetry()),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
