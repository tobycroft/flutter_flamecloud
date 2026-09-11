import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_flamecloud/data/models/balance_log.dart';
import 'package:flutter_flamecloud/data/models/recharge_order.dart';
import 'package:flutter_flamecloud/features/fund/balance_log_controller.dart';
import 'package:flutter_flamecloud/features/fund/balance_summary_controller.dart';
import 'package:flutter_flamecloud/features/fund/fund_manage_page.dart';
import 'package:flutter_flamecloud/features/fund/fund_meta.dart';
import 'package:flutter_flamecloud/features/fund/recharge_order_controller.dart';

/// 余额概览桩：直接给出概览数据，避免测试触发网络请求。
class _StubSummaryController extends BalanceSummaryController {
  @override
  BalanceSummaryState build() => const BalanceSummaryState(
    summary: BalanceSummary(
      balance: '1234.5',
      frozen: '0.00',
      totalRecharge: '2000',
      totalConsume: '765.44',
    ),
  );
}

/// 充值订单桩：固定一页数据，`load` 无副作用。
class _StubRechargeOrderController extends RechargeOrderController {
  @override
  RechargeOrderState build() => const RechargeOrderState(
    items: <RechargeOrderItem>[
      RechargeOrderItem(
        id: 1,
        orderNo: 'CZ202609111030001234',
        amount: '100',
        payMethod: 'alipay',
        type: 1,
        status: 0,
        createdAt: '2026-09-11T10:30:00',
        remitTime: '',
        remark: '',
      ),
    ],
    total: 1,
  );

  @override
  Future<void> load() async {}
}

/// 余额流水桩：固定一页数据，`load` 无副作用。
class _StubBalanceLogController extends BalanceLogController {
  @override
  BalanceLogState build() => const BalanceLogState(
    items: <BalanceLogItem>[
      BalanceLogItem(
        id: 1,
        type: 1,
        orderNo: 'CZ202609111030001234',
        amount: '500',
        balanceAfter: '1734.5',
        description: '在线充值成功',
        createdAt: '2026-09-11T10:31:00',
      ),
    ],
    total: 1,
  );

  @override
  Future<void> load() async {}
}

void main() {
  group('资金管理数据解析', () {
    test('充值订单解析订单号、金额与时间', () {
      final RechargeOrderItem item = RechargeOrderItem.fromMap(
        <String, dynamic>{
          'id': '7',
          'order_no': 'CZ202609111030001234',
          'amount': '100',
          'pay_method': 'bank_transfer',
          'type': '2',
          'status': '3',
          'created_at': '2026-09-11T10:30:00',
          'remit_time': '2026-09-11T10:00:00',
          'remark': '已汇款',
        },
      );

      expect(item.id, 7);
      expect(item.orderNo, 'CZ202609111030001234');
      expect(item.amountText, '100.00');
      expect(item.displayTime, '2026-09-11 10:30:00');
      expect(item.remitTimeText, '2026-09-11 10:00:00');
      expect(FundMeta.payMethodText(item.payMethod), '银行转账');
      expect(FundMeta.orderStatusText(item.status), '审核中');
    });

    test('余额流水解析金额、变动后余额与收支方向', () {
      final BalanceLogItem item = BalanceLogItem.fromMap(<String, dynamic>{
        'id': 3,
        'type': 2,
        'order_no': '',
        'amount': '12.5',
        'balance_after': '1734.5',
        'description': '云服务器续费',
        'created_at': '2026-09-11T10:32:00.000Z',
      });

      expect(item.amountText, '12.50');
      expect(item.balanceAfterText, '1734.50');
      expect(item.displayTime, '2026-09-11 10:32:00');
      expect(FundMeta.balanceTypeText(item.type), '消费');
      expect(FundMeta.balanceTypeIsIncome(item.type), isFalse);
    });

    test('余额概览缺字段时退化为 0.00', () {
      final BalanceSummary summary = BalanceSummary.fromMap(<String, dynamic>{
        'balance': 18,
      });

      expect(summary.balanceText, '18.00');
      expect(summary.totalRechargeText, '0.00');
      expect(summary.totalConsumeText, '0.00');
    });
  });

  testWidgets('资金管理页渲染余额概览与充值订单', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          balanceSummaryControllerProvider.overrideWith(
            _StubSummaryController.new,
          ),
          rechargeOrderControllerProvider.overrideWith(
            _StubRechargeOrderController.new,
          ),
          balanceLogControllerProvider.overrideWith(
            _StubBalanceLogController.new,
          ),
        ],
        child: const MaterialApp(home: FundManagePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('资金管理'), findsOneWidget);
    expect(find.text('¥ 1234.50'), findsOneWidget);
    expect(find.text('¥ 2000.00'), findsOneWidget);
    expect(find.text('¥ 765.44'), findsOneWidget);

    expect(find.text('充值订单'), findsOneWidget);
    expect(find.text('CZ202609111030001234'), findsOneWidget);
    expect(find.text('¥100.00'), findsOneWidget);
    expect(find.text('待支付'), findsOneWidget);
    expect(find.text('支付宝'), findsOneWidget);
  });

  testWidgets('切换到余额流水 tab 展示流水明细', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          balanceSummaryControllerProvider.overrideWith(
            _StubSummaryController.new,
          ),
          rechargeOrderControllerProvider.overrideWith(
            _StubRechargeOrderController.new,
          ),
          balanceLogControllerProvider.overrideWith(
            _StubBalanceLogController.new,
          ),
        ],
        child: const MaterialApp(home: FundManagePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('余额流水'));
    await tester.pumpAndSettle();

    expect(find.text('充值'), findsOneWidget);
    expect(find.text('+¥500.00'), findsOneWidget);
    expect(find.text('在线充值成功'), findsOneWidget);
    expect(find.text('变动后余额 ¥1734.50'), findsOneWidget);
  });
}
