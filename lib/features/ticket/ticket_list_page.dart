import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ticket.dart';
import 'ticket_list_controller.dart';
import 'ticket_list_page/pager.dart';
import 'ticket_list_page/stat_card.dart';
import 'ticket_list_page/status_filter_bar.dart';
import 'ticket_list_page/status_view.dart';
import 'ticket_list_page/ticket_card.dart';

/// 工单列表页，搬迁自 vue_flamecloud/TicketListPage。
///
/// 顶部两个统计卡来自后端聚合计数（`processing` / `confirm`），
/// 其下为状态筛选 chips 与分页列表；AppBar 右上角进入提交页。
///
/// 各板块实现拆分在 [ticket_list_page] 子目录中，本文件只保留
/// 控制器调用、导航、弹窗触发方法与列表组装。
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

  Future<void> _closeTicket(TicketItem ticket) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('关闭工单'),
        content: Text('确定要结案关闭工单 #${ticket.id} 吗？关闭后可重新开启。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(ticketListControllerProvider.notifier).close(ticket);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('工单已关闭')));
    } on Exception catch (error) {
      _showError(error, '关闭失败');
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
      return TicketListStatusView(
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
                child: TicketListStatCard(
                  label: '服务中',
                  value: state.processing,
                  color: AppColors.flame500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TicketListStatCard(
                  label: '待您确认结果',
                  value: state.confirm,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TicketListStatusFilterBar(state: state),
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
                child: TicketListCard(
                  ticket: item,
                  onTap: () => unawaited(_openDetail(item.id)),
                  onClose: () => unawaited(_closeTicket(item)),
                  onReopen: () => unawaited(_reopen(item)),
                ),
              ),
            TicketListPager(state: state),
          ],
        ],
      ),
    );
  }
}
