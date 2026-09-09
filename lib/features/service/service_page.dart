import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// 服务 tab。
///
/// 目录参考 vue_flamecloud 控制台左侧菜单（ConsoleSidebar.vue）与顶部主菜单
/// （ConsoleHeader.vue）整理而来，具体页面随控制台搬迁逐个接入。
class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  /// 服务目录。
  static const List<ServiceEntry> entries = <ServiceEntry>[
    ServiceEntry(
      icon: Icons.dns_outlined,
      name: '云服务器',
      description: 'ECS 实例的创建、续费与运维',
    ),
    ServiceEntry(
      icon: Icons.hub_outlined,
      name: '云网络',
      description: '弹性公网 IP、负载均衡与 VPC',
    ),
    ServiceEntry(
      icon: Icons.storage_outlined,
      name: '云存储',
      description: '云硬盘、快照与对象存储',
    ),
    ServiceEntry(
      icon: Icons.inventory_2_outlined,
      name: '资源管理',
      description: '资源包与资源总览',
    ),
    ServiceEntry(
      icon: Icons.key_outlined,
      name: 'AK 管理',
      description: '访问密钥的创建与停用',
    ),
    ServiceEntry(
      icon: Icons.history_outlined,
      name: '操作日志',
      description: '账号下的操作审计记录',
    ),
    ServiceEntry(
      icon: Icons.confirmation_number_outlined,
      name: '工单',
      description: '提交与跟踪售后工单',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('服务'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          return _ServiceTile(entry: entries[index], isDark: isDark);
        },
      ),
    );
  }
}

/// 服务条目数据。
class ServiceEntry {
  const ServiceEntry({
    required this.icon,
    required this.name,
    required this.description,
  });

  /// 图标。
  final IconData icon;

  /// 名称。
  final String name;

  /// 描述。
  final String description;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.entry, required this.isDark});

  final ServiceEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.dark500 : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _comingSoon(context, entry.name),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.flame500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(entry.icon, color: AppColors.flame500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$name 正在搬迁中，敬请期待')),
      );
  }
}
