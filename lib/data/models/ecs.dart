import '../../core/utils/json_value.dart';

/// 云服务器地域。
///
/// 对应 `GET /v1/ecs/config/regions` 返回的 data.list 元素，
/// 字段与 go_flamecloud 的 `fc_ecs_region` 表保持一致。
class EcsRegion {
  const EcsRegion({
    required this.id,
    required this.name,
    required this.value,
  });

  /// 从接口返回的元素构造。
  factory EcsRegion.fromMap(Map<String, dynamic> map) {
    return EcsRegion(
      id: JsonValue.integer(map['id']) ?? 0,
      name: JsonValue.string(map['name']) ?? '',
      value: JsonValue.string(map['value']) ?? '',
    );
  }

  /// 地域 id。
  final int id;

  /// 地域名称，如「华东1（杭州）」。
  final String name;

  /// 地域编码，下单时与后端约定的 `region` 字段值（如 `cn-hangzhou`）。
  final String value;
}

/// 云服务器可用区。
///
/// 对应 `GET /v1/ecs/config/zones` 返回的 data.list 元素。
class EcsZone {
  const EcsZone({required this.id, required this.name});

  /// 从接口返回的元素构造。
  factory EcsZone.fromMap(Map<String, dynamic> map) {
    return EcsZone(
      id: JsonValue.integer(map['id']) ?? 0,
      name: JsonValue.string(map['name']) ?? '',
    );
  }

  /// 可用区 id。
  final int id;

  /// 可用区名称，如「可用区A」。
  final String name;
}

/// 云服务器实例规格。
///
/// 对应 `GET /v1/ecs/config/specs` 返回的 data.list 元素。
/// 后端出于安全考虑已在响应中剔除单价字段，价格仅由 config/price 计算。
class EcsSpec {
  const EcsSpec({
    required this.id,
    required this.cpu,
    required this.memory,
  });

  /// 从接口返回的元素构造。
  factory EcsSpec.fromMap(Map<String, dynamic> map) {
    return EcsSpec(
      id: JsonValue.integer(map['id']) ?? 0,
      cpu: JsonValue.string(map['cpu']) ?? '',
      memory: JsonValue.string(map['memory']) ?? '',
    );
  }

  /// 规格 id。
  final int id;

  /// CPU 描述，如「2核」。
  final String cpu;

  /// 内存描述，如「4GB」。
  final String memory;

  /// 展示用的规格标题：CPU 与内存拼接。
  String get title => '$cpu $memory';
}

/// 购买周期与折扣配置。
///
/// 对应 `GET /v1/ecs/config/periods` 返回的 data.list 元素，
/// 折扣力度来自后端 `fc_ecs_period` 配置表，前端仅展示、不写死。
class EcsPeriod {
  const EcsPeriod({
    required this.month,
    required this.label,
    required this.discount,
  });

  /// 从接口返回的元素构造。
  factory EcsPeriod.fromMap(Map<String, dynamic> map) {
    return EcsPeriod(
      month: JsonValue.integer(map['month']) ?? 1,
      label: JsonValue.string(map['label']) ?? '',
      discount: JsonValue.decimal(map['discount']) ?? 1,
    );
  }

  /// 购买周期（月）。
  final int month;

  /// 展示文案，如「1年」。
  final String label;

  /// 折扣率，1 = 无优惠。
  final double discount;

  /// 折扣中文展示，如 0.95 -> 9.5折；无优惠时返回空串。
  String get discountText {
    if (discount >= 1) {
      return '';
    }
    final double z = (discount * 10 * 100).round() / 100;
    final String text = z == z.roundToDouble() ? z.toInt().toString() : z.toString();
    return '$text折';
  }
}

/// ECS 配置总价（由后端 config/price 接口计算，前端仅展示）。
class EcsPrice {
  const EcsPrice({
    required this.specPrice,
    required this.diskPrice,
    required this.bandwidthPrice,
    required this.imagePrice,
    required this.imageRemark,
    required this.monthlyBase,
    required this.purchaseCount,
    required this.purchasePeriod,
    required this.originalPrice,
    required this.discountRate,
    required this.totalPrice,
  });

  /// 从接口返回的 data 构造。
  factory EcsPrice.fromMap(Map<String, dynamic> map) {
    return EcsPrice(
      specPrice: JsonValue.string(map['spec_price']) ?? '0.00',
      diskPrice: JsonValue.string(map['disk_price']) ?? '0.00',
      bandwidthPrice: JsonValue.string(map['bandwidth_price']) ?? '0.00',
      imagePrice: JsonValue.string(map['image_price']) ?? '0.00',
      imageRemark: JsonValue.string(map['image_remark']) ?? '',
      monthlyBase: JsonValue.string(map['monthly_base']) ?? '0.00',
      purchaseCount: JsonValue.integer(map['purchase_count']) ?? 1,
      purchasePeriod: JsonValue.integer(map['purchase_period']) ?? 1,
      originalPrice: JsonValue.string(map['original_price']) ?? '0.00',
      discountRate: JsonValue.string(map['discount_rate']) ?? '1',
      totalPrice: JsonValue.string(map['total_price']) ?? '0.00',
    );
  }

