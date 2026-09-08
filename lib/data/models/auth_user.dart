import '../../core/utils/json_value.dart';

/// 登录成功返回的用户信息。
///
/// 对应 `POST /v1/user/login` 的 data：
/// `{ id, username, phone, email, token }`。
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.token,
    this.phone,
    this.email,
  });

  /// 从接口 data 构造。
  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: JsonValue.string(map['id']) ?? '',
      username: JsonValue.string(map['username']) ?? '',
      token: JsonValue.string(map['token']) ?? '',
      phone: JsonValue.string(map['phone']),
      email: JsonValue.string(map['email']),
    );
  }

  /// 用户 id，后端可能返回 int 或 string。
  final String id;

  /// 用户名。
  final String username;

  /// 登录 token。
  final String token;

  /// 手机号。
  final String? phone;

  /// 邮箱。
  final String? email;

  /// 是否可用（登录成功必须拿到 id 与 token）。
  bool get isValid => id.isNotEmpty && token.isNotEmpty;

  /// 用于顶部展示的昵称。
  String get displayName => username.isNotEmpty
      ? username
      : (phone ?? email ?? id);
}
