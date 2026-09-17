import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_surfaces.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ecs_instance.dart';
import 'ecs_instance_controller.dart';
import 'ecs_instance_tile.dart';
import 'ecs_security_group_panel.dart';
import 'ecs_snapshot_panel.dart';

/// 地域筛选「全部」占位值。
const String _allRegions = '全部地域';

/// 云服务器 ECS 控制台页。
///
/// 搬迁自 vue_flamecloud 的 EcsPage，提供三个 Tab：
/// - 实例列表：真实接口数据，支持搜索 / 地域筛选 / 刷新 / 创建实例；
/// - 安全组：只读示例数据（后端接口待接入）；
/// - 快照管理：只读示例数据（后端接口待接入）。
///
/// 「服务」页的「云服务器」入口应进入本页，而非直接跳购买页。
class EcsPage extends StatelessWidget {
  const EcsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('云服务器 ECS'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: '实例列表'),
              Tab(text: '安全组'),
              Tab(text: '快照管理'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            EcsInstanceListTab(),
            EcsSecurityGroupPanel(),
            EcsSnapshotPanel(),
          ],
        ),
      ),
    );
  }
}

/// 实例列表 Tab（真实数据）。
class EcsInstanceListTab extends ConsumerStatefulWidget {
  const EcsInstanceListTab({super.key});

  @override
  ConsumerState<EcsInstanceListTab> createState() => _EcsInstanceListTabState();
}

class _EcsInstanceListTabState extends ConsumerState<EcsInstanceListTab> {
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ecsInstanceControllerProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EcsInstanceState state = ref.watch(ecsInstanceControllerProvider);
    final EcsInstanceController notifier =
        ref.read(ecsInstanceControllerProvider.notifier);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _searchCtl,
                onChanged: notifier.setSearchQuery,
                decoration: InputDecoration(
                  hintText: '搜索实例名称 / ID / 备注',
                  hintStyle: TextStyle(color: secondary),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: context.surfaces.inset,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _RegionFilter(state: state, notifier: notifier),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '共 ${state.items.length} 台实例',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(
                      Navigator.of(context).pushNamed(AppRoutes.ecsBuy),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('创建实例'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.flame500,
                      side: BorderSide(
                        color: AppColors.flame500.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.refresh,
            child: _buildBody(context, state, notifier),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    EcsInstanceState state,
    EcsInstanceController notifier,
  ) {
    if (state.loading && state.items.isEmpty) {
      return ListView(
        children: const <Widget>[
          SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return ListView(
        children: <Widget>[
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: notifier.refresh,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final List<EcsInstance> list = state.filtered;
    if (list.isEmpty) {
      final String hint = state.searchQuery.trim().isNotEmpty ||
              state.selectedRegion != null
          ? '没有匹配的实例'
          : '暂无实例，点击「创建实例」新建一台';
      return ListView(
        children: <Widget>[
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                hint,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final EcsInstance item = list[index];
        return EcsInstanceTile(
          item: item,
          onTap: () => unawaited(
            Navigator.of(context).pushNamed(
              AppRoutes.ecsDetail,
              arguments: item,
            ),
          ),
        );
      },
    );
  }
}

/// 地域筛选下拉。
class _RegionFilter extends StatelessWidget {
  const _RegionFilter({required this.state, required this.notifier});

  final EcsInstanceState state;
  final EcsInstanceController notifier;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final String current = state.selectedRegion ?? _allRegions;
    final List<DropdownMenuItem<String>> items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: _allRegions,
        child: Text(_allRegions),
      ),
      for (final String region in state.regionOptions)
        DropdownMenuItem<String>(value: region, child: Text(region)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.surfaces.inset,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          items: items,
          onChanged: (String? value) =>
              notifier.setRegion(value == _allRegions ? null : value),
          style: TextStyle(fontSize: 13, color: secondary),
          icon: const Icon(Icons.filter_list, size: 16),
        ),
      ),
    );
  }
}
