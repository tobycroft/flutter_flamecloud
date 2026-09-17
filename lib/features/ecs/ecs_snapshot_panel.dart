import 'package:flutter/material.dart';

import '../../core/theme/app_surfaces.dart';
import '../../core/theme/app_theme.dart';
import 'ecs_security_group_panel.dart' show EcsDemoBanner;

/// 快照（只读示例数据）。
///
/// 后端暂未提供快照接口，数据与 vue_flamecloud 的 EcsPage「快照管理」Tab
/// 保持一致，仅用于展示结构；回滚磁盘 / 创建镜像 / 删除等操作尚未开放。
class _Snapshot {
  const _Snapshot({
    required this.id,
    required this.name,
    required this.diskType,
    required this.diskSize,
    required this.instanceName,
    required this.status,
    required this.progress,
    required this.createTime,
  });

  final String id;
  final String name;
  final String diskType;
  final String diskSize;
  final String instanceName;
  final String status; // completed / creating
  final String progress;
  final String createTime;

  bool get isCompleted => status == 'completed';
}

const List<_Snapshot> _demoSnapshots = <_Snapshot>[
  _Snapshot(
    id: 'snap-001',
    name: '生产环境-系统盘快照',
    diskType: '系统盘',
    diskSize: '40GB',
    instanceName: '生产环境服务器',
    status: 'completed',
    progress: '100%',
    createTime: '2025-07-10 02:00:00',
  ),
  _Snapshot(
    id: 'snap-002',
    name: '数据库-数据盘快照',
    diskType: '数据盘',
    diskSize: '100GB',
    instanceName: '数据库服务器',
    status: 'completed',
    progress: '100%',
    createTime: '2025-07-11 03:00:00',
  ),
  _Snapshot(
    id: 'snap-003',
    name: '测试环境-系统盘快照',
    diskType: '系统盘',
    diskSize: '40GB',
    instanceName: '测试环境服务器',
    status: 'creating',
    progress: '65%',
    createTime: '2025-07-12 10:00:00',
  ),
  _Snapshot(
    id: 'snap-004',
    name: '开发环境-系统盘快照',
    diskType: '系统盘',
    diskSize: '40GB',
    instanceName: '开发环境服务器',
    status: 'completed',
    progress: '100%',
    createTime: '2025-07-08 01:00:00',
  ),
];

/// 快照面板（只读示例）。
class EcsSnapshotPanel extends StatelessWidget {
  const EcsSnapshotPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const EcsDemoBanner(
          text: '快照为示例数据，后端接口待接入，回滚/创建镜像/删除操作暂未开放。',
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < _demoSnapshots.length; i++) ...<Widget>[
          _SnapshotCard(snapshot: _demoSnapshots[i]),
          if (i != _demoSnapshots.length - 1) const SizedBox(height: 12),
        ],
        SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.snapshot});

  final _Snapshot snapshot;

  void _notify(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label（示例数据，暂未开放）')));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (snapshot.isCompleted
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: snapshot.isCompleted
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        snapshot.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        snapshot.id,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: snapshot.isCompleted
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      snapshot.isCompleted
                          ? '已完成'
                          : '创建中 ${snapshot.progress}',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: context.surfaces.line),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _MetaChip(label: '磁盘类型', value: snapshot.diskType),
                const SizedBox(width: 8),
                _MetaChip(label: '磁盘容量', value: snapshot.diskSize),
                const SizedBox(width: 8),
                _MetaChip(label: '关联实例', value: snapshot.instanceName),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '创建时间：${snapshot.createTime}',
              style: TextStyle(fontSize: 12, color: secondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _ActionButton(
                  label: '回滚磁盘',
                  onTap: (BuildContext c) => _notify(c, '回滚磁盘'),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: '创建镜像',
                  onTap: (BuildContext c) => _notify(c, '创建镜像'),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: '删除',
                  danger: true,
                  onTap: (BuildContext c) => _notify(c, '删除快照'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.surfaces.inset,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label,
                style: TextStyle(fontSize: 11, color: secondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final void Function(BuildContext) onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color color =
        danger ? const Color(0xFFDC2626) : const Color(0xFF3B82F6);
    return Expanded(
      child: OutlinedButton(
        onPressed: () => onTap(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
