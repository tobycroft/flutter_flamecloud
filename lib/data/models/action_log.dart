import '../../core/utils/json_value.dart';

/// 操作日志类型字典项。
///
/// 对应 `GET /v1/actionlog/type` 返回 data 数组中的元素，
/// `code` 用于前端映射颜色（user / system / ak / login / security）。
class ActionLogType {
  const ActionLogType({
    required this.id,
    required this.name,
    required this.code,
  });

  /// 从接口返回的元素构造。
  factory ActionLogType.fromMap(Map<String, dynamic> map) {
    return ActionLogType(
      id: JsonValue.integer(map['id']) ?? 0,
      name: JsonValue.string(map['name']) ?? '',
      code: JsonValue.string(map['code']) ?? '',
    );
  }

  /// 类型 id。
  final int id;

  /// 类型中文名，如「用户」「系统」。
  final String name;

  /// 类型标识码。
  final String code;
}

/// 操作日志。
///
/// 对应 `GET /v1/actionlog/list` 返回 data.list 中的元素，
/// data 结构为 `{ list: [...], total: n }`（真分页）。
class ActionLogItem {
  const ActionLogItem({
    required this.id,
    required this.uid,
    required this.logTypeId,
    required this.action,
    required this.detail,
    required this.ip,
    required this.deviceType,
    required this.createdAt,
  });

  /// 从接口返回的元素构造。
  factory ActionLogItem.fromMap(Map<String, dynamic> map) {
    return ActionLogItem(
      id: JsonValue.integer(map['id']) ?? 0,
      uid: JsonValue.integer(map['uid']) ?? 0,
      logTypeId: JsonValue.integer(map['log_type_id']) ?? 0,
      action: JsonValue.string(map['action']) ?? '',
      detail: JsonValue.string(map['detail']) ?? '',
      ip: JsonValue.string(map['ip']) ?? '',
      deviceType: JsonValue.string(map['device_type']),
      createdAt: JsonValue.string(map['created_at']) ?? '',
    );
  }

  /// 日志 id。
  final int id;

  /// 操作用户 id。
  final int uid;

  /// 日志类型 id，对应 [ActionLogType.id]。
  final int logTypeId;

  /// 操作描述文本。
  final String action;

  /// 详情文本。
  final String detail;

  /// 来源 IP。
  final String ip;

  /// 设备类型：web / android / ios，仅登录日志有值。
  final String? deviceType;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 展示用时间：ISO 串的 `T` 换成空格并截到秒。
  String get displayTime {
    final String text = createdAt.replaceFirst('T', ' ');
    return text.length > 19 ? text.substring(0, 19) : text;
  }
}

/// 操作日志分页结果。
class ActionLogPage {
  const ActionLogPage({required this.items, required this.total});

  /// 当前页日志列表。
  final List<ActionLogItem> items;

  /// 总条数。
  final int total;
}
