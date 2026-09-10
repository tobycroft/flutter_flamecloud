import 'package:flutter/material.dart';

/// 登录页标题区：主标题与欢迎副标题。
class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '账号密码登录',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          '欢迎回来，请登录您的账户',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
