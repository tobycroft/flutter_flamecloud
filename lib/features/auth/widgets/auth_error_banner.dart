import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 登录表单顶部错误告警条。
///
/// 对齐 Vue 登录页 `bg-red-50 border-red-200 text-red-600`。
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  /// 错误文案。
  final String message;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFDC2626).withValues(alpha: 0.1)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isDark
              ? const Color(0xFFDC2626).withValues(alpha: 0.3)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            size: 20,
            color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
