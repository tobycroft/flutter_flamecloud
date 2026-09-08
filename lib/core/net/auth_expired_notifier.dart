/// 登录失效广播。
///
/// 网络层（core）只负责发出信号，具体清理动作由会话层（features）注册，
/// 避免 core 反向依赖 feature。
class AuthExpiredNotifier {
  void Function()? _handler;

  /// 注册登录失效处理器，重复注册会覆盖前一个。
  void register(void Function() handler) => _handler = handler;

  /// 取消注册。
  void unregister() => _handler = null;

  /// 发出登录失效信号。
  void notify() => _handler?.call();
}
