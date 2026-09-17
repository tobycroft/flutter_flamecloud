import 'package:flutter/material.dart';

import '../../core/theme/app_surfaces.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ecs_instance.dart';

/// ECS 实例列表行。
///
/// 展示实例名称/ID/备注、地域、运行状态、规格、IP（等宽）与操作系统；
/// 整行可点击钻取至详情页。
class EcsInstanceTile extends StatelessWidget {
  const EcsInstanceTile({
    super.key,
    required this.item,
    this.onTap,
  });

  /// 待展示的实例。
  final EcsInstance item;

  /// 点击回调（钻取详情）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final Color tertiary = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF9CA3AF);

    return Material(
      color: context.surfaces.panel,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.dns_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.instanceId,
                      style: TextStyle(
                        fontSize: 12,
                        color: tertiary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (item.remark != null && item.remark!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        item.remark!,
                        style: TextStyle(fontSize: 12, color: secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.isRunning
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.statusText,
                        style: TextStyle(fontSize: 12, color: secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.specText,
                    style: TextStyle(fontSize: 12, color: tertiary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.ipText,
                    style: TextStyle(
                      fontSize: 12,
                      color: item.hasIp ? tertiary : const Color(0xFFF59E0B),
                      fontFamily: item.hasIp ? 'monospace' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
