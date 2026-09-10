import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../data/models/ticket.dart';
import '../ticket_detail_controller.dart';

/// 底部回复输入栏，工单关闭后替换为结案提示。
class TicketDetailReplyBar extends ConsumerWidget {
  const TicketDetailReplyBar({
    required this.state,
    required this.controller,
    required this.onSend,
    super.key,
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
            FilledButton(
              onPressed: state.sending ? null : () => unawaited(onSend()),
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 48),
                maximumSize: const Size.fromHeight(48),
              ),
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
          ],
        ),
      ),
    );
  }
}
