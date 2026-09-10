import 'dart:async';

import '../../../core/theme/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ticket.dart';
import 'ticket_detail_controller.dart';
import 'ticket_meta.dart';

/// 工单详情页，搬迁自 vue_flamecloud/TicketDetailPage。
///
/// 展示主帖（含附件/链接/联系方式）、盖楼回复，支持追加回复、
/// 关闭/重启工单，以及聊天工单转标准工单；新回复由控制器轮询拉取。
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
    String category = 'ecs';
    String urgency = 'fault';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    '转为标准工单',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '补齐问题分类与紧急性后，该工单将按标准流程处理',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: '问题分类'),
                    items: <DropdownMenuItem<String>>[
                      for (final (String, String) item in TicketMeta.categories
                          .where((element) => element.$1 != 'chat'))
                        DropdownMenuItem<String>(
                          value: item.$1,
                          child: Text(item.$2),
                        ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setSheetState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: urgency,
                    decoration: const InputDecoration(labelText: '紧急性'),
                    items: <DropdownMenuItem<String>>[
                      for (final (String, String) item in TicketMeta.urgencies)
                        DropdownMenuItem<String>(
                          value: item.$1,
                          child: Text(item.$2),
                        ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setSheetState(() => urgency = value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            final String selectedCategory = category;
                            final String selectedUrgency = urgency;
                            try {
                              await ref
                                  .read(ticketDetailControllerProvider.notifier)
                                  .convert(
                                    category: selectedCategory,
                                    urgency: selectedUrgency,
                                  );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(content: Text('工单转换成功')),
                                );
                            } on Exception catch (error) {
                              _showError(error, '转换失败');
                            }
                          },
                          child: const Text('确认转换'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
            _ReplyBar(
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
      return _StatusView(
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
          _TicketInfoCard(
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
                child: _ReplyCard(reply: reply),
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

/// 主帖卡片：紧急性、分类、联系方式、正文与附件区。
class _TicketInfoCard extends StatelessWidget {
  const _TicketInfoCard({
    required this.info,
    required this.attachments,
    required this.links,
    required this.contacts,
  });

  final TicketInfo info;
  final List<TicketAttachment> attachments;
  final List<TicketLink> links;
  final List<TicketContact> contacts;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasExtras =
        attachments.isNotEmpty || links.isNotEmpty || contacts.isNotEmpty;

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  TicketMeta.urgencyText(info.urgency),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TicketMeta.urgencyColor(info.urgency),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TicketMeta.statusColor(info.status)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    TicketMeta.statusText(info.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TicketMeta.statusColor(info.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              info.description,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  Icons.label_outline,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  TicketMeta.categoryText(info.category),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  info.displayTime,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            if (info.contactPhone.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                '联系电话 ${info.contactPhone}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                ),
              ),
            ],
            if (hasExtras) ...<Widget>[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (attachments.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final TicketAttachment file in attachments)
                      _AttachmentChip(attachment: file),
                  ],
                ),
              if (links.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                for (final TicketLink link in links)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${link.text} ${link.url}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
              if (contacts.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                for (final TicketContact contact in contacts)
                  Row(
                    children: <Widget>[
                      Icon(
                        contact.isEmail
                            ? Icons.mail_outline
                            : Icons.phone_outlined,
                        size: 14,
                        color: const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contact.label.isEmpty ? contact.value : contact.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// 附件 chip：图片按名称判断，统一以文件名展示（暂不加载远程图）。
class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment});

  final TicketAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaces.inset,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: context.surfaces.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            attachment.isImage ? Icons.image_outlined : Icons.attach_file,
            size: 14,
            color: AppColors.flame500,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条回复：客服左侧橙色、自己蓝色，回复可带附件。
class _ReplyCard extends StatelessWidget {
  const _ReplyCard({required this.reply});

  final TicketReply reply;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent =
        reply.fromAdmin ? const Color(0xFFEA580C) : const Color(0xFF2563EB);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: BorderSide.none,
          right: BorderSide.none,
          bottom: BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person_outline, size: 16, color: accent),
                ),
                const SizedBox(width: 8),
                Text(
                  reply.fromAdmin ? '客服' : '我',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                if (reply.fromAdmin) ...<Widget>[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '官方',
                      style: TextStyle(fontSize: 10, color: accent),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  reply.displayTime,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            if (reply.content.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                reply.content,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
            if (reply.attachments.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final TicketAttachment file in reply.attachments)
                    _AttachmentChip(attachment: file),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 底部回复输入栏，工单关闭后替换为结案提示。
class _ReplyBar extends ConsumerWidget {
  const _ReplyBar({
    required this.state,
    required this.controller,
    required this.onSend,
  });

  final TicketDetailState state;
  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TicketInfo? info = state.info;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (info == null) {
      return const SizedBox.shrink();
    }
    if (info.closed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: context.surfaces.panel,
        child: Text(
          '工单已结案，如需继续沟通请重启工单或提交新工单',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        border: Border(
          top: BorderSide(
            color: context.surfaces.line,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '输入回复内容',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => unawaited(onSend()),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: state.sending ? null : () => unawaited(onSend()),
                child: state.sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('发送'),
              ),
            ),
          ],
        ),
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
