import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/action_log.dart';
import 'action_log_controller.dart';

/// 操作日志页，搬迁自 vue_flamecloud/ActionLogsPage。
///
/// 顶部为日志类型筛选条（综合 + 动态类型字典，对应 Vue 端
/// `?log_type_id=` 的筛选行为），下方为分页日志列表。
class ActionLogPage extends ConsumerStatefulWidget {
  const ActionLogPage({super.key});

  @override
  ConsumerState<ActionLogPage> createState() => _ActionLogPageState();
}

class _ActionLogPageState extends ConsumerState<ActionLogPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(actionLogControllerProvider.notifier).load());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ActionLogState state = ref.watch(actionLogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('操作日志'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _TypeFilterBar(state: state),
          const Divider(height: 1),
          Expanded(child: _buildList(state)),
        ],
      ),
    );
  }

  Widget _buildList(ActionLogState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(actionLogControllerProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(actionLogControllerProvider.notifier).refresh(),
        child: ListView(
          children: const <Widget>[
            SizedBox(height: 120),
            Center(
              child: Text(
                '暂无日志',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(actionLogControllerProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: state.items.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == state.items.length) {
            return _ActionLogPager(state: state);
          }
          return _ActionLogTile(
            item: state.items[index],
            types: state.types,
          );
        },
      ),
    );
  }
}

/// 类型筛选条：「综合」+ 动态类型 chips，横向滚动。
class _TypeFilterBar extends ConsumerWidget {
  const _TypeFilterBar({required this.state});

  final ActionLogState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.typesLoading && state.types.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: <Widget>[
          _TypeChip(
            label: '综合',
            selected: state.selectedTypeId == null,
            onTap: () => unawaited(
              ref.read(actionLogControllerProvider.notifier).selectType(null),
            ),
          ),
          for (final ActionLogType type in state.types)
            _TypeChip(
              label: type.name,
              selected: state.selectedTypeId == type.id,
              onTap: () => unawaited(
                ref
                    .read(actionLogControllerProvider.notifier)
                    .selectType(type.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// 类型筛选 chip。
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? primary
                : (isDark ? const Color(0xFF151A3A) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? primary
                  : (isDark
                      ? const Color(0xFF1A1F4E)
                      : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF4B5563)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单条操作日志。
class _ActionLogTile extends StatelessWidget {
  const _ActionLogTile({required this.item, required this.types});

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

/// 加载失败视图，提供重试入口。
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => unawaited(onRetry()),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 底部分页条，展示「第 X / Y 页 (共 N 条)」。
class _ActionLogPager extends ConsumerWidget {
  const _ActionLogPager({required this.state});

  final ActionLogState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton(
            onPressed: state.loading || state.page <= 1
                ? null
                : () => unawaited(
                      ref
                          .read(actionLogControllerProvider.notifier)
                          .goPage(state.page - 1),
                    ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('上一页'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '第 ${state.page} / ${state.totalPages} 页 (共 ${state.total} 条)',
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: state.loading || state.page >= state.totalPages
                ? null
                : () => unawaited(
                      ref
                          .read(actionLogControllerProvider.notifier)
                          .goPage(state.page + 1),
                    ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('下一页'),
          ),
        ],
      ),
    );
  }
}
