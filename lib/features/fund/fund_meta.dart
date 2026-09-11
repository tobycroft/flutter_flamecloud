import 'package:flutter/material.dart';

/// 资金管理展示元数据：充值订单状态、支付方式、余额流水类型的文案与配色。
///
/// 集中搬迁自 vue_flamecloud 的 RechargeOrdersPage 与 BalanceLogPage
/// 中重复的 statusMap / payMethodMap / typeMap，供资金管理页各板块复用。
class FundMeta {
  const FundMeta._();

  /// 充值订单状态文案：0 待支付、1 已完成、2 已取消、3 审核中、4 已失败。
  static String orderStatusText(int status) => switch (status) {
    0 => '待支付',
    1 => '已完成',
    2 => '已取消',
    3 => '审核中',
    4 => '已失败',
    _ => '未知',
  };

  /// 充值订单状态配色，对齐 Vue 端 badge（黄/绿/灰/蓝/红）。
  static Color orderStatusColor(int status) => switch (status) {
    0 => const Color(0xFFCA8A04),
    1 => const Color(0xFF16A34A),
    2 => const Color(0xFF9CA3AF),
    3 => const Color(0xFF2563EB),
    4 => const Color(0xFFDC2626),
    _ => const Color(0xFF9CA3AF),
  };

  /// 支付方式文案，未命中时原样返回。
  static String payMethodText(String method) => switch (method) {
    'alipay' => '支付宝',
    'wechat' => '微信支付',
    'bank_transfer' => '银行转账',
    'alipay_transfer' => '支付宝转账',
    'wechat_transfer' => '微信转账',
    _ => method.isEmpty ? '未知方式' : method,
  };

  /// 余额流水类型文案：1 充值、2 消费、3 退款、4 系统调整。
  static String balanceTypeText(int type) => switch (type) {
    1 => '充值',
    2 => '消费',
    3 => '退款',
    4 => '系统调整',
    _ => '未知',
  };

  /// 余额流水类型配色：充值/退款绿、消费红、系统调整蓝。
  static Color balanceTypeColor(int type) => switch (type) {
    1 || 3 => const Color(0xFF16A34A),
    2 => const Color(0xFFDC2626),
    4 => const Color(0xFF2563EB),
    _ => const Color(0xFF6B7280),
  };

  /// 余额流水类型图标，对齐 Vue 端 TrendingUp / TrendingDown / Wallet。
  static IconData balanceTypeIcon(int type) => switch (type) {
    1 || 3 => Icons.trending_up,
    2 => Icons.trending_down,
    4 => Icons.account_balance_wallet_outlined,
    _ => Icons.receipt_long_outlined,
  };

  /// 是否为收入类流水（充值 / 退款 / 系统调整），用于金额正负号与配色。
  static bool balanceTypeIsIncome(int type) => type != 2;
}
