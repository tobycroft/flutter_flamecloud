import 'package:flutter/material.dart';

import '../../core/widgets/detail_info.dart';
import '../../data/models/bill.dart';
import 'fund_meta.dart';

/// 账单详情页。
///
/// 承接资金管理页「账单」列表的钻取：展示单条账单的完整字段
/// （账单编码 / 账期 / 产品 / 实例 / 计费模块 / 支付方式 /
/// 原价 / 优惠 / 结算价 / 代金券 / 余额支付 / 状态 / 账期与出账时间）。
/// 数据来自列表项 [BillItem]，无需额外请求。
class BillDetailPage extends StatelessWidget {
  const BillDetailPage({super.key, required this.item});

  /// 待展示的账单。
  final BillItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账单详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DetailCard(
            rows: <Widget>[
              DetailRow(
                label: '账单编码',
                value: item.billNo,
                mono: true,
                selectable: true,
              ),
              DetailRow(label: '账期', value: item.billingPeriod),
              DetailRow(
                label: '状态',
                value: FundMeta.billStatusText(item.status),
              ),
              DetailRow(label: '产品', value: item.product),
              DetailRow(label: '计费模块', value: item.moduleText),
              DetailRow(
                label: '关联实例',
                value: item.instanceId.isEmpty ? '—' : item.instanceId,
                mono: true,
                selectable: true,
              ),
              DetailRow(label: '实例名称', value: item.instanceName),
              DetailRow(
                label: '支付方式',
                value: FundMeta.payMethodText(item.payMethod),
              ),
              DetailRow(label: '原价', value: item.totalText),
              DetailRow(label: '优惠', value: '-${item.discountText}'),
              DetailRow(label: '结算价', value: item.settlementText),
              DetailRow(label: '代金券抵扣', value: '-${item.couponText}'),
              DetailRow(label: '余额支付', value: item.balancePayText),
              DetailRow(
                label: '账期开始',
                value: item.startTime.isEmpty ? '—' : item.startTime,
                selectable: true,
              ),
              DetailRow(
                label: '账期结束',
                value: item.endTime.isEmpty ? '—' : item.endTime,
                selectable: true,
              ),
              DetailRow(
                label: '出账时间',
                value: item.chargeTime.isEmpty ? '—' : item.chargeTime,
                selectable: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
