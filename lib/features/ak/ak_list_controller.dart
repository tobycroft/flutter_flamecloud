import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/access_key.dart';
import '../../data/repositories/access_key_repository.dart';

/// AK 管理状态。
class AkListState {
  const AkListState({
    this.items = const <AccessKeyItem>[],
    this.loading = false,
    this.errorMessage,
  });

  /// AK 列表。
  final List<AccessKeyItem> items;

  /// 是否正在加载。
  final bool loading;

  /// 错误提示，非空时展示重试入口。
  final String? errorMessage;

  /// 复制出新状态。
  AkListState copyWith({
    List<AccessKeyItem>? items,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AkListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// AK 管理控制器。
///
/// 搬迁自 vue_flamecloud/UsersPage 的列表拉取逻辑；
/// 创建、启停、删除等操作直接抛出业务/网络异常，由页面负责提示。
class AkListController extends Notifier<AkListState> {
  /// 是否已加载过，避免重复拉取。
  bool _loaded = false;

  @override
  AkListState build() {
    ref.onDispose(() => _loaded = false);
    return const AkListState();
  }

  /// 首次进入时拉取一次，之后走 [refresh]。
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    await refresh();
    _loaded = true;
  }

  /// 重新拉取 AK 列表。
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<AccessKeyItem> items =
          await ref.read(accessKeyRepositoryProvider).fetchList();
      if (!ref.mounted) {
        return;
      }
      _loaded = true;
      state = state.copyWith(items: items, loading: false);
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? 'AK 列表加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: 'AK 列表加载失败');
    }
  }

  /// 创建 AK：成功返回一次性 secret 并刷新列表，失败时抛出异常。
  Future<AccessKeySecret> createAk(String name) async {
    final AccessKeySecret secret =
        await ref.read(accessKeyRepositoryProvider).createAk(name: name);
    await refresh();
    return secret;
  }

  /// 启用/禁用 AK：成功后刷新列表，失败时抛出异常。
  Future<void> setStatus(AccessKeyItem ak, bool enable) async {
    await ref
        .read(accessKeyRepositoryProvider)
        .updateStatus(id: ak.id, enable: enable);
    await refresh();
  }

  /// 删除 AK：成功后刷新列表，失败时抛出异常。
  Future<void> deleteAk(AccessKeyItem ak) async {
    await ref.read(accessKeyRepositoryProvider).deleteAk(id: ak.id);
    await refresh();
  }
}

/// AK 管理状态实例。
final NotifierProvider<AkListController, AkListState> akListControllerProvider =
    NotifierProvider<AkListController, AkListState>(
  AkListController.new,
);
