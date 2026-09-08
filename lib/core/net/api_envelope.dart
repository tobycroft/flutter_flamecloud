/// 后端统一响应包。
///
/// 后端 `tuuz/RET` 固定输出 `{ code: int, data: any, echo: string }`，
/// 且 HTTP 状态码恒为 200，业务状态只看 `code`；`data` 为 nil 时会变成 `[]`。
class ApiEnvelope {
  const ApiEnvelope({
    required this.code,
    required this.echo,
    required this.data,
  });

  /// 从已解码的 JSON 对象构造。
  factory ApiEnvelope.fromMap(Map<dynamic, dynamic> map) {
    return ApiEnvelope(
      code: _asInt(map['code']),
      echo: (map['echo'] ?? '').toString(),
      data: map['data'],
    );
  }

  /// 业务码，0 表示成功。
  final int code;

  /// 后端提示语，失败时直接展示给用户。
  final String echo;

  /// 业务数据，可能为 Map、List 或基础类型。
  final Object? data;

  /// 是否成功。
  bool get isSuccess => code == 0;

  /// 是否已登录失效（后端返回 -1）。
  bool get isAuthExpired => code == -1;

  /// 以 Map 形式读取数据，类型不匹配时返回 null。
  Map<String, dynamic>? get asMap {
    final Object? value = data;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// 以 List 形式读取数据，类型不匹配时返回 null。
  List<dynamic>? get asList {
    final Object? value = data;
    if (value is List) {
      return List<dynamic>.from(value);
    }
    return null;
  }

  /// 以字符串形式读取数据。
  String? get asString => data?.toString();

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? -1;
    }
    return -1;
  }
}
