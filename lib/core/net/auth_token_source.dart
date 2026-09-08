/// 鉴权信息来源，由本地会话存储实现。
///
/// 后端 `HeaderAuthMode = true`，登录态通过平级的 `uid` / `token` 请求头传递，
/// 与 Vue 端 `getAuthHeaders()` 行为一致。
abstract interface class AuthTokenSource {
  /// 当前登录用户 id，未登录为 null。
  String? get uid;

  /// 当前登录 token，未登录为 null。
  String? get token;
}
