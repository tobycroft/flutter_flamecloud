import 'package:flutter/material.dart';

import '../../core/widgets/detail_info.dart';
import '../../data/models/ecs_instance.dart';

/// ECS 实例详情页。
///
/// 承接实例列表的钻取：展示单台实例的完整字段
/// （实例 ID / 状态 / 地域 / 规格 / IP / 操作系统 / 磁盘 / 网络 / 备注 / 创建时间）。
/// 数据来自列表项 [EcsInstance]，无需额外请求。
class EcsInstanceDetailPage extends StatelessWidget {
  const EcsInstanceDetailPage({super.key, required this.item});

  /// 待展示的实例。
  final EcsInstance item;

  @override
  Widget build(BuildContext context) {
    final String systemDisk = <String>[
      if (item.systemDiskSize != null) '${item.systemDiskSize}GB',
      if (item.systemDiskType != null && item.systemDiskType!.isNotEmpty)
        item.systemDiskType!,
    ].join(' ');

    return Scaffold(
      appBar: AppBar(title: const Text('实例详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dns_outlined,
                  color: Color(0xFF3B82F6),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isRunning
                      ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                      : const Color(0xFF9CA3AF).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isRunning
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailCard(
            rows: <Widget>[
              DetailRow(
                label: '实例 ID',
                value: item.instanceId,
                mono: true,
              ),
              DetailRow(label: '地域', value: item.region),
              DetailRow(
                label: '可用区',
                value: item.zone ?? '',
              ),
              DetailRow(label: '规格', value: item.specText),
              DetailRow(label: '操作系统', value: item.osText),
              DetailRow(
                label: '系统盘',
                value: systemDisk,
              ),
              DetailRow(
                label: '公网 IP',
                value: item.publicIp ?? '',
                mono: item.hasIp,
              ),
              DetailRow(
                label: '私网 IP',
                value: item.privateIp ?? '',
                mono: item.privateIp != null && item.privateIp!.isNotEmpty,
              ),
              DetailRow(label: '私网 VPC', value: item.vpcId ?? ''),
              DetailRow(
                label: '线路类型',
                value: item.lineType ?? '',
              ),
              DetailRow(
                label: '带宽',
                value: item.bandwidth != null ? '${item.bandwidth} Mbps' : '',
              ),
              DetailRow(label: '备注', value: item.remark ?? ''),
              DetailRow(
                label: '创建时间',
                value: item.createdAt,
                selectable: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '启停、重启、重置密码等运维操作将在后续版本开放。',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
