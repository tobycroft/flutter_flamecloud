/// 客服聊天页标题区。
library;

import 'package:flutter/material.dart';

/// 标题区，展示客服在线状态。
class SupportChatTitle extends StatelessWidget {
  const SupportChatTitle({super.key, required this.online});

  /// 客服是否在线。
  final bool online;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          '在线客服',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online
                    ? const Color(0xFF22C55E)
                    : (isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              online ? '客服在线' : '客服离线',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
