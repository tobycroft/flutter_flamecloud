import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/bill.dart';
import '../../data/repositories/bill_repository.dart';

/// 账单列表状态。
class BillState {
  const BillState({
    this.items = const <BillItem>[],
    this.total = 0,
    this.page = 1,
    this.pageSize = 10,
    this.period = 'all',
    this.moduleType = 'all',
    this.status = 'all',
    this.keyword = '',
    this.periods = const <String>[],
    this.generating = false,
    this.loading = false,
    this.errorMessage,
  });

  /// 当前页账单。
  final List<BillItem> items;

  /// 总条数。
  final int total;

  /// 当前页码，从 1 开始。
  final int page;

  /// 每页数量，与 Vue 端固定值一致。
  final int pageSize;

  /// 账期过滤，'all' 表示全部。
  final String period;

  /// 计费模块过滤，'all' 表示全部。
  final String moduleType;

  /// 状态过滤，'all' 表示全部。
  final String status;

  /// 当前关键字，空串表示不过滤。
  final String keyword;

  /// 可用账期列表。
  final List<String> periods;

  /// 是否正在生成账单。
  final bool generating;

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
  BillState copyWith({
    List<BillItem>? items,
    int? total,
    int? page,
    int? pageSize,
    String? period,
    String? moduleType,
    String? status,
    String? keyword,
    List<String>? periods,
    bool? generating,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BillState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      period: period ?? this.period,
      moduleType: moduleType ?? this.moduleType,
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
      periods: periods ?? this.periods,
      generating: generating ?? this.generating,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 账单列表控制器。
///
/// 搬迁自 vue_flamecloud/BillPage 的拉取与筛选逻辑：
/// 进入 tab 拉取第一页与可用账期，搜索 / 筛选 / 翻页时重查列表。
class BillController extends Notifier<BillState> {
  /// 是否已加载过，避免切回 tab 时重复拉取。
  bool _loaded = false;

  @override
  BillState build() {
    ref.onDispose(() => _loaded = false);
    return const BillState();
  }

  /// 首次进入 tab 时拉取账期与第一页。
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    await Future.wait(<Future<void>>[loadPeriods(), _fetch(page: 1)]);
  }

  /// 重新拉取第一页（下拉刷新/重试时重置列表）。
  Future<void> refresh() => _fetch(page: 1);

  /// 拉取可用账期。
  Future<void> loadPeriods() async {
    try {
      final List<String> periods =
          await ref.read(billRepositoryProvider).fetchPeriods();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(periods: periods);
    } on ApiException {
      // 账期列表不影响主列表，失败静默忽略。
    } on NetworkException {
      // 同上。
    }
  }

  /// 按关键字搜索并回到第一页。
  Future<void> search(String keyword) async {
    state = state.copyWith(keyword: keyword.trim());
    await _fetch(page: 1);
  }

  /// 切换账期并回到第一页。
  Future<void> changePeriod(String period) async {
    state = state.copyWith(period: period);
    await _fetch(page: 1);
  }

  /// 切换计费模块并回到第一页。
  Future<void> changeModule(String moduleType) async {
    state = state.copyWith(moduleType: moduleType);
    await _fetch(page: 1);
  }

  /// 切换状态并回到第一页。
  Future<void> changeStatus(String status) async {
    state = state.copyWith(status: status);
    await _fetch(page: 1);
  }

  /// 上拉加载下一页（追加到已有列表），无更多或加载中时跳过。
  Future<void> loadMore() async {
    if (state.loading || state.generating || !state.hasMore) {
      return;
    }
    await _fetch(page: state.page + 1, append: true);
  }

  /// 生成当月账单（按实例出账），成功后刷新列表与账期。
  Future<void> generate({String? period}) async {
    if (state.generating) {
      return;
    }
    state = state.copyWith(generating: true, clearError: true);
    try {
      final BillGenerateResult result =
          await ref.read(billRepositoryProvider).generateBills(period: period);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(generating: false);
      await Future.wait(<Future<void>>[loadPeriods(), _fetch(page: 1)]);
      if (!ref.mounted) {
        return;
      }
      if (result.generated == 0) {
        state = state.copyWith(
          errorMessage: '本月账单已生成，没有可出账的实例或模块',
        );
      }
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        generating: false,
        errorMessage: error.message.isEmpty ? '账单生成失败' : error.message,
      );
    } on NetworkException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(generating: false, errorMessage: error.message);
    } on Exception {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(generating: false, errorMessage: '账单生成失败');
    }
  }

  /// 拉取指定页账单；[append] 为 true 时追加到已有列表（上拉加载）。
  Future<void> _fetch({required int page, bool append = false}) async {
    state = state.copyWith(loading: true, page: page, clearError: true);
    try {
      final BillResult result = await ref.read(billRepositoryProvider).fetchBills(
        page: page,
        pageSize: state.pageSize,
        status: state.status == 'all' ? null : state.status,
        moduleType: state.moduleType == 'all' ? null : state.moduleType,
        period: state.period == 'all' ? null : state.period,
        keyword: state.keyword.isEmpty ? null : state.keyword,
      );
      if (!ref.mounted) {
        return;
      }
      _loaded = true;
      state = state.copyWith(
        items: append
            ? <BillItem>[...state.items, ...result.items]
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
        errorMessage: error.message.isEmpty ? '账单加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: '账单加载失败');
    }
  }
}

/// 账单列表状态实例。
final NotifierProvider<BillController, BillState> billControllerProvider =
    NotifierProvider<BillController, BillState>(BillController.new);
