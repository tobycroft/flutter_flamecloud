/// 客服聊天页顶部错误提示条。
library;

import 'package:flutter/material.dart';

/// 顶部错误提示条。
class SupportChatErrorBanner extends StatelessWidget {
  const SupportChatErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
      ),
    );
  }
}
