import '../../core/utils/json_value.dart';

/// 余额流水。
///
/// 对应 `GET /v1/user/balance/log` 返回 data.list 中的元素，
/// 字段与 go_flamecloud 的 `fc_balance_record` 表保持一致。
class BalanceLogItem {
  const BalanceLogItem({
    required this.id,
    required this.type,
    required this.orderNo,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  /// 从接口返回的元素构造。
  factory BalanceLogItem.fromMap(Map<String, dynamic> map) {
    return BalanceLogItem(
      id: JsonValue.integer(map['id']) ?? 0,
      type: JsonValue.integer(map['type']) ?? 0,
      orderNo: JsonValue.string(map['order_no']) ?? '',
      amount: JsonValue.string(map['amount']) ?? '0',
      balanceAfter: JsonValue.string(map['balance_after']) ?? '0',
      description: JsonValue.string(map['description']) ?? '',
      createdAt: JsonValue.string(map['created_at']) ?? '',
    );
  }

  /// 流水 id。
  final int id;

  /// 流水类型：1 充值、2 消费、3 退款、4 系统调整。
  final int type;

  /// 关联订单号，非订单流水为空串。
  final String orderNo;

  /// 变动金额（无符号），后端返回的原始串。
  final String amount;

  /// 变动后余额，后端返回的原始串。
  final String balanceAfter;

  /// 流水描述。
  final String description;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 展示用时间：ISO 串的 `T` 换成空格并截到秒。
  String get displayTime {
    final String text = createdAt.replaceFirst('T', ' ');
    return text.length > 19 ? text.substring(0, 19) : text;
  }

  /// 变动金额展示：固定两位小数。
  String get amountText => _fixed(amount);

  /// 变动后余额展示：固定两位小数。
  String get balanceAfterText => _fixed(balanceAfter);
}

/// 余额流水分页结果。
class BalanceLogResult {
  const BalanceLogResult({required this.items, required this.total});

  /// 当前页流水。
  final List<BalanceLogItem> items;

  /// 总条数。
  final int total;
}

/// 账户余额概览。
///
/// 对应 `GET /v1/user/balance` 返回的 data，
/// 用于资金管理页顶部的余额卡片。
class BalanceSummary {
  const BalanceSummary({
    required this.balance,
    required this.frozen,
    required this.totalRecharge,
    required this.totalConsume,
  });

  /// 从接口返回的 data 构造。
  factory BalanceSummary.fromMap(Map<String, dynamic> map) {
    return BalanceSummary(
      balance: JsonValue.string(map['balance']) ?? '0.00',
      frozen: JsonValue.string(map['frozen']) ?? '0.00',
      totalRecharge: JsonValue.string(map['total_recharge']) ?? '0.00',
      totalConsume: JsonValue.string(map['total_consume']) ?? '0.00',
    );
  }

  /// 当前可用余额。
  final String balance;

  /// 冻结金额。
  final String frozen;

  /// 累计充值（含退款）。
  final String totalRecharge;

  /// 累计消费。
  final String totalConsume;

  /// 余额展示：固定两位小数。
  String get balanceText => _fixed(balance);

  /// 累计充值展示：固定两位小数。
  String get totalRechargeText => _fixed(totalRecharge);

  /// 累计消费展示：固定两位小数。
  String get totalConsumeText => _fixed(totalConsume);
}

/// 金额串固定两位小数，无法解析时回退原始串。
String _fixed(String raw) {
  final double? value = JsonValue.decimal(raw);
  return value == null ? raw : value.toStringAsFixed(2);
}
