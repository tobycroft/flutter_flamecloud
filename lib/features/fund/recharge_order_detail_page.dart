import 'package:flutter/material.dart';

import '../../core/widgets/detail_info.dart';
import '../../data/models/recharge_order.dart';
import 'fund_meta.dart';

/// 充值订单详情页。
///
/// 承接资金管理页「充值订单」列表的钻取：展示单条订单的完整字段
/// （订单号 / 金额 / 支付方式 / 来源 / 状态 / 时间 / 汇款时间 / 备注）。
/// 数据来自列表项 [RechargeOrderItem]，无需额外请求。
class RechargeOrderDetailPage extends StatelessWidget {
  const RechargeOrderDetailPage({super.key, required this.item});

  /// 待展示的订单。
  final RechargeOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DetailCard(
            rows: <Widget>[
              DetailRow(
                label: '订单号',
                value: item.orderNo,
                mono: true,
                selectable: true,
              ),
              DetailRow(label: '充值金额', value: '¥${item.amountText}'),
              DetailRow(
                label: '支付方式',
                value: FundMeta.payMethodText(item.payMethod),
              ),
              DetailRow(
                label: '充值来源',
                value: item.type == 2 ? '线下充值' : '在线充值',
              ),
              DetailRow(
                label: '订单状态',
                value: FundMeta.orderStatusText(item.status),
              ),
              DetailRow(
                label: '创建时间',
                value: item.displayTime,
                selectable: true,
              ),
              if (item.remitTimeText.isNotEmpty)
                DetailRow(
                  label: '汇款时间',
                  value: item.remitTimeText,
                  selectable: true,
                ),
              if (item.remark.isNotEmpty)
                DetailRow(label: '备注', value: item.remark),
            ],
          ),
        ],
      ),
    );
  }
}
