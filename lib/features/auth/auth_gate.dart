import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../console/console_shell_page.dart';
import 'login_page.dart';
import 'session_controller.dart';
import 'splash/splash_page.dart';

/// 登录态路由闸门。
///
/// 启动恢复期间展示闪屏，恢复完成后按登录态切换到控制台或登录页。
/// （Vue 端没有路由守卫，/console 可匿名访问；这里在客户端补上拦截。）
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SessionSnapshot?> session =
        ref.watch(sessionControllerProvider);

    return session.when(
      data: (SessionSnapshot? snapshot) =>
          snapshot == null ? const LoginPage() : const ConsoleShellPage(),
      loading: () => const SplashPage(),
      error: (Object error, StackTrace stackTrace) => const LoginPage(),
    );
  }
}
