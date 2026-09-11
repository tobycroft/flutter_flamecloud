import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/recharge_order.dart';
import '../../data/repositories/recharge_repository.dart';

/// 充值订单列表状态。
class RechargeOrderState {
  const RechargeOrderState({
    this.items = const <RechargeOrderItem>[],
    this.total = 0,
    this.page = 1,
    this.pageSize = 10,
    this.keyword = '',
    this.loading = false,
    this.errorMessage,
  });

  /// 当前页订单。
  final List<RechargeOrderItem> items;

  /// 总条数。
  final int total;

  /// 当前页码，从 1 开始。
  final int page;

  /// 每页数量，与 Vue 端固定值一致。
  final int pageSize;

  /// 当前订单号搜索词，空串表示不过滤。
  final String keyword;

  /// 是否正在加载。
  final bool loading;

  /// 错误提示，非空时展示重试入口。
  final String? errorMessage;

  /// 总页数。
  int get totalPages =>
      total <= 0 ? 1 : ((total + pageSize - 1) / pageSize).floor();

  /// 复制出新状态。
  RechargeOrderState copyWith({
    List<RechargeOrderItem>? items,
    int? total,
    int? page,
    int? pageSize,
    String? keyword,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RechargeOrderState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      keyword: keyword ?? this.keyword,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 充值订单列表控制器。
///
/// 搬迁自 vue_flamecloud/RechargeOrdersPage 的拉取逻辑：
/// 进入 tab 拉取第一页，搜索订单号或翻页时重查列表。
class RechargeOrderController extends Notifier<RechargeOrderState> {
  /// 是否已加载过，避免切回 tab 时重复拉取。
  bool _loaded = false;

  @override
  RechargeOrderState build() {
    ref.onDispose(() => _loaded = false);
    return const RechargeOrderState();
  }

  /// 首次进入 tab 时拉取一次。
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    await _fetch(page: 1);
  }

  /// 重新拉取当前页。
  Future<void> refresh() => _fetch(page: state.page);

  /// 按订单号搜索并回到第一页。
  Future<void> search(String keyword) async {
    state = state.copyWith(keyword: keyword.trim());
    await _fetch(page: 1);
  }

  /// 翻到指定页。
  Future<void> goPage(int page) async {
    if (page < 1 || page > state.totalPages) {
      return;
    }
    await _fetch(page: page);
  }

  /// 拉取指定页订单。
  Future<void> _fetch({required int page}) async {
    state = state.copyWith(loading: true, page: page, clearError: true);
    try {
      final RechargeOrderResult result = await ref
          .read(rechargeRepositoryProvider)
          .fetchOrders(
            page: page,
            pageSize: state.pageSize,
            keyword: state.keyword.isEmpty ? null : state.keyword,
          );
      if (!ref.mounted) {
        return;
      }
      _loaded = true;
      state = state.copyWith(
        items: result.items,
        total: result.total,
        loading: false,
      );
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '充值订单加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: '充值订单加载失败');
    }
  }
}

/// 充值订单状态实例。
final NotifierProvider<RechargeOrderController, RechargeOrderState>
rechargeOrderControllerProvider =
    NotifierProvider<RechargeOrderController, RechargeOrderState>(
      RechargeOrderController.new,
    );
