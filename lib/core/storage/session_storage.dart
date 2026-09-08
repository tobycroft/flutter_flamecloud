import 'package:shared_preferences/shared_preferences.dart';

import '../net/auth_token_source.dart';

/// 登录态本地存储。
///
/// 对应 Vue 端的 `localStorage`（`uid` / `token`），并实现 [AuthTokenSource]
/// 供网络层注入鉴权请求头。
class SessionStorage implements AuthTokenSource {
  SessionStorage(this._prefs)
      : _uid = _prefs.getString(_keyUid),
        _token = _prefs.getString(_keyToken);

  final SharedPreferences _prefs;

  /// 用户 id 的键名，与 Vue 端保持一致。
  static const String _keyUid = 'uid';

  /// 登录 token 的键名，与 Vue 端保持一致。
  static const String _keyToken = 'token';

  /// 「记住我」保存的用户名键名。
  static const String _keyRememberedUsername = 'remembered_username';

  String? _uid;
  String? _token;

  @override
  String? get uid => _uid;

  @override
  String? get token => _token;

  /// 是否存在完整登录态。
  bool get hasSession {
    final String? u = _uid;
    final String? t = _token;
    return u != null && u.isNotEmpty && t != null && t.isNotEmpty;
  }

  /// 「记住我」保存的用户名，未开启时为空。
  String? get rememberedUsername => _prefs.getString(_keyRememberedUsername);

  /// 写入登录态。
  Future<void> saveSession({required String uid, required String token}) async {
    _uid = uid;
    _token = token;
    await _prefs.setString(_keyUid, uid);
    await _prefs.setString(_keyToken, token);
  }

  /// 清除登录态。
  ///
  /// 注意：Vue 端退出登录使用 `localStorage.clear()`，会连带清掉主题偏好；
  /// 这里只清除登录相关键，避免影响主题等其它偏好设置。
  Future<void> clearSession() async {
    _uid = null;
    _token = null;
    await _prefs.remove(_keyUid);
    await _prefs.remove(_keyToken);
  }

  /// 写入「记住我」的用户名。
  Future<void> saveRememberedUsername(String username) =>
      _prefs.setString(_keyRememberedUsername, username);

  /// 清除「记住我」的用户名。
  Future<void> clearRememberedUsername() =>
      _prefs.remove(_keyRememberedUsername);
}
