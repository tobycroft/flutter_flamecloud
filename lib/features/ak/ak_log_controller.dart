import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/access_key.dart';
import '../../data/repositories/access_key_repository.dart';

/// AK 调用日志状态。
class AkLogState {
  const AkLogState({
    this.akId,
    this.akName = '',
    this.items = const <AccessKeyLogItem>[],
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.loading = false,
    this.errorMessage,
  });

  /// 筛选的 AK id，null 表示全部 AK 的日志。
  final int? akId;

  /// 筛选的 AK 备注名，用于弹窗标题展示。
  final String akName;

  /// 当前页日志列表。
  final List<AccessKeyLogItem> items;

  /// 当前页码，从 1 开始。
  final int page;

  /// 每页数量，与后端默认值保持一致。
  final int pageSize;

  /// 是否还有下一页（返回条数满一页即认为可能还有）。
  final bool hasMore;

  /// 是否正在加载。
  final bool loading;

  /// 错误提示，非空时展示重试入口。
  final String? errorMessage;

  /// 复制出新状态。
  ///
  /// [akId] 使用哨兵值区分「未传」与「显式置 null（切回全部日志）」。
  AkLogState copyWith({
    Object? akId = _unset,
    String? akName,
    List<AccessKeyLogItem>? items,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AkLogState(
      akId: identical(akId, _unset) ? this.akId : akId as int?,
      akName: akName ?? this.akName,
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static const Object _unset = Object();
}

/// AK 调用日志控制器。
///
/// 搬迁自 vue_flamecloud 的 AK 日志逻辑（LogModal + AkLogsPage）：
/// 后端返回裸数组无 total，采用「返回条数不足一页则禁用下一页」的隐式分页。
/// 单 AK 弹窗与全部日志页共用此控制器，通过 [open] 切换筛选范围。
class AkLogController extends Notifier<AkLogState> {
  @override
  AkLogState build() {
    return const AkLogState();
  }

  /// 打开日志视图：重置筛选与页码并加载第一页。
  Future<void> open({int? akId, String akName = ''}) async {
    state = AkLogState(akId: akId, akName: akName);
    await _fetch(1);
  }

  /// 重新拉取当前页。
  Future<void> refresh() async {
    await _fetch(state.page);
  }

  /// 翻到指定页。
  Future<void> goPage(int page) async {
    if (page < 1) {
      return;
    }
    await _fetch(page);
  }

  /// 拉取指定页数据。
  Future<void> _fetch(int page) async {
    state = state.copyWith(loading: true, page: page, clearError: true);
    try {
      final List<AccessKeyLogItem> items =
          await ref.read(accessKeyRepositoryProvider).fetchLogs(
                akId: state.akId,
                page: page,
                pageSize: state.pageSize,
              );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        items: items,
        hasMore: items.length >= state.pageSize,
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

/// AK 调用日志状态实例。
final NotifierProvider<AkLogController, AkLogState> akLogControllerProvider =
    NotifierProvider<AkLogController, AkLogState>(
  AkLogController.new,
);
