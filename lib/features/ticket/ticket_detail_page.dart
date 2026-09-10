import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/ticket.dart';
import 'ticket_detail_controller.dart';
import 'ticket_detail_page/info_card.dart';
import 'ticket_detail_page/reply_bar.dart';
import 'ticket_detail_page/reply_card.dart';
import 'ticket_detail_page/reply_sheet.dart';
import 'ticket_detail_page/status_view.dart';

/// 工单详情页，搬迁自 vue_flamecloud/TicketDetailPage。
///
/// 展示主帖（含附件/链接/联系方式）、盖楼回复，支持追加回复、
/// 关闭/重启工单，以及聊天工单转标准工单；新回复由控制器轮询拉取。
///
/// 各板块实现拆分在 [ticket_detail_page] 子目录中，本文件只保留
/// State 字段、控制器调用、导航与弹窗触发方法。
class TicketDetailPage extends ConsumerStatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  /// 工单 id，由路由参数传入。
  final int ticketId;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref
              .read(ticketDetailControllerProvider.notifier)
              .open(widget.ticketId),
        );
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final String content = _replyController.text.trim();
    if (content.isEmpty) {
      return;
    }
    try {
      await ref
          .read(ticketDetailControllerProvider.notifier)
          .sendReply(content);
      if (!mounted) {
        return;
      }
      _replyController.clear();
    } on Exception catch (error) {
      _showError(error, '回复发送失败');
    }
  }

  Future<void> _close() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('关闭工单'),
        content: const Text('确定要结案关闭该工单吗？关闭后可重新开启。'),
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
      await ref.read(ticketDetailControllerProvider.notifier).close();
    } on Exception catch (error) {
      _showError(error, '关闭失败');
    }
  }

  Future<void> _reopen() async {
    try {
      await ref.read(ticketDetailControllerProvider.notifier).reopen();
    } on Exception catch (error) {
      _showError(error, '只有已关闭的工单才能重启');
    }
  }

  /// 聊天工单转标准工单弹窗：补齐分类与紧急性。
  Future<void> _convert() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return TicketDetailConvertSheet(
          onError: (Object error) => _showError(error, '转换失败'),
        );
      },
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final TicketDetailState state = ref.watch(ticketDetailControllerProvider);
    final TicketInfo? info = state.info;

    return Scaffold(
      appBar: AppBar(
        title: Text('工单 ${info == null ? '' : '#${info.id}'}'),
        actions: <Widget>[
          if (info != null && info.ticketType == 'chat')
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: '转为标准工单',
              onPressed: () => unawaited(_convert()),
            ),
          if (info != null && info.closed)
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: '重启工单',
              onPressed: () => unawaited(_reopen()),
            )
          else if (info != null)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: '关闭工单',
              onPressed: () => unawaited(_close()),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: _buildBody(state)),
          if (info != null)
            TicketDetailReplyBar(
              state: state,
              controller: _replyController,
              onSend: _sendReply,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(TicketDetailState state) {
    if (state.loading && state.info == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.info == null) {
      return TicketDetailStatusView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(ticketDetailControllerProvider.notifier).refresh(),
      );
    }
    final TicketInfo? info = state.info;
    if (info == null) {
      return const Center(
        child: Text(
          '工单不存在',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ticketDetailControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TicketDetailInfoCard(
            info: info,
            attachments: state.attachments,
            links: state.links,
            contacts: state.contacts,
          ),
          const SizedBox(height: 16),
          if (state.replies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '暂无回复',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else ...<Widget>[
            for (final TicketReply reply in state.replies)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TicketDetailReplyCard(reply: reply),
              ),
          ],
          if (info.closed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.highlight_off,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '该工单已结案关闭',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
