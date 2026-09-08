import 'dart:convert';
import 'dart:typed_data';

import '../../core/utils/json_value.dart';

/// 图形验证码。
///
/// 对应 Vue 端 `data:image/gif;base64,` + `result.data.image`，
/// 后端返回的是 GIF 二进制的标准 base64（不含 data URI 前缀）。
class Captcha {
  const Captcha({
    required this.ident,
    required this.imageBase64,
  });

  /// 从接口 data 构造。
  factory Captcha.fromMap(Map<String, dynamic> map) {
    return Captcha(
      ident: JsonValue.string(map['ident']) ?? '',
      imageBase64: JsonValue.string(map['image']) ?? '',
    );
  }

  /// 验证码标识，登录时与用户输入一起回传。
  final String ident;

  /// 图片 base64 内容。
  final String imageBase64;

  /// 是否有效。
  bool get isValid => ident.isNotEmpty && imageBase64.isNotEmpty;

  /// 解码图片字节，base64 非法时返回 null。
  Uint8List? decodeImageBytes() {
    try {
      return base64Decode(imageBase64);
    } on FormatException {
      return null;
    }
  }
}
