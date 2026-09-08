import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/captcha.dart';
import 'login_controller.dart';
import 'session_controller.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/captcha_field.dart';
import 'widgets/gradient_button.dart';
import 'widgets/login_background.dart';

/// 账号密码登录页。
///
/// 搬迁自 vue_flamecloud/src/pages/LoginPage.vue，字段、校验规则、
/// 接口与交互保持一致（密码按后端约定明文提交，由服务端 MD5 比对）。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _exitController;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -10),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -10, end: 10),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 10, end: -10),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -10, end: 10),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 10, end: 0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOutSine),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final CurvedAnimation exitCurve = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInQuad,
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(exitCurve);
    _exitScale = Tween<double>(begin: 1, end: 0.95).animate(exitCurve);

    final String? remembered =
        ref.read(sessionStorageProvider).rememberedUsername;
    if (remembered != null && remembered.isNotEmpty) {
      _usernameController.text = remembered;
      _rememberMe = true;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _shakeController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LoginState state = ref.watch(loginControllerProvider);
    final bool submitting = state.submitting;
    final String? errorMessage = state.errorMessage;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const LoginBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        duration: const Duration(milliseconds: 800),
                        beginOffset: const Offset(0, 0.6),
                        child: const _LoginTitle(),
                      ),
                      const SizedBox(height: 40),
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (BuildContext context, Widget? child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: FadeTransition(
                          opacity: _exitOpacity,
                          child: ScaleTransition(
                            scale: _exitScale,
                            child: _LoginCard(
                              errorMessage: errorMessage,
                              submitting: submitting,
                              captcha: state.captcha,
                              captchaLoading: state.captchaLoading,
                              obscurePassword: _obscurePassword,
                              rememberMe: _rememberMe,
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              codeController: _codeController,
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onRememberChanged: (bool? value) => setState(
                                () => _rememberMe = value ?? false,
                              ),
                              onRefreshCaptcha: _refreshCaptcha,
                              onSubmit: _submit,
                              onForgotPassword: _showComingSoon,
                              onRegister: _showComingSoon,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '© 2024 火焰云. 保留所有权利.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshCaptcha() {
    ref.read(loginControllerProvider.notifier).refreshCaptcha();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('该页面正在搬迁中，敬请期待')),
      );
  }

  /// 表单校验，文案与 Vue 端 validateForm 保持一致。
  String? _validate() {
    if (_usernameController.text.trim().isEmpty) {
      return '请输入用户名';
    }
    if (_passwordController.text.isEmpty) {
      return '请输入密码';
    }
    if (_codeController.text.trim().isEmpty) {
      return '请输入验证码';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final String? validationError = _validate();
    if (validationError != null) {
      ref.read(loginControllerProvider.notifier).showError(validationError);
      _playShake();
      return;
    }

    final AuthUser? user =
        await ref.read(loginControllerProvider.notifier).submit(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
              ident: ref.read(loginControllerProvider).captcha?.ident ?? '',
              code: _codeController.text.trim(),
              rememberMe: _rememberMe,
            );

    if (!mounted) {
      return;
    }

    if (user == null) {
      _playShake();
      _codeController.clear();
      _refreshCaptcha();
      return;
    }

    // 对应 Vue 端登录成功后的卡片退场动画，结束后再切换登录态。
    await _exitController.forward();
    if (!mounted) {
      return;
    }
    await ref.read(sessionControllerProvider.notifier).applyLogin(user);
  }

  void _playShake() {
    _shakeController.forward(from: 0);
  }
}

class _LoginTitle extends StatelessWidget {
  const _LoginTitle();

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

class _LoginCard extends StatelessWidget {
  const _LoginCard({
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
        color: isDark
            ? AppColors.dark500.withValues(alpha: 0.8)
            : Colors.white,
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
