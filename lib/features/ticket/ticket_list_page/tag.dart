import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 小标签：状态/类型/分类通用。
class TicketListTag extends StatelessWidget {
  const TicketListTag({
    required this.text,
    required this.color,
    this.filled = true,
    super.key,
  });

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
