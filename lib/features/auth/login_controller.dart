import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../core/storage/session_storage.dart';
import '../../core/storage/storage_providers.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/captcha.dart';
import '../../data/repositories/auth_repository.dart';

/// 登录页状态。
class LoginState {
  const LoginState({
    this.captcha,
    this.captchaLoading = false,
    this.submitting = false,
    this.errorMessage,
  });

  /// 当前验证码。
  final Captcha? captcha;

  /// 是否正在拉取验证码。
  final bool captchaLoading;

  /// 是否正在提交登录。
  final bool submitting;

  /// 错误提示，非空时在表单顶部展示告警条。
  final String? errorMessage;

  /// 复制出新状态。
  LoginState copyWith({
    Captcha? captcha,
    bool? captchaLoading,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      captcha: captcha ?? this.captcha,
      captchaLoading: captchaLoading ?? this.captchaLoading,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 登录页控制器。
///
/// 负责验证码获取与登录提交，登录成功后由页面调用会话控制器写入登录态。
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() {
    // 首次进入自动拉取验证码，对应 Vue 端 onMounted(fetchCaptcha)。
    Future<void>.microtask(refreshCaptcha);
    return const LoginState(captchaLoading: true);
  }

  /// 刷新验证码。
  Future<void> refreshCaptcha() async {
    state = state.copyWith(captchaLoading: true);
    try {
      final Captcha captcha =
          await ref.read(authRepositoryProvider).createCaptcha();
      state = state.copyWith(captcha: captcha, captchaLoading: false);
    } on ApiException catch (error) {
      state = state.copyWith(
        captchaLoading: false,
        errorMessage: error.message.isEmpty ? '验证码获取失败' : error.message,
      );
    } on NetworkException catch (error) {
      state = state.copyWith(captchaLoading: false, errorMessage: error.message);
    } on Exception {
      state = state.copyWith(captchaLoading: false, errorMessage: '验证码获取失败');
    }
  }

  /// 展示校验/业务错误。
  void showError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  /// 提交登录，成功返回 [AuthUser]，失败返回 null 并写入错误提示。
  Future<AuthUser?> submit({
    required String username,
    required String password,
    required String ident,
    required String code,
    required bool rememberMe,
  }) async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final AuthUser user = await ref.read(authRepositoryProvider).login(
            username: username,
            password: password,
            ident: ident,
            code: code,
          );

      if (!user.isValid) {
        state = state.copyWith(submitting: false, errorMessage: '登录失败');
        return null;
      }

      await _applyRememberMe(username: username, rememberMe: rememberMe);
      state = state.copyWith(submitting: false);
      return user;
    } on ApiException catch (error) {
      state = state.copyWith(
        submitting: false,
        errorMessage: error.message.isEmpty ? '登录失败' : error.message,
      );
      return null;
    } on NetworkException {
      state = state.copyWith(submitting: false, errorMessage: '登录失败，请稍后重试');
      return null;
    } on Exception {
      state = state.copyWith(submitting: false, errorMessage: '登录失败，请稍后重试');
      return null;
    }
  }

  Future<void> _applyRememberMe({
    required String username,
    required bool rememberMe,
  }) async {
    final SessionStorage storage = ref.read(sessionStorageProvider);
    if (rememberMe) {
      await storage.saveRememberedUsername(username);
    } else {
      await storage.clearRememberedUsername();
    }
  }
}

/// 登录页状态。
final NotifierProvider<LoginController, LoginState> loginControllerProvider =
    NotifierProvider<LoginController, LoginState>(LoginController.new);
