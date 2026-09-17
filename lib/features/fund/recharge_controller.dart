import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/repositories/recharge_repository.dart';

/// 充值页状态：仅承载提交中的加载与错误提示。
class RechargeState {
  const RechargeState({this.loading = false, this.errorMessage});

  /// 是否正在提交。
  final bool loading;

  /// 错误提示，非空时由页面用 SnackBar 展示。
  final String? errorMessage;

  /// 复制新状态。
  RechargeState copyWith({
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RechargeState(
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 充值页控制器。
///
/// 搬迁自 vue_flamecloud 的 RechargePage：
/// - [submitOnline] 在线充值（支付宝），成功后返回 `pay_url` 由上层用 WebView 拉起支付；
/// - [submitOffline] 线下充值申请（含收款凭证）。
///
/// 后端支付宝通道尚未配置时，[submitOnline] 会返回空 `pay_url` 或抛错，
/// 由页面展示「支付通道待配置」占位，符合「先留空」的过渡状态。
class RechargeController extends Notifier<RechargeState> {
  RechargeRepository get _repo => ref.read(rechargeRepositoryProvider);

  @override
  RechargeState build() => const RechargeState();

  /// 清除当前错误提示（如用户重新输入时）。
  void clearError() => state = state.copyWith(clearError: true);

  /// 在线充值下单。成功返回支付宝 `pay_url`（可能为空 = 通道未配置），失败返回 null。
  Future<String?> submitOnline(double amount) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final RechargeOnlineResult result = await _repo.rechargeOnline(
        amount,
        'alipay',
      );
      state = state.copyWith(loading: false);
      return result.payUrl;
    } on ApiException catch (error) {
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '下单失败' : error.message,
      );
      return null;
    } on NetworkException catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.message);
      return null;
    } on Exception {
      state = state.copyWith(loading: false, errorMessage: '下单失败');
      return null;
    }
  }

  /// 线下充值申请。成功返回 true。
  Future<bool> submitOffline(RechargeOfflineForm form) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _repo.rechargeOffline(form);
      state = state.copyWith(loading: false);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '提交失败' : error.message,
      );
      return false;
    } on NetworkException catch (error) {
      state = state.copyWith(loading: false, errorMessage: error.message);
      return false;
    } on Exception {
      state = state.copyWith(loading: false, errorMessage: '提交失败');
      return false;
    }
  }
}

/// 充值控制器实例。
final NotifierProvider<RechargeController, RechargeState>
    rechargeControllerProvider =
    NotifierProvider<RechargeController, RechargeState>(
  RechargeController.new,
);
