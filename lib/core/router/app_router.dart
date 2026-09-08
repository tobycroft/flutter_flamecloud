import 'package:flutter/material.dart';

import '../../features/auth/login_page.dart';
import '../../features/console/console_page.dart';

/// 路由名称。
class AppRoutes {
  const AppRoutes._();

  /// 登录页。
  static const String login = '/login';

  /// 控制台。
  static const String console = '/console';
}

/// 命名路由表。
///
/// 当前主入口由 AuthGate 控制，这里为后续控制台内页跳转预留。
class AppRouter {
  const AppRouter._();

  /// 生成路由。
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginPage(),
        );
      case AppRoutes.console:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ConsolePage(),
        );
      default:
        return null;
    }
  }
}
