import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../ticket/ticket_summary_controller.dart';
import 'home_data.dart';
import 'home_models.dart';
import 'home_utils.dart';
import 'section_title.dart';

/// 待办事项。
///
/// 「待回复工单」的数量来自后端聚合计数（未结案关闭且未删除），
/// 工单状态变化后控制器会失效该 provider，回到首页即为最新值。
class HomeTodoSection extends ConsumerWidget {
  const HomeTodoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HomeSectionTitle('待办事项'),
        Material(
          color: context.surfaces.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < homeTodoItems.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(height: 1, color: context.surfaces.line),
                _HomeTodoTile(item: homeTodoItems[i], isDark: isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeTodoTile extends ConsumerWidget {
  const _HomeTodoTile({required this.item, required this.isDark});

  final HomeTodoItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasRoute = item.route != null;
    // 只有工单待办取实时计数，其余仍用静态值（后端暂无对应统计接口）。
    final int count = item.liveTicketCount
        ? ref.watch(pendingTicketCountProvider).value ?? item.count
        : item.count;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () {
        if (hasRoute) {
          unawaited(Navigator.of(context).pushNamed(item.route!));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(item.icon, size: 20, color: homeTertiaryColor(isDark)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: count > 0
                    ? AppColors.flame500.withValues(alpha: 0.12)
                    : context.surfaces.inset,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: count > 0 ? AppColors.flame500 : homeTertiaryColor(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
