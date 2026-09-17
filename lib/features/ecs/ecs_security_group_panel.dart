import 'package:flutter/material.dart';

import '../../core/theme/app_surfaces.dart';
import '../../core/theme/app_theme.dart';

/// 安全组（只读示例数据）。
///
/// 后端暂未提供安全组接口，数据与 vue_flamecloud 的 EcsPage「安全组」Tab
/// 保持一致，仅用于展示结构；创建 / 添加规则 / 编辑 / 删除等操作尚未开放。
class _SecurityGroup {
  const _SecurityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.rules,
    required this.instances,
  });

  final String id;
  final String name;
  final String description;
  final int rules;
  final int instances;
}

class _SecurityRule {
  const _SecurityRule({
    required this.direction,
    required this.protocol,
    required this.port,
    required this.source,
    required this.action,
    required this.description,
  });

  final String direction;
  final String protocol;
  final String port;
  final String source;
  final String action;
  final String description;
}

const List<_SecurityGroup> _demoGroups = <_SecurityGroup>[
  _SecurityGroup(
    id: 'sg-001',
    name: '默认安全组',
    description: '系统默认安全组',
    rules: 5,
    instances: 3,
  ),
  _SecurityGroup(
    id: 'sg-002',
    name: 'Web服务器安全组',
    description: '开放80/443端口',
    rules: 4,
    instances: 2,
  ),
  _SecurityGroup(
    id: 'sg-003',
    name: '数据库安全组',
    description: '仅允许内网访问3306',
    rules: 1,
    instances: 1,
  ),
];

const List<_SecurityRule> _demoRules = <_SecurityRule>[
  _SecurityRule(
    direction: '入方向',
    protocol: 'TCP',
    port: '22',
    source: '0.0.0.0/0',
    action: '允许',
    description: 'SSH远程连接',
  ),
  _SecurityRule(
    direction: '入方向',
    protocol: 'TCP',
    port: '80',
    source: '0.0.0.0/0',
    action: '允许',
    description: 'HTTP访问',
  ),
  _SecurityRule(
    direction: '入方向',
    protocol: 'TCP',
    port: '443',
    source: '0.0.0.0/0',
    action: '允许',
    description: 'HTTPS访问',
  ),
  _SecurityRule(
    direction: '入方向',
    protocol: 'ICMP',
    port: '-',
    source: '0.0.0.0/0',
    action: '允许',
    description: 'Ping监控',
  ),
  _SecurityRule(
    direction: '出方向',
    protocol: 'ALL',
    port: '-',
    source: '0.0.0.0/0',
    action: '允许',
    description: '允许所有出站流量',
  ),
  _SecurityRule(
    direction: '入方向',
    protocol: 'TCP',
    port: '3306',
    source: '10.0.0.0/8',
    action: '允许',
    description: 'MySQL内网访问',
  ),
];

/// 安全组面板（只读示例）。
class EcsSecurityGroupPanel extends StatefulWidget {
  const EcsSecurityGroupPanel({super.key});

  @override
  State<EcsSecurityGroupPanel> createState() => _EcsSecurityGroupPanelState();
}

class _EcsSecurityGroupPanelState extends State<EcsSecurityGroupPanel> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const EcsDemoBanner(text: '安全组为示例数据，后端接口待接入，创建/编辑操作暂未开放。'),
        const SizedBox(height: 12),
        for (int i = 0; i < _demoGroups.length; i++) ...<Widget>[
          _SecurityGroupCard(
            group: _demoGroups[i],
            expanded: _expandedId == _demoGroups[i].id,
            onTap: () => setState(() {
              final String id = _demoGroups[i].id;
              _expandedId = _expandedId == id ? null : id;
            }),
          ),
          if (i != _demoGroups.length - 1) const SizedBox(height: 12),
        ],
        SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

class EcsDemoBanner extends StatelessWidget {
  const EcsDemoBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityGroupCard extends StatelessWidget {
  const _SecurityGroupCard({
    required this.group,
    required this.expanded,
    required this.onTap,
  });

  final _SecurityGroup group;
  final bool expanded;
  final VoidCallback onTap;

  List<_SecurityRule> get _rules =>
      _demoRules.where((_SecurityRule r) => _matchesGroup(r)).toList();

  bool _matchesGroup(_SecurityRule r) {
    // sg-001 / sg-002 共享前 5 条通用规则；sg-003 仅数据库规则。
    if (group.id == 'sg-003') {
      return r.description.contains('MySQL');
    }
    return !r.description.contains('MySQL');
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
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
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
                      Icons.shield_outlined,
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
                          group.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.description,
                          style: TextStyle(fontSize: 12, color: secondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text('${group.rules} 条规则',
                          style: TextStyle(fontSize: 12, color: secondary)),
                      const SizedBox(height: 2),
                      Text('${group.instances} 台实例',
                          style: TextStyle(fontSize: 12, color: secondary)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: secondary,
                  ),
                ],
              ),
            ),
            if (expanded) ...<Widget>[
              Divider(height: 1, color: context.surfaces.line),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('规则',
                        style: TextStyle(fontSize: 12, color: secondary)),
                    const SizedBox(height: 8),
                    for (final _SecurityRule rule in _rules) ...<Widget>[
                      _RuleRow(rule: rule),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});

  final _SecurityRule rule;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final Color tertiary = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF9CA3AF);

    final bool inbound = rule.direction == '入方向';
    final bool allow = rule.action == '允许';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaces.inset,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (inbound ? Colors.green : Colors.blue)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rule.direction,
              style: TextStyle(
                fontSize: 11,
                color: inbound ? Colors.green : Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${rule.protocol} ${rule.port} · ${rule.source}',
              style: TextStyle(
                fontSize: 12,
                color: secondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (allow ? Colors.green : Colors.red)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rule.action,
              style: TextStyle(
                fontSize: 11,
                color: allow ? Colors.green : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              rule.description,
              style: TextStyle(fontSize: 12, color: tertiary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
