import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/ecs_instance.dart';
import '../../data/repositories/ecs_repository.dart';

/// ECS 实例列表状态。
class EcsInstanceState {
  const EcsInstanceState({
    this.items = const <EcsInstance>[],
    this.loading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedRegion,
  });

  /// 全部实例（未筛选）。
  final List<EcsInstance> items;

  /// 是否正在加载。
  final bool loading;

  /// 错误提示，非空时展示重试入口。
  final String? errorMessage;

  /// 搜索关键字（匹配实例名 / 实例 ID / 备注）。
  final String searchQuery;

  /// 地域筛选，null 表示「全部地域」。
  final String? selectedRegion;

  /// 复制出新状态。
  EcsInstanceState copyWith({
    List<EcsInstance>? items,
    bool? loading,
    String? errorMessage,
    String? searchQuery,
    Object? selectedRegion = _unset,
    bool clearError = false,
  }) {
    return EcsInstanceState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRegion: identical(selectedRegion, _unset)
          ? this.selectedRegion
          : selectedRegion as String?,
    );
  }

  static const Object _unset = Object();

  /// 去重后的地域编码列表（用于筛选下拉），按出现顺序。
  List<String> get regionOptions {
    final List<String> result = <String>[];
    for (final EcsInstance item in items) {
      if (item.region.isNotEmpty && !result.contains(item.region)) {
        result.add(item.region);
      }
    }
    return result;
  }

  /// 按搜索关键字 + 地域筛选后的实例列表。
  List<EcsInstance> get filtered {
    final String q = searchQuery.trim().toLowerCase();
    return items.where((EcsInstance item) {
      if (selectedRegion != null && item.region != selectedRegion) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
      return item.displayName.toLowerCase().contains(q) ||
          item.instanceId.toLowerCase().contains(q) ||
          (item.remark != null &&
              item.remark!.toLowerCase().contains(q));
    }).toList(growable: false);
  }
}

/// ECS 实例列表控制器。
///
/// 搬迁自 vue_flamecloud 的 EcsPage「实例列表」Tab：进入时拉取当前用户全部实例，
/// 支持关键字搜索（名称/ID/备注）与地域筛选（下拉来自数据本身去重的地域编码）。
/// 后端未提供分页，列表整体加载后在前端完成筛选。
class EcsInstanceController extends Notifier<EcsInstanceState> {
  /// 是否已加载过，避免重复拉取。
  bool _loaded = false;

  EcsRepository get _repo => ref.read(ecsRepositoryProvider);

  @override
  EcsInstanceState build() {
    ref.onDispose(() => _loaded = false);
    return const EcsInstanceState();
  }

  /// 首次进入时拉取实例列表。
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    await _fetch();
  }

  /// 重新拉取列表（下拉刷新 / 重试）。
  Future<void> refresh() async {
    await _fetch();
  }

  /// 更新搜索关键字。
  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  /// 切换地域筛选（null 表示全部）。
  void setRegion(String? region) {
    state = state.copyWith(selectedRegion: region);
  }

  Future<void> _fetch() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<EcsInstance> items = await _repo.fetchInstances();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(items: items, loading: false);
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '实例列表加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: '实例列表加载失败');
    }
  }
}

/// ECS 实例列表控制器实例。
final NotifierProvider<EcsInstanceController, EcsInstanceState>
    ecsInstanceControllerProvider =
    NotifierProvider<EcsInstanceController, EcsInstanceState>(
  EcsInstanceController.new,
);
