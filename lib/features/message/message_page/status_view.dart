/// 消息页通知加载失败/空态视图。
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// 通知加载失败/空态视图，失败时提供重试入口。
class MessageStatusView extends StatelessWidget {
  const MessageStatusView({super.key, required this.message, required this.onRetry});

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
