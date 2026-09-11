import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 把后端返回的时间字符串格式化为「今天 HH:MM」或「YYYY-MM-DD HH:MM」。
///
/// 兼容 `2025-01-01 00:00:00` 与 ISO `2025-01-01T00:00:00` 两种形态，
/// 与 vue_flamecloud DashboardPage 的 formatDateTime 行为一致。
String formatLastLogin(String? raw) {
  if (raw == null || raw.isEmpty) {
    return '';
  }
  try {
    final String normalized = raw.replaceAll('T', ' ').trim();
    final String trimmed =
        normalized.length >= 19 ? normalized.substring(0, 19) : normalized;
    final DateTime? date = DateTime.tryParse(trimmed);
    if (date == null) {
      return raw;
    }
    final DateTime now = DateTime.now();
    final bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final String hh = date.hour.toString().padLeft(2, '0');
    final String mm = date.minute.toString().padLeft(2, '0');
    if (isToday) {
      return '今天 $hh:$mm';
    }
    final String mo = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mo-$d $hh:$mm';
  } catch (_) {
    return raw;
  }
}

/// 活动状态对应的（图标色，浅底背景色）。
(Color, Color) homeStatusColors(String type) {
  switch (type) {
    case 'success':
      const Color green = Color(0xFF16A34A);
      return (green, green.withValues(alpha: 0.1));
    case 'warning':
      const Color amber = Color(0xFFD97706);
      return (amber, amber.withValues(alpha: 0.1));
    default:
      return (AppColors.flame500, AppColors.flame500.withValues(alpha: 0.1));
  }
}

/// 活动状态对应的图标。
IconData homeStatusIcon(String type) {
  switch (type) {
    case 'success':
      return Icons.check_circle;
    case 'warning':
      return Icons.warning_amber_rounded;
    default:
      return Icons.info;
  }
}

/// 二级文字色（用于次要说明文字）。
Color homeSecondaryColor(bool isDark) =>
    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

/// 三级文字色（用于时间、日期等弱信息）。
Color homeTertiaryColor(bool isDark) =>
    isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);
