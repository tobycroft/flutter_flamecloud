import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ticket_list_controller.dart';

/// 底部分页条。
class TicketListPager extends ConsumerWidget {
  const TicketListPager({required this.state, super.key});

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
