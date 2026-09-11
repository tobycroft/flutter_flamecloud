import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../balance_log_controller.dart';
import 'balance_log_tile.dart';
import 'fund_error_view.dart';
import 'fund_pager.dart';
import 'fund_search_field.dart';

/// 余额流水 tab：描述搜索 + 下拉刷新 + 真分页列表。
///
/// 搬迁自 vue_flamecloud/BalanceLogPage（顶部统计卡已上提到资金管理页）。
class BalanceLogTab extends ConsumerStatefulWidget {
  const BalanceLogTab({super.key});

  @override
  ConsumerState<BalanceLogTab> createState() => _BalanceLogTabState();
}

class _BalanceLogTabState extends ConsumerState<BalanceLogTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(balanceLogControllerProvider.notifier).load());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final BalanceLogState state = ref.watch(balanceLogControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: FundSearchField(
            hintText: '搜索描述',
            onSubmitted: (String value) => unawaited(
              ref.read(balanceLogControllerProvider.notifier).search(value),
            ),
          ),
        ),
        Expanded(child: _buildList(state)),
      ],
    );
  }

  Widget _buildList(BalanceLogState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return FundErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(balanceLogControllerProvider.notifier).refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(balanceLogControllerProvider.notifier).refresh(),
      child: state.items.isEmpty
          ? ListView(
              children: const <Widget>[
                SizedBox(height: 120),
                Center(
                  child: Text(
                    '暂无余额流水',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: state.items.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == state.items.length) {
                  return FundPager(
                    page: state.page,
                    totalPages: state.totalPages,
                    total: state.total,
                    loading: state.loading,
                    onPrev: () => unawaited(
                      ref
                          .read(balanceLogControllerProvider.notifier)
                          .goPage(state.page - 1),
                    ),
                    onNext: () => unawaited(
                      ref
                          .read(balanceLogControllerProvider.notifier)
                          .goPage(state.page + 1),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BalanceLogTile(item: state.items[index]),
                );
              },
            ),
    );
  }
}
