import 'dart:convert';
import 'dart:typed_data';

import '../../core/utils/json_value.dart';

/// 图形验证码。
///
/// 后端返回的是 GIF 二进制的标准 base64（不含 data URI 前缀），
/// 通常为多帧动图（约 4 帧，每帧约 1 秒）。
class Captcha {
  Captcha({
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

  Uint8List? _decodedBytes;

  /// 是否有效。
  bool get isValid => ident.isNotEmpty && imageBase64.isNotEmpty;

  /// 解码图片字节，base64 非法时返回 null。
  ///
  /// 结果会被缓存为同一 [Uint8List] 实例：Flutter 的 [MemoryImage] 通过
  /// `other.bytes == bytes`（Uint8List 未重写 ==，即实例身份）判断相等，
  /// 若每次 build 都重新解码产生新实例，[Image] 会反复重新解码并重启
  /// 动画，导致 GIF 看起来永远停在第一帧。
  Uint8List? decodeImageBytes() {
    final Uint8List? cached = _decodedBytes;
    if (cached != null) {
      return cached;
    }
    try {
      final Uint8List bytes = base64Decode(imageBase64);
      _decodedBytes = bytes;
      return bytes;
    } on FormatException {
      return null;
    }
  }
}
