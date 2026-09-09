import '../../core/utils/json_value.dart';

/// AccessKey 访问密钥。
///
/// 对应 `GET /v1/user/access_key` 返回 data 数组中的元素，
/// 字段与 vue_flamecloud 的 AccessKey 接口定义保持一致。
class AccessKeyItem {
  const AccessKeyItem({
    required this.id,
    required this.accessKey,
    required this.name,
    required this.status,
    required this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从接口返回的元素构造。
  factory AccessKeyItem.fromMap(Map<String, dynamic> map) {
    return AccessKeyItem(
      id: JsonValue.integer(map['id']) ?? 0,
      accessKey: JsonValue.string(map['access_key']) ?? '',
      name: JsonValue.string(map['name']) ?? '',
      status: JsonValue.integer(map['status']) ?? 0,
      remark: JsonValue.string(map['remark']) ?? '',
      createdAt: JsonValue.string(map['created_at']) ?? '',
      updatedAt: JsonValue.string(map['updated_at']) ?? '',
    );
  }

  /// AK id。
  final int id;

  /// 访问密钥 Key。
  final String accessKey;

  /// 备注名。
  final String name;

  /// 状态：1=启用，0=禁用。
  final int status;

  /// 备注。
  final String remark;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 更新时间，后端返回的原始时间串。
  final String updatedAt;

  /// 是否启用。
  bool get enabled => status == 1;

  /// 展示用时间：ISO 串的 `T` 换成空格并截到秒。
  String get displayCreatedAt {
    final String text = createdAt.replaceFirst('T', ' ');
    return text.length > 19 ? text.substring(0, 19) : text;
  }
}

/// AccessKey 创建结果。
///
/// 后端仅在创建时返回一次 `access_secret`，之后无法再查询。
class AccessKeySecret {
  const AccessKeySecret({required this.accessKey, required this.accessSecret});

  /// 访问密钥 Key。
  final String accessKey;

  /// 访问密钥 Secret（仅此一次）。
  final String accessSecret;
}

/// AccessKey 调用日志。
///
/// 对应 `GET /v1/user/access_key/log` 与 `/log/all` 返回 data 数组中的元素
/// （裸数组，无 total/list 包裹）。
class AccessKeyLogItem {
  const AccessKeyLogItem({
    required this.id,
    required this.akId,
    required this.action,
    required this.detail,
    required this.ip,
    required this.createdAt,
  });

  /// 从接口返回的元素构造。
  factory AccessKeyLogItem.fromMap(Map<String, dynamic> map) {
    return AccessKeyLogItem(
      id: JsonValue.integer(map['id']) ?? 0,
      akId: JsonValue.integer(map['ak_id']) ?? 0,
      action: JsonValue.string(map['action']) ?? '',
      detail: JsonValue.string(map['detail']) ?? '',
      ip: JsonValue.string(map['ip']) ?? '',
      createdAt: JsonValue.string(map['created_at']) ?? '',
    );
  }

  /// 日志 id。
  final int id;

  /// 所属 AK id。
  final int akId;

  /// 操作类型：create / delete / permission / update。
  final String action;

  /// 详情文本。
  final String detail;

  /// 来源 IP。
  final String ip;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 展示用时间：ISO 串的 `T` 换成空格并截到秒。
  String get displayTime {
    final String text = createdAt.replaceFirst('T', ' ');
    return text.length > 19 ? text.substring(0, 19) : text;
  }
}
