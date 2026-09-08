/// 业务异常。
///
/// 由 [ApiEnvelope] 中非 0 的 `code` 转换而来，`message` 取后端 `echo`。
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  /// 业务码。
  final int code;

  /// 展示给用户的提示语。
  final String message;

  /// 登录失效（后端 code = -1）。
  bool get isAuthExpired => code == -1;

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}

/// 网络异常，封装连接超时、断网等场景的可读文案。
class NetworkException implements Exception {
  const NetworkException(this.message);

  /// 展示给用户的提示语。
  final String message;

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// 响应结构异常，接口未返回约定的 `{ code, data, echo }`。
class ApiFormatException implements Exception {
  const ApiFormatException();

  /// 展示给用户的提示语。
  String get message => '服务返回数据格式异常';

  @override
  String toString() => 'ApiFormatException()';
}
