/// 操作日志页单条日志条目。
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/action_log.dart';

/// 单条操作日志。
class ActionLogTile extends StatelessWidget {
  const ActionLogTile({super.key, required this.item, required this.types});

  final ActionLogItem item;
  final List<ActionLogType> types;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color typeColor = _typeColor(_typeCode(item.logTypeId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  _typeName(item.logTypeId),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
              if (item.deviceType != null && item.deviceType!.isNotEmpty)
                ...<Widget>[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _deviceColor(item.deviceType!)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      item.deviceType!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _deviceColor(item.deviceType!),
                      ),
                    ),
                  ),
                ],
              const Spacer(),
              Text(
                item.displayTime,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              item.action,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (item.detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.detail,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color:
                      isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151),
                ),
              ),
            ),
          if (item.ip.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'IP ${item.ip}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 类型中文名，字典缺失时退化为「类型 {id}」。
  String _typeName(int typeId) {
    for (final ActionLogType type in types) {
      if (type.id == typeId) {
        return type.name;
      }
    }
    return '类型 $typeId';
  }

  /// 类型 code，字典缺失时返回空串。
  String _typeCode(int typeId) {
    for (final ActionLogType type in types) {
      if (type.id == typeId) {
        return type.code;
      }
    }
    return '';
  }

  /// 类型对应主题色，对齐 Vue 端映射：user 蓝、system 黄、ak 紫，其余灰。
  static Color _typeColor(String code) {
    switch (code) {
      case 'user':
        return const Color(0xFF3B82F6);
      case 'system':
        return const Color(0xFFF59E0B);
      case 'ak':
        return const Color(0xFFA855F7);
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// 设备对应主题色：web 天蓝、android 绿、ios 黑。
  static Color _deviceColor(String device) {
    switch (device) {
      case 'web':
        return const Color(0xFF0EA5E9);
      case 'android':
        return const Color(0xFF22C55E);
      case 'ios':
        return const Color(0xFF111827);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
