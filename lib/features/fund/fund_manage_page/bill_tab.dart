import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/infinite_scroll.dart';
import '../../../data/models/bill.dart';
import '../bill_controller.dart';
import '../fund_meta.dart';
import 'fund_error_view.dart';
import 'fund_search_field.dart';

/// 账单 tab：账期/模块/状态筛选 + 关键字搜索 + 出账生成 + 真分页列表。
///
/// 搬迁自 vue_flamecloud/BillPage，列表数据来自真实后端出账接口。
class BillTab extends ConsumerStatefulWidget {
  const BillTab({super.key});

  @override
  ConsumerState<BillTab> createState() => _BillTabState();
}

class _BillTabState extends ConsumerState<BillTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(billControllerProvider.notifier).load());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final BillState state = ref.watch(billControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FundSearchField(
                  hintText: '搜索账单编码/实例',
                  onSubmitted: (String value) => unawaited(
                    ref.read(billControllerProvider.notifier).search(value),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: state.generating
                    ? null
                    : () => unawaited(
                          ref.read(billControllerProvider.notifier).generate(),
                        ),
                tooltip: '生成当月账单',
                icon: state.generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew_outlined, size: 20),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _FilterRow(state: state),
        ),
        Expanded(child: _buildList(state)),
      ],
    );
  }

  Widget _buildList(BillState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return FundErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(billControllerProvider.notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 80),
        children: <Widget>[
          Center(
            child: Text(
              state.errorMessage ?? '暂无账单，点击右上角生成当月账单',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (state.errorMessage == null)
            Center(
              child: FilledButton.icon(
                onPressed: () => unawaited(
                  ref.read(billControllerProvider.notifier).generate(),
                ),
                icon: const Icon(Icons.autorenew_outlined),
                label: const Text('生成当月账单'),
              ),
            ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(billControllerProvider.notifier).refresh(),
      child: InfiniteScrollListener(
        onLoadMore: () =>
            ref.read(billControllerProvider.notifier).loadMore(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: state.items.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == state.items.length) {
              return LoadMoreFooter(
                loading: state.loading,
                hasMore: state.hasMore,
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BillTile(
                item: state.items[index],
                onTap: () => unawaited(
                  Navigator.of(context).pushNamed(
                    AppRoutes.billDetail,
                    arguments: state.items[index],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 账期 / 模块 / 状态的筛选行。
class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.state});

  final BillState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> modules = <String>[
      'all',
      'cpu',
      'memory',
      'disk',
      'bandwidth',
    ];
    final List<String> statuses = <String>['all', '0', '1'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        DropdownButton<String>(
          value: state.period,
          isDense: true,
          underline: const SizedBox.shrink(),
          items: <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: 'all',
              child: Text('全部账期'),
            ),
            ...state.periods.map(
              (String p) => DropdownMenuItem<String>(
                value: p,
                child: Text(p),
              ),
            ),
          ],
          onChanged: (String? value) {
            if (value != null) {
              unawaited(
                ref.read(billControllerProvider.notifier).changePeriod(value),
              );
            }
          },
        ),
        ...modules.map(
          (String m) => _Chip(
            label: m == 'all' ? '全部模块' : FundMeta.billModuleText(m),
            selected: state.moduleType == m,
            onTap: () => unawaited(
              ref.read(billControllerProvider.notifier).changeModule(m),
            ),
          ),
        ),
        ...statuses.map(
          (String s) => _Chip(
            label: s == 'all' ? '全部状态' : FundMeta.billStatusText(int.parse(s)),
            selected: state.status == s,
            onTap: () => unawaited(
              ref.read(billControllerProvider.notifier).changeStatus(s),
            ),
          ),
        ),
      ],
    );
  }
}

/// 紧凑筛选标签。
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : context.surfaces.inset,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: selected ? activeColor.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 单条账单卡片。
class BillTile extends StatelessWidget {
  const BillTile({required this.item, this.onTap, super.key});

  final BillItem item;

  /// 点击钻取账单详情，为 null 时不响应。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color metaColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final Color orderNoColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Ink(
        decoration: BoxDecoration(
          color: context.surfaces.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.billNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: orderNoColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(text: item.statusText, color: item.statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    item.settlementText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.flame500,
                    ),
                  ),
                  const Spacer(),
                  Text(item.billingPeriod, style: TextStyle(fontSize: 12, color: metaColor)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  _MetaTag(text: item.moduleText),
                  const SizedBox(width: 6),
                  Flexible(child: _MetaTag(text: item.product)),
                  if (item.instanceId.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 6),
                    Flexible(
                      child: _MetaTag(text: item.instanceId),
                    ),
                  ],
                ],
              ),
              if (item.discountAmount != '0' && item.discountAmount != '0.00')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '原价 ${item.totalText}  优惠 -${item.discountText}',
                    style: TextStyle(fontSize: 12, color: metaColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 账单状态徽标。
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 计费模块 / 产品等次要信息标签。
class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.surfaces.inset,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563),
        ),
      ),
    );
  }
}
