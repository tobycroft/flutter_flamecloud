import 'package:flutter/material.dart';

import '../../core/utils/json_value.dart';

/// 账单条目。
///
/// 对应 `GET /v1/user/bill/list` 返回 data.list 中的元素，
/// 字段与 go_flamecloud 的 `fc_bill` 表保持一致。
/// 每条账单按计费模块（cpu/memory/disk/bandwidth）出账，金额拆为
/// 原价 / 优惠 / 结算价 / 代金券 / 余额支付。
class BillItem {
  const BillItem({
    required this.id,
    required this.billNo,
    required this.billingPeriod,
    required this.product,
    required this.instanceId,
    required this.instanceName,
    required this.moduleType,
    required this.payMethod,
    required this.totalPrice,
    required this.discountAmount,
    required this.settlementPrice,
    required this.couponAmount,
    required this.balancePay,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.chargeTime,
  });

  /// 从接口返回的元素构造。
  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: JsonValue.integer(map['id']) ?? 0,
      billNo: JsonValue.string(map['bill_no']) ?? '',
      billingPeriod: JsonValue.string(map['billing_period']) ?? '',
      product: JsonValue.string(map['product']) ?? '',
      instanceId: JsonValue.string(map['instance_id']) ?? '',
      instanceName: JsonValue.string(map['instance_name']) ?? '',
      moduleType: JsonValue.string(map['module_type']) ?? '',
      payMethod: JsonValue.string(map['pay_method']) ?? '',
      totalPrice: JsonValue.string(map['total_price']) ?? '0',
      discountAmount: JsonValue.string(map['discount_amount']) ?? '0',
      settlementPrice: JsonValue.string(map['settlement_price']) ?? '0',
      couponAmount: JsonValue.string(map['coupon_amount']) ?? '0',
      balancePay: JsonValue.string(map['balance_pay']) ?? '0',
      status: JsonValue.integer(map['status']) ?? 0,
      startTime: JsonValue.string(map['start_time']) ?? '',
      endTime: JsonValue.string(map['end_time']) ?? '',
      chargeTime: JsonValue.string(map['charge_time']) ?? '',
    );
  }

  /// 账单 id。
  final int id;

  /// 账单编码，形如 `ZD202509111030001234`。
  final String billNo;

  /// 账期，形如 `2026-09`。
  final String billingPeriod;

  /// 产品，如 `云服务器ECS`。
  final String product;

  /// 关联实例 id。
  final String instanceId;

  /// 关联实例名称。
  final String instanceName;

  /// 计费模块：cpu / memory / disk / bandwidth。
  final String moduleType;

  /// 支付方式：balance 等。
  final String payMethod;

  /// 原价。
  final String totalPrice;

  /// 优惠金额。
  final String discountAmount;

  /// 结算价（原价 - 优惠）。
  final String settlementPrice;

  /// 代金券抵扣。
  final String couponAmount;

  /// 余额支付金额。
  final String balancePay;

  /// 状态：0 未出账、1 已出账。
  final int status;

  /// 账期开始时间。
  final String startTime;

  /// 账期结束时间。
  final String endTime;

  /// 出账时间。
  final String chargeTime;

  /// 状态文案。
  String get statusText => status == 1 ? '已出账' : '未出账';

  /// 状态配色。
  Color get statusColor =>
      status == 1 ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF);

  /// 计费模块文案。
  String get moduleText => switch (moduleType) {
        'cpu' => 'CPU 计算',
        'memory' => '内存',
        'disk' => '系统盘',
        'bandwidth' => '带宽',
        _ => moduleType.isEmpty ? '未知模块' : moduleType,
      };

  /// 金额展示：固定两位小数并加 ¥，无法解析时回退原始串。
  String priceText(String raw) {
    final double? value = JsonValue.decimal(raw);
    return value == null ? raw : '¥${value.toStringAsFixed(2)}';
  }

  /// 原价展示。
  String get totalText => priceText(totalPrice);

  /// 优惠展示。
  String get discountText => priceText(discountAmount);

  /// 结算价展示。
  String get settlementText => priceText(settlementPrice);

  /// 代金券抵扣展示。
  String get couponText => priceText(couponAmount);

  /// 余额支付展示。
  String get balancePayText => priceText(balancePay);
}
