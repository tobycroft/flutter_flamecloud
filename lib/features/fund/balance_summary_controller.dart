import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/balance_log.dart';
import '../../data/repositories/balance_repository.dart';

/// 余额概览状态（资金管理页顶部卡片）。
class BalanceSummaryState {
  const BalanceSummaryState({
    this.summary,
    this.loading = false,
    this.errorMessage,
  });

  /// 余额概览，未加载成功时为 null（卡片展示占位符）。
  final BalanceSummary? summary;

  /// 是否正在加载。
  final bool loading;

  /// 错误提示，非空时卡片可点击重试。
  final String? errorMessage;

  /// 复制出新状态。
  BalanceSummaryState copyWith({
    BalanceSummary? summary,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BalanceSummaryState(
      summary: summary ?? this.summary,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 余额概览控制器。
///
/// 对应 `GET /v1/user/balance`，与余额流水列表共用余额仓库。
/// 加载失败只影响顶部卡片（退化为占位符），不阻塞两个 tab 的列表。
class BalanceSummaryController extends Notifier<BalanceSummaryState> {
  @override
  BalanceSummaryState build() => const BalanceSummaryState();

  /// 拉取余额概览，保留已加载的旧数据。
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final BalanceSummary summary = await ref
          .read(balanceRepositoryProvider)
          .fetchSummary();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(summary: summary, loading: false);
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '余额加载失败' : error.message,
      );
    } on NetworkException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, errorMessage: error.message);
    } on Exception {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(loading: false, errorMessage: '余额加载失败');
    }
  }
}

/// 余额概览状态实例。
final NotifierProvider<BalanceSummaryController, BalanceSummaryState>
balanceSummaryControllerProvider =
    NotifierProvider<BalanceSummaryController, BalanceSummaryState>(
      BalanceSummaryController.new,
    );
