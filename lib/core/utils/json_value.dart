/// JSON 取值工具。
///
/// 后端字段类型不稳定（例如 id 有时是 int、有时是 string），统一做容错转换。
class JsonValue {
  const JsonValue._();

  /// 取字符串，null 或空串返回 null。
  static String? string(Object? value) {
    if (value == null) {
      return null;
    }
    final String text = value is String ? value : value.toString();
    return text.isEmpty ? null : text;
  }

  /// 取整数。
  static int? integer(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? num.tryParse(value)?.toInt();
    }
    return null;
  }

  /// 取小数。
  static double? decimal(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// 取布尔。
  static bool? boolean(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String text = value.toLowerCase();
      if (text == 'true' || text == '1') {
        return true;
      }
      if (text == 'false' || text == '0') {
        return false;
      }
    }
    return null;
  }
}
