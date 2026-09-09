import 'package:flutter/material.dart';

import '../../features/ak/ak_log_page.dart';
import '../../features/ak/ak_manage_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/console/console_shell_page.dart';
import '../../features/log/action_log_page.dart';
import '../../features/support/support_chat_page.dart';

/// 路由名称。
class AppRoutes {
  const AppRoutes._();

  /// 登录页。
  static const String login = '/login';

  /// 控制台，即底部导航外壳页。
  static const String console = '/console';

  /// 在线客服聊天页。
  static const String supportChat = '/support/chat';

  /// AK 管理页。
  static const String akManage = '/ak/manage';

  /// AK 调用日志页（全部 AK）。
  static const String akLogs = '/ak/logs';

  /// 操作日志页。
  static const String actionLog = '/logs/action';
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
          builder: (_) => const ConsoleShellPage(),
        );
      case AppRoutes.supportChat:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SupportChatPage(),
        );
      case AppRoutes.akManage:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AkManagePage(),
        );
      case AppRoutes.akLogs:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AkLogPage(),
        );
      case AppRoutes.actionLog:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ActionLogPage(),
        );
      default:
        return null;
    }
  }
}
