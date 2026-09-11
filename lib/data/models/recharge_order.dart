import '../../core/utils/json_value.dart';

/// 充值订单。
///
/// 对应 `GET /v1/user/recharge/orders` 返回 data.list 中的元素，
/// 字段与 go_flamecloud 的 `fc_recharge_order` 表保持一致。
class RechargeOrderItem {
  const RechargeOrderItem({
    required this.id,
    required this.orderNo,
    required this.amount,
    required this.payMethod,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.remitTime,
    required this.remark,
  });

  /// 从接口返回的元素构造。
  factory RechargeOrderItem.fromMap(Map<String, dynamic> map) {
    return RechargeOrderItem(
      id: JsonValue.integer(map['id']) ?? 0,
      orderNo: JsonValue.string(map['order_no']) ?? '',
      amount: JsonValue.string(map['amount']) ?? '0',
      payMethod: JsonValue.string(map['pay_method']) ?? '',
      type: JsonValue.integer(map['type']) ?? 1,
      status: JsonValue.integer(map['status']) ?? 0,
      createdAt: JsonValue.string(map['created_at']) ?? '',
      remitTime: JsonValue.string(map['remit_time']) ?? '',
      remark: JsonValue.string(map['remark']) ?? '',
    );
  }

  /// 订单 id。
  final int id;

  /// 订单号，形如 `CZ202509111030001234`。
  final String orderNo;

  /// 充值金额，后端返回的原始串。
  final String amount;

  /// 支付方式：alipay / wechat / bank_transfer / alipay_transfer / wechat_transfer。
  final String payMethod;

  /// 订单来源：1 在线充值、2 线下充值。
  final int type;

  /// 订单状态：0 待支付、1 已完成、2 已取消、3 审核中、4 已失败。
  final int status;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 线下充值的汇款时间，在线充值为空。
  final String remitTime;

  /// 用户备注，仅线下充值可能有值。
  final String remark;

  /// 展示用时间：ISO 串的 `T` 换成空格并截到秒。
  String get displayTime => _formatTime(createdAt);

  /// 展示用汇款时间，未填写时为空串。
  String get remitTimeText => _formatTime(remitTime);

  /// 金额展示：固定两位小数，无法解析时回退原始串。
  String get amountText {
    final double? value = JsonValue.decimal(amount);
    return value == null ? amount : value.toStringAsFixed(2);
  }
}

/// 充值订单分页结果。
class RechargeOrderResult {
  const RechargeOrderResult({required this.items, required this.total});

  /// 当前页订单。
  final List<RechargeOrderItem> items;

  /// 总条数。
  final int total;
}

/// 时间串的 `T` 换成空格并截到秒，空串原样返回。
String _formatTime(String raw) {
  if (raw.isEmpty) {
    return '';
  }
  final String text = raw.replaceFirst('T', ' ');
  return text.length > 19 ? text.substring(0, 19) : text;
}
