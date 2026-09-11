import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/balance_log.dart';
import '../../data/repositories/balance_repository.dart';

/// 余额流水列表状态。
class BalanceLogState {
  const BalanceLogState({
    this.items = const <BalanceLogItem>[],
    this.total = 0,
    this.page = 1,
    this.pageSize = 10,
    this.keyword = '',
    this.loading = false,
    this.errorMessage,
  });

  /// 当前页流水。
  final List<BalanceLogItem> items;

  /// 总条数。
  final int total;

  /// 当前页码，从 1 开始。
  final int page;

  /// 每页数量，与 Vue 端固定值一致。
  final int pageSize;

  /// 当前描述搜索词，空串表示不过滤。
  final String keyword;

  /// 是否正在加载。
  final bool loading;

  /// 错误提示，非空时展示重试入口。
  final String? errorMessage;

  /// 总页数。
  int get totalPages =>
      total <= 0 ? 1 : ((total + pageSize - 1) / pageSize).floor();

  /// 是否还有更多数据（已加载条数 < 总条数）。
  bool get hasMore => items.length < total;

  /// 复制出新状态。
  BalanceLogState copyWith({
    List<BalanceLogItem>? items,
    int? total,
    int? page,
    int? pageSize,
    String? keyword,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BalanceLogState(
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

/// 余额流水列表控制器。
///
/// 搬迁自 vue_flamecloud/BalanceLogPage 的拉取逻辑：
/// 进入 tab 拉取第一页，搜索描述或翻页时重查列表。
class BalanceLogController extends Notifier<BalanceLogState> {
  /// 是否已加载过，避免切回 tab 时重复拉取。
  bool _loaded = false;

  @override
  BalanceLogState build() {
    ref.onDispose(() => _loaded = false);
    return const BalanceLogState();
  }

  /// 首次进入 tab 时拉取一次。
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    await _fetch(page: 1);
  }

  /// 重新拉取第一页（下拉刷新/重试时重置列表）。
  Future<void> refresh() => _fetch(page: 1);

  /// 按描述搜索并回到第一页。
  Future<void> search(String keyword) async {
    state = state.copyWith(keyword: keyword.trim());
    await _fetch(page: 1);
  }

  /// 上拉加载下一页（追加到已有列表），无更多或加载中时跳过。
  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) {
      return;
    }
    await _fetch(page: state.page + 1, append: true);
  }

  /// 拉取指定页流水；[append] 为 true 时追加到已有列表（上拉加载）。
  Future<void> _fetch({required int page, bool append = false}) async {
    state = state.copyWith(loading: true, page: page, clearError: true);
    try {
      final BalanceLogResult result = await ref
          .read(balanceRepositoryProvider)
          .fetchLogs(
            page: page,
            pageSize: state.pageSize,
            keyword: state.keyword.isEmpty ? null : state.keyword,
          );
      if (!ref.mounted) {
        return;
      }
      _loaded = true;
      state = state.copyWith(
        items: append
            ? <BalanceLogItem>[...state.items, ...result.items]
            : result.items,
        total: result.total,
        loading: false,
      );
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '余额流水加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: '余额流水加载失败');
    }
  }
}

/// 余额流水状态实例。
final NotifierProvider<BalanceLogController, BalanceLogState>
balanceLogControllerProvider =
    NotifierProvider<BalanceLogController, BalanceLogState>(
      BalanceLogController.new,
    );
