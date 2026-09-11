import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/infinite_scroll.dart';
import '../recharge_order_controller.dart';
import 'fund_error_view.dart';
import 'fund_search_field.dart';
import 'recharge_order_tile.dart';

/// 充值订单 tab：订单号搜索 + 下拉刷新 + 真分页列表。
///
/// 搬迁自 vue_flamecloud/RechargeOrdersPage。
class RechargeOrderTab extends ConsumerStatefulWidget {
  const RechargeOrderTab({super.key});

  @override
  ConsumerState<RechargeOrderTab> createState() => _RechargeOrderTabState();
}

class _RechargeOrderTabState extends ConsumerState<RechargeOrderTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(rechargeOrderControllerProvider.notifier).load());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final RechargeOrderState state = ref.watch(rechargeOrderControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: FundSearchField(
            hintText: '搜索订单号',
            onSubmitted: (String value) => unawaited(
              ref.read(rechargeOrderControllerProvider.notifier).search(value),
            ),
          ),
        ),
        Expanded(child: _buildList(state)),
      ],
    );
  }

  Widget _buildList(RechargeOrderState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return FundErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(rechargeOrderControllerProvider.notifier).refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(rechargeOrderControllerProvider.notifier).refresh(),
      child: state.items.isEmpty
          ? ListView(
              children: const <Widget>[
                SizedBox(height: 120),
                Center(
                  child: Text(
                    '暂无充值订单',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ],
            )
          : InfiniteScrollListener(
              onLoadMore: () =>
                  ref.read(rechargeOrderControllerProvider.notifier).loadMore(),
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
                    child: RechargeOrderTile(item: state.items[index]),
                  );
                },
              ),
            ),
    );
  }
}
