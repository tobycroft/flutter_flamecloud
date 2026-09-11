import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/ticket.dart';
import '../../data/repositories/ticket_repository.dart';
import 'ticket_summary_controller.dart';

/// 工单列表状态。
class TicketListState {
  const TicketListState({
    this.items = const <TicketItem>[],
    this.total = 0,
    this.processing = 0,
    this.confirm = 0,
    this.page = 1,
    this.pageSize = 20,
    this.statusFilter,
    this.loading = false,
    this.errorMessage,
  });

  /// 当前页工单。
  final List<TicketItem> items;

  /// 总条数。
  final int total;

  /// 服务中数量（后端聚合）。
  final int processing;

  /// 待确认数量（后端聚合）。
  final int confirm;

  /// 当前页码，从 1 开始。
  final int page;

  /// 每页数量。
  final int pageSize;

  /// 状态筛选：null 为全部，取 0/1/2/3。
  final int? statusFilter;

  /// 是否正在加载。
  final bool loading;

  /// 错误提示。
  final String? errorMessage;

  /// 总页数。
  int get totalPages =>
      total <= 0 ? 1 : ((total + pageSize - 1) / pageSize).floor();

  /// 是否还有更多数据（已加载条数 < 总条数）。
  bool get hasMore => items.length < total;

  /// 复制出新状态。
  ///
  /// [statusFilter] 使用哨兵值区分「未传」与「显式置 null（切回全部）」。
  TicketListState copyWith({
    List<TicketItem>? items,
    int? total,
    int? processing,
    int? confirm,
    int? page,
    int? pageSize,
    Object? statusFilter = _unset,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TicketListState(
      items: items ?? this.items,
      total: total ?? this.total,
      processing: processing ?? this.processing,
      confirm: confirm ?? this.confirm,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      statusFilter: identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as int?,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const Object _unset = Object();
}

/// 工单列表控制器。
///
/// 搬迁自 vue_flamecloud/TicketListPage：分页列表 + 状态筛选；
/// 列表接口必须用 POST（后端 GET 分支忽略分页参数）。
class TicketListController extends Notifier<TicketListState> {
  /// 是否已加载过，避免重复拉取。
  bool _loaded = false;

  @override
  TicketListState build() {
    ref.onDispose(() => _loaded = false);
    return const TicketListState();
  }

  /// 首次进入时拉取一次。
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    await refresh();
    _loaded = true;
  }

  /// 重新拉取第一页（下拉刷新/重试时重置列表）。
  Future<void> refresh() async {
    await _fetch(page: 1);
  }

  /// 切换状态筛选并回到第一页。
  Future<void> selectStatus(int? status) async {
    if (state.statusFilter == status) {
      return;
    }
    state = state.copyWith(statusFilter: status);
    await _fetch(page: 1);
  }

  /// 上拉加载下一页（追加到已有列表），无更多或加载中时跳过。
  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) {
      return;
    }
    await _fetch(page: state.page + 1, append: true);
  }

  /// 关闭工单（状态置 3），成功后刷新列表。
  Future<void> close(TicketItem ticket) async {
    await ref.read(ticketRepositoryProvider).close(id: ticket.id);
    ref.invalidate(pendingTicketCountProvider);
    await refresh();
  }

  /// 重启已关闭工单，成功后刷新列表。
  Future<void> reopen(TicketItem ticket) async {
    await ref.read(ticketRepositoryProvider).reopen(id: ticket.id);
    ref.invalidate(pendingTicketCountProvider);
    await refresh();
  }

  /// 拉取指定页数据；[append] 为 true 时追加到已有列表（上拉加载）。
  Future<void> _fetch({required int page, bool append = false}) async {
    state = state.copyWith(loading: true, page: page, clearError: true);
    try {
      final TicketListResult result = await ref
          .read(ticketRepositoryProvider)
          .fetchList(
            page: page,
            pageSize: state.pageSize,
            status: state.statusFilter,
          );
      if (!ref.mounted) {
        return;
      }
      _loaded = true;
      state = state.copyWith(
        items: append
            ? <TicketItem>[...state.items, ...result.items]
            : result.items,
        total: result.total,
        processing: result.processing,
        confirm: result.confirm,
        loading: false,
      );
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '工单加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: '工单加载失败');
    }
  }
}

/// 工单列表状态实例。
final NotifierProvider<TicketListController, TicketListState>
ticketListControllerProvider =
    NotifierProvider<TicketListController, TicketListState>(
      TicketListController.new,
    );
