/// 操作日志页底部分页条。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../action_log_controller.dart';

/// 底部分页条，展示「第 X / Y 页 (共 N 条)」。
class ActionLogPager extends ConsumerWidget {
  const ActionLogPager({super.key, required this.state});

  final ActionLogState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton(
            onPressed: state.loading || state.page <= 1
                ? null
                : () => unawaited(
                      ref
                          .read(actionLogControllerProvider.notifier)
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
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: state.loading || state.page >= state.totalPages
                ? null
                : () => unawaited(
                      ref
                          .read(actionLogControllerProvider.notifier)
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
