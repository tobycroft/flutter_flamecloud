import '../../core/utils/json_value.dart';

/// 用户详细资料。
///
/// 对应 `GET /v1/user/info` 的 data，`fc_user_info` 全量字段 +
/// `username` / `phone` / `email` / `balance` / `last_login_time`。
class UserInfo {
  const UserInfo({
    this.uid,
    this.name,
    this.username,
    this.phone,
    this.email,
    this.avatar,
    this.company,
    this.department,
    this.balance,
    this.lastLoginTime,
    this.createdAt,
    this.updatedAt,
  });

  /// 从接口 data 构造。
  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      uid: JsonValue.string(map['uid']),
      name: JsonValue.string(map['name']),
      username: JsonValue.string(map['username']),
      phone: JsonValue.string(map['phone']),
      email: JsonValue.string(map['email']),
      avatar: JsonValue.string(map['avatar']),
      company: JsonValue.string(map['company']),
      department: JsonValue.string(map['department']),
      balance: JsonValue.string(map['balance']),
      lastLoginTime: JsonValue.string(map['last_login_time']),
      createdAt: JsonValue.string(map['created_at']),
      updatedAt: JsonValue.string(map['updated_at']),
    );
  }

  /// 用户 id。
  final String? uid;

  /// 姓名。
  final String? name;

  /// 用户名。
  final String? username;

  /// 手机号。
  final String? phone;

  /// 邮箱。
  final String? email;

  /// 头像地址。
  final String? avatar;

  /// 公司。
  final String? company;

  /// 部门。
  final String? department;

  /// 账户余额，后端返回两位小数字符串。
  final String? balance;

  /// 最近登录时间。
  final String? lastLoginTime;

  /// 创建时间。
  final String? createdAt;

  /// 更新时间。
  final String? updatedAt;

  /// 展示用昵称，与 Vue AppHeader 的取值顺序保持一致：
  /// name -> username -> phone -> email。
  String get displayName {
    final String? nickname = name;
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    final String? account = username;
    if (account != null && account.isNotEmpty) {
      return account;
    }
    final String? mobile = phone;
    if (mobile != null && mobile.isNotEmpty) {
      return mobile;
    }
    final String? mail = email;
    if (mail != null && mail.isNotEmpty) {
      return mail;
    }
    return uid ?? '';
  }
}
