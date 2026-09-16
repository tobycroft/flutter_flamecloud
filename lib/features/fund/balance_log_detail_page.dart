import 'package:flutter/material.dart';

import '../../core/widgets/detail_info.dart';
import '../../data/models/balance_log.dart';
import 'fund_meta.dart';

/// 余额流水详情页。
///
/// 承接资金管理页「余额流水」列表的钻取：展示单条流水的完整字段
/// （流水 ID / 类型 / 变动金额 / 变动后余额 / 关联订单 / 描述 / 时间）。
/// 数据来自列表项 [BalanceLogItem]，无需额外请求。
class BalanceLogDetailPage extends StatelessWidget {
  const BalanceLogDetailPage({super.key, required this.item});

  /// 待展示的流水。
  final BalanceLogItem item;

  @override
  Widget build(BuildContext context) {
    final bool income = FundMeta.balanceTypeIsIncome(item.type);
    return Scaffold(
      appBar: AppBar(title: const Text('流水详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DetailCard(
            rows: <Widget>[
              DetailRow(
                label: '流水 ID',
                value: '${item.id}',
                selectable: true,
              ),
              DetailRow(
                label: '流水类型',
                value: FundMeta.balanceTypeText(item.type),
              ),
              DetailRow(
                label: '变动金额',
                value: '${income ? '+' : '-'}¥${item.amountText}',
              ),
              DetailRow(
                label: '变动后余额',
                value: '¥${item.balanceAfterText}',
              ),
              if (item.orderNo.isNotEmpty)
                DetailRow(
                  label: '关联订单',
                  value: item.orderNo,
                  mono: true,
                  selectable: true,
                ),
              DetailRow(label: '描述', value: item.description),
              DetailRow(
                label: '时间',
                value: item.displayTime,
                selectable: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
