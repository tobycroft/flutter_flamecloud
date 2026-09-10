import 'dart:async';

import '../../../core/theme/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket.dart';
import 'ticket_list_controller.dart';
import 'ticket_meta.dart';

/// 工单列表页，搬迁自 vue_flamecloud/TicketListPage。
///
/// 顶部两个统计卡来自后端聚合计数（`processing` / `confirm`），
/// 其下为状态筛选 chips 与分页列表；AppBar 右上角进入提交页。
class TicketListPage extends ConsumerStatefulWidget {
  const TicketListPage({super.key});

  @override
  ConsumerState<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends ConsumerState<TicketListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(ticketListControllerProvider.notifier).load());
      }
    });
  }

  /// 跳转提交页，提交成功后刷新列表。
  Future<void> _openSubmit() async {
    final Object? result =
        await Navigator.of(context).pushNamed(AppRoutes.ticketSubmit);
    if (result == true && mounted) {
      unawaited(ref.read(ticketListControllerProvider.notifier).refresh());
    }
  }

  /// 跳转详情，返回后刷新列表（可能在详情里回复/关闭/重启）。
  Future<void> _openDetail(int id) async {
    final Object? result =
        await Navigator.of(context).pushNamed(AppRoutes.ticketDetail, arguments: id);
    if (result == true && mounted) {
      unawaited(ref.read(ticketListControllerProvider.notifier).refresh());
    }
  }

  /// 统一错误提示，优先展示后端 echo 转成的异常文案。
  void _showError(Object error, String fallback) {
    String message = fallback;
    if (error is ApiException && error.message.isNotEmpty) {
      message = error.message;
    } else if (error is NetworkException) {
      message = error.message;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteTicket(TicketItem ticket) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('删除工单'),
        content: Text('确定删除工单 #${ticket.id} 吗？删除后不可恢复。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              '删除',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(ticketListControllerProvider.notifier)
          .deleteTicket(ticket);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('工单已删除')));
    } on Exception catch (error) {
      _showError(error, '删除失败');
    }
  }

  Future<void> _reopen(TicketItem ticket) async {
    try {
      await ref.read(ticketListControllerProvider.notifier).reopen(ticket);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('工单已重启')));
    } on Exception catch (error) {
      _showError(error, '只有已关闭的工单才能重启');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TicketListState state = ref.watch(ticketListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的工单'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '提交工单',
            onPressed: () => unawaited(_openSubmit()),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(TicketListState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _StatusView(
        message: state.errorMessage!,
        onRetry: () => ref.read(ticketListControllerProvider.notifier).refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ticketListControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  label: '服务中',
                  value: state.processing,
                  color: AppColors.flame500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '待您确认结果',
                  value: state.confirm,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatusFilterBar(state: state),
          const SizedBox(height: 12),
          if (state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  '暂无工单',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else ...<Widget>[
            for (final TicketItem item in state.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TicketCard(
                  ticket: item,
                  onTap: () => unawaited(_openDetail(item.id)),
                  onDelete: () => unawaited(_deleteTicket(item)),
                  onReopen: () => unawaited(_reopen(item)),
                ),
              ),
            _Pager(state: state),
          ],
        ],
      ),
    );
  }
}

/// 统计卡：后端聚合计数。
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// 状态筛选条：全部 + 四种状态。
class _StatusFilterBar extends ConsumerWidget {
  const _StatusFilterBar({required this.state});

  final TicketListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _FilterChip(
            label: '全部',
            selected: state.statusFilter == null,
            onTap: () => unawaited(
              ref.read(ticketListControllerProvider.notifier).selectStatus(null),
            ),
          ),
          for (final int status in const <int>[0, 1, 2, 3])
            _FilterChip(
              label: TicketMeta.statusText(status),
              selected: state.statusFilter == status,
              onTap: () => unawaited(
                ref
                    .read(ticketListControllerProvider.notifier)
                    .selectStatus(status),
              ),
            ),
        ],
      ),
    );
  }
}

/// 筛选 chip。
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? primary
                : (context.surfaces.inset),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? primary
                  : (isDark
                      ? const Color(0xFF1A1F4E)
                      : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF4B5563)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个工单卡片：描述、类型、分类、状态与时间。
///
/// 操作入口不再放三个点，改为长按卡片弹出上下文菜单（菜单锚定在卡片右上角）。
class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.onTap,
    required this.onDelete,
    required this.onReopen,
  });

  final TicketItem ticket;
  final VoidCallback onTap;
  final VoidCallback onDelete;
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
          ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            '删除工单',
            style: TextStyle(color: Color(0xFFDC2626)),
          ),
        ),
      ],
    );
    if (action == null) {
      return;
    }
    switch (action) {
      case 'detail':
        onTap();
      case 'reopen':
        onReopen();
      case 'delete':
        onDelete();
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
                  _Tag(
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
                  _Tag(
                    text: TicketMeta.categoryText(ticket.category),
                    color: const Color(0xFF6B7280),
                    filled: false,
                  ),
                  const SizedBox(width: 8),
                  _Tag(
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

/// 小标签：状态/类型/分类通用。
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color, this.filled = true});

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: filled
            ? null
            : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// 底部分页条。
class _Pager extends ConsumerWidget {
  const _Pager({required this.state});

  final TicketListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton(
            onPressed: state.loading || state.page <= 1
                ? null
                : () => unawaited(
                      ref
                          .read(ticketListControllerProvider.notifier)
                          .goPage(state.page - 1),
                    ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('上一页'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '第 ${state.page} / ${state.totalPages} 页 (共 ${state.total} 条)',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          OutlinedButton(
            onPressed: state.loading || state.page >= state.totalPages
                ? null
                : () => unawaited(
                      ref
                          .read(ticketListControllerProvider.notifier)
                          .goPage(state.page + 1),
                    ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('下一页'),
          ),
        ],
      ),
    );
  }
}

/// 加载失败视图。
class _StatusView extends StatelessWidget {
  const _StatusView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
