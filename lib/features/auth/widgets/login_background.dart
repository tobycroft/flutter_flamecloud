import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/fade_slide_in.dart';

/// 登录页背景。
///
/// 对齐 Vue 登录页的三团光斑 + 渐变底色（`.login-bg-orb` + animejs stagger）。
class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.loginBackgroundDark
              : AppColors.loginBackgroundLight,
        ),
        child: Stack(
          children: <Widget>[
            _Orb(
              alignment: const Alignment(-1.1, -0.45),
              size: 384,
              color: AppColors.flame400.withValues(alpha: 0.10),
              delay: const Duration(milliseconds: 0),
            ),
            _Orb(
              alignment: const Alignment(1.1, 0.45),
              size: 384,
              color: AppColors.orange500.withValues(alpha: 0.10),
              delay: const Duration(milliseconds: 200),
            ),
            _Orb(
              alignment: Alignment.center,
              size: 800,
              color: AppColors.flame500.withValues(alpha: 0.05),
              delay: const Duration(milliseconds: 400),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.alignment,
    required this.size,
    required this.color,
    required this.delay,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FadeSlideIn(
        delay: delay,
        duration: const Duration(milliseconds: 1200),
        beginOffset: Offset.zero,
        beginScale: 0.8,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}
