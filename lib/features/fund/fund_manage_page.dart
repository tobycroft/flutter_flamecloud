import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'balance_summary_controller.dart';
import 'fund_manage_page/balance_log_tab.dart';
import 'fund_manage_page/fund_balance_card.dart';
import 'fund_manage_page/recharge_order_tab.dart';

/// 资金管理页。
///
/// 把 vue_flamecloud 的「充值订单」与「余额流水」两个页面合并到一页：
/// 顶部固定余额概览卡（当前余额 / 累计充值 / 累计消费），
/// 下方用 Tab 切换两个分页列表。
///
/// 入口有二：「我的」页的「资金管理」项，以及「我的」页顶部账户余额区块。
class FundManagePage extends ConsumerStatefulWidget {
  const FundManagePage({super.key});

  @override
  ConsumerState<FundManagePage> createState() => _FundManagePageState();
}

class _FundManagePageState extends ConsumerState<FundManagePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(balanceSummaryControllerProvider.notifier).refresh(),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('资金管理')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: FundBalanceCard(),
          ),
          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: const <Widget>[
              Tab(text: '充值订单'),
              Tab(text: '余额流水'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const <Widget>[RechargeOrderTab(), BalanceLogTab()],
            ),
          ),
        ],
      ),
    );
  }
}
