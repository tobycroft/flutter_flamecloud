import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/action_log.dart';
import '../../data/repositories/action_log_repository.dart';

/// 操作日志状态。
class ActionLogState {
  const ActionLogState({
    this.types = const <ActionLogType>[],
    this.items = const <ActionLogItem>[],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.selectedTypeId,
    this.loading = false,
    this.typesLoading = false,
    this.errorMessage,
  });

  /// 日志类型字典（侧边筛选 chips）。
  final List<ActionLogType> types;

  /// 当前页日志列表。
  final List<ActionLogItem> items;

  /// 总条数。
  final int total;

  /// 当前页码，从 1 开始。
  final int page;

  /// 每页数量，与 Vue 端固定值一致。
  final int pageSize;

  /// 当前筛选的类型 id，null 表示「综合」（全部类型）。
  final int? selectedTypeId;

  /// 日志列表是否正在加载。
  final bool loading;

  /// 类型字典是否正在加载。
  final bool typesLoading;

  /// 错误提示，非空时展示重试入口。
  final String? errorMessage;

  /// 总页数。
  int get totalPages =>
      total <= 0 ? 1 : ((total + pageSize - 1) / pageSize).floor();

  /// 是否还有更多数据（已加载条数 < 总条数）。
  bool get hasMore => items.length < total;

  /// 复制出新状态。
  ///
  /// [selectedTypeId] 使用哨兵值区分「未传」与「显式置 null（切回综合）」。
  ActionLogState copyWith({
    List<ActionLogType>? types,
    List<ActionLogItem>? items,
    int? total,
    int? page,
    int? pageSize,
    Object? selectedTypeId = _unset,
    bool? loading,
    bool? typesLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActionLogState(
      types: types ?? this.types,
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      selectedTypeId: identical(selectedTypeId, _unset)
          ? this.selectedTypeId
          : selectedTypeId as int?,
      loading: loading ?? this.loading,
      typesLoading: typesLoading ?? this.typesLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const Object _unset = Object();
}

/// 操作日志控制器。
///
/// 搬迁自 vue_flamecloud/ActionLogsPage 的拉取与筛选逻辑：
/// 进入页面拉取类型字典 + 第一页；切换类型或翻页时重查列表，
/// 对应 Vue 端 `?log_type_id=` 的筛选行为。
class ActionLogController extends Notifier<ActionLogState> {
  /// 是否已加载过，避免重复拉取。
  bool _loaded = false;

  @override
  ActionLogState build() {
    ref.onDispose(() => _loaded = false);
    return const ActionLogState();
  }

  /// 首次进入时拉取类型字典与第一页日志。
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    unawaited(_fetchTypes());
    await _fetchLogs(page: 1);
  }

  /// 重新拉取第一页日志（下拉刷新/重试时重置列表）。
  Future<void> refresh() async {
    await _fetchLogs(page: 1);
  }

  /// 切换日志类型筛选（null 表示综合），并回到第一页。
  Future<void> selectType(int? typeId) async {
    if (state.selectedTypeId == typeId) {
      return;
    }
    state = state.copyWith(selectedTypeId: typeId);
    await _fetchLogs(page: 1);
  }

  /// 上拉加载下一页（追加到已有列表），无更多或加载中时跳过。
  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) {
      return;
    }
    await _fetchLogs(page: state.page + 1, append: true);
  }

  /// 拉取类型字典。
  Future<void> _fetchTypes() async {
    state = state.copyWith(typesLoading: true);
    try {
      final List<ActionLogType> types =
          await ref.read(actionLogRepositoryProvider).fetchTypes();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(types: types, typesLoading: false);
    } on Exception {
      // 类型字典加载失败不阻塞列表，筛选条退化为仅「综合」。
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(typesLoading: false);
    }
  }

  /// 拉取指定页日志；[append] 为 true 时追加到已有列表（上拉加载）。
  Future<void> _fetchLogs({
    required int page,
    bool append = false,
  }) async {
    state = state.copyWith(loading: true, page: page, clearError: true);
    try {
      final ActionLogPage result =
          await ref.read(actionLogRepositoryProvider).fetchLogs(
                page: page,
                pageSize: state.pageSize,
                typeId: state.selectedTypeId,
              );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        items: append
            ? <ActionLogItem>[...state.items, ...result.items]
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
        errorMessage: error.message.isEmpty ? '日志加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: '日志加载失败');
    }
  }
}

/// 操作日志状态实例。
final NotifierProvider<ActionLogController, ActionLogState>
    actionLogControllerProvider =
    NotifierProvider<ActionLogController, ActionLogState>(
  ActionLogController.new,
);
