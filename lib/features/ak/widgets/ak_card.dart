import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/access_key.dart';

/// 单个 AK 卡片，搬迁自 vue_flamecloud/AkTable 的移动端适配。
///
/// 展示名称、密钥（等宽字体可复制）、状态徽标、创建时间与操作行
/// （禁用/启用、权限、日志、删除）。
class AkCard extends StatelessWidget {
  const AkCard({
    super.key,
    required this.ak,
    required this.onToggle,
    required this.onPermission,
    required this.onLogs,
    required this.onDelete,
  });

  /// AK 数据。
  final AccessKeyItem ak;

  /// 启用/禁用回调。
  final VoidCallback onToggle;

  /// 权限配置回调。
  final VoidCallback onPermission;

  /// 查看日志回调。
  final VoidCallback onLogs;

  /// 删除回调。
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.dark500 : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.key_outlined,
                    color: Color(0xFFEA580C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              ak.name.isEmpty ? '未命名 AK' : ak.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(enabled: ak.enabled),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              ak.accessKey,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            iconSize: 16,
                            onPressed: () => unawaited(_copyKey(context)),
                            icon: const Icon(Icons.copy_outlined),
                            color: AppColors.flame500,
                            tooltip: '复制 AK',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '创建于 ${ak.displayCreatedAt}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    ak.enabled
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                    size: 16,
                  ),
                  label: Text(ak.enabled ? '禁用' : '启用'),
                  style: TextButton.styleFrom(
                    foregroundColor: ak.enabled
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF22C55E),
                  ),
                ),
                TextButton.icon(
                  onPressed: onPermission,
                  icon: const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 16,
                  ),
                  label: const Text('权限'),
                ),
                TextButton.icon(
                  onPressed: onLogs,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('日志'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 复制密钥并提示。
  Future<void> _copyKey(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: ak.accessKey));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('AK 已复制')));
  }
}

/// 启用状态徽标。
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color color =
        enabled ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            enabled ? '启用' : '禁用',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
