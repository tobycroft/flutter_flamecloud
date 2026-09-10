import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/models/auth_user.dart';
import 'login_controller.dart';
import 'login_page/login_card.dart';
import 'login_page/login_title.dart';
import 'session_controller.dart';
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
                        child: const LoginTitle(),
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
                            child: LoginCard(
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