  /// 规格费（每月）。
  final String specPrice;

  /// 数据盘费（每月）。
  final String diskPrice;

  /// 带宽费（每月）。
  final String bandwidthPrice;

  /// 镜像费（一次性）。
  final String imagePrice;

  /// 收费镜像的备注提示（如 Windows 镜像：需要增加费用）。
  final String imageRemark;

  /// 每月基础费用 = 规格 + 数据盘 + 带宽 + 镜像。
  final String monthlyBase;

  /// 购买数量。
  final int purchaseCount;

  /// 购买周期（月）。
  final int purchasePeriod;

  /// 原价（未折扣）。
  final String originalPrice;

  /// 折扣率，字符串形式（如 "0.95"）。
  final String discountRate;

  /// 实付总价。
  final String totalPrice;

  /// 是否存在有效折扣（0 < rate < 1）。
  bool get hasDiscount {
    final double? rate = JsonValue.decimal(discountRate);
    return rate != null && rate > 0 && rate < 1;
  }
}

/// ECS 订单。
///
/// 对应 `POST /v1/ecs/order/create` 与 `POST /v1/ecs/order/detail` 的 data。
class EcsOrder {
  const EcsOrder({
    required this.id,
    required this.orderNo,
    required this.amount,
    required this.status,
    required this.remark,
  });

  /// 从接口返回的 data 构造。
  factory EcsOrder.fromMap(Map<String, dynamic> map) {
    return EcsOrder(
      id: JsonValue.integer(map['id']) ?? 0,
      orderNo: JsonValue.string(map['order_no']) ?? '',
      amount: JsonValue.string(map['amount']) ?? '0.00',
      status: JsonValue.integer(map['status']) ?? 0,
      remark: JsonValue.string(map['remark']) ?? '',
    );
  }

  /// 订单 id。
  final int id;

  /// 订单号，形如 `ECS202509111030001234`。
  final String orderNo;

  /// 金额，后端返回的原始串。
  final String amount;

  /// 订单状态：0 待支付、1 已支付、2 已取消。
  final int status;

  /// 备注。
  final String remark;

  /// 状态中文。
  String get statusText => switch (status) {
        0 => '待支付',
        1 => '已支付',
        2 => '已取消',
        _ => '未知',
      };
}

/// ECS 支付结果。
///
/// 对应 `POST /v1/ecs/order/pay` 的 data；余额支付直接成功，
/// 支付宝等第三方支付返回 `pay_url` 由客户端拉起。
class EcsPayResult {
  const EcsPayResult({
    required this.orderId,
    required this.orderNo,
    required this.amount,
    required this.payMethod,
    required this.status,
    this.payUrl,
  });

  /// 从接口返回的 data 构造。
  factory EcsPayResult.fromMap(Map<String, dynamic> map) {
    return EcsPayResult(
      orderId: JsonValue.integer(map['order_id']) ?? 0,
      orderNo: JsonValue.string(map['order_no']) ?? '',
      amount: JsonValue.string(map['amount']) ?? '0.00',
      payMethod: JsonValue.string(map['pay_method']) ?? '',
      status: JsonValue.integer(map['status']) ?? 0,
      payUrl: JsonValue.string(map['pay_url']),
    );
  }

  /// 订单 id。
  final int orderId;

  /// 订单号。
  final String orderNo;

  /// 金额。
  final String amount;

  /// 支付方式。
  final String payMethod;

  /// 支付后状态。
  final int status;

  /// 第三方支付跳转地址，余额支付时为 null。
  final String? payUrl;
}

/// 购买表单中的数据盘条目（UI 层状态，不直接对应接口字段）。
class EcsDataDisk {
  const EcsDataDisk({
    required this.id,
    required this.size,
    required this.type,
  });

  /// 列表内唯一标识（用于 Widget key）。
  final int id;

  /// 容量（GB）。
  final int size;

  /// 类型，如「性能型」「容量型」「SSD云盘」。
  final String type;

  /// 复制出新条目。
  EcsDataDisk copyWith({int? size, String? type}) {
    return EcsDataDisk(
      id: id,
      size: size ?? this.size,
      type: type ?? this.type,
    );
  }
}
