import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../data/models/captcha.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/captcha_field.dart';
import '../widgets/gradient_button.dart';

/// 登录卡片：错误提示、账号/密码/验证码输入、记住我、登录按钮与注册入口。
class LoginCard extends StatelessWidget {
  const LoginCard({
    required this.errorMessage,
    required this.submitting,
    required this.captcha,
    required this.captchaLoading,
    required this.obscurePassword,
    required this.rememberMe,
    required this.usernameController,
    required this.passwordController,
    required this.codeController,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onRefreshCaptcha,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onRegister,
    super.key,
  });

  final String? errorMessage;
  final bool submitting;
  final Captcha? captcha;
  final bool captchaLoading;
  final bool obscurePassword;
  final bool rememberMe;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController codeController;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onRefreshCaptcha;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: isDark ? 0.85 : 1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFF3F4F6),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFFE5E7EB).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: errorMessage == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: AuthErrorBanner(message: errorMessage!),
                  ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 700),
            duration: const Duration(milliseconds: 600),
            beginOffset: const Offset(-0.08, 0),
            child: AuthTextField(
              controller: usernameController,
              hintText: '用户名',
              prefixIcon: Icons.person_outline,
              enabled: !submitting,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.username],
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 800),
            duration: const Duration(milliseconds: 600),
            beginOffset: const Offset(-0.08, 0),
            child: AuthTextField(
              controller: passwordController,
              hintText: '密码',
              prefixIcon: Icons.lock_outline,
              obscureText: obscurePassword,
              enabled: !submitting,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.password],
              suffix: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 900),
            duration: const Duration(milliseconds: 600),
            beginOffset: const Offset(-0.08, 0),
            child: CaptchaField(
              controller: codeController,
              captcha: captcha,
              loading: captchaLoading,
              enabled: !submitting,
              onRefresh: onRefreshCaptcha,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 1000),
            duration: const Duration(milliseconds: 600),
            beginOffset: const Offset(-0.08, 0),
            child: Row(
              children: <Widget>[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: submitting ? null : onRememberChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '记住我',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF4B5563),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: submitting ? null : onForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.flame500,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('忘记密码?', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FadeSlideIn(
            delay: const Duration(milliseconds: 1100),
            duration: const Duration(milliseconds: 600),
            beginScale: 0.9,
            curve: Curves.easeOutBack,
            child: GradientButton(
              text: '立即登录',
              loading: submitting,
              onPressed: submitting ? null : onSubmit,
            ),
          ),
          const SizedBox(height: 24),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFF3F4F6),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '还没有账户？',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
              GestureDetector(
                onTap: submitting ? null : onRegister,
                child: Text(
                  '免费注册',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.flame400
                        : AppColors.flame500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
