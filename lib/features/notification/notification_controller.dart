import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';

/// 通知中心状态。
class NotificationState {
  const NotificationState({
    this.items = const <NotificationItem>[],
    this.loading = false,
    this.unread = 0,
    this.errorMessage,
  });

  /// 通知列表，按时间倒序（后端 order by id desc）。
  final List<NotificationItem> items;

  /// 是否正在加载。
  final bool loading;

  /// 未读总数。
  final int unread;

  /// 错误提示，非空时展示重试入口。
  final String? errorMessage;

  /// 复制出新状态。
  NotificationState copyWith({
    List<NotificationItem>? items,
    bool? loading,
    int? unread,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      unread: unread ?? this.unread,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 通知中心控制器。
///
/// 搬迁自 go_flamecloud 的站内通知列表逻辑：进入消息 tab 时拉取一次，
/// 列表直接在「消息」页内联展示；点击单条标记已读。
class NotificationController extends Notifier<NotificationState> {
  /// 是否已加载过，避免 IndexedStack 重建时重复拉取。
  bool _loaded = false;

  @override
  NotificationState build() {
    ref.onDispose(() => _loaded = false);
    return const NotificationState();
  }

  /// 首次进入时拉取一次，之后走 [refresh]。
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    await refresh();
    _loaded = true;
  }

  /// 重新拉取通知列表。
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final NotificationList result =
          await ref.read(notificationRepositoryProvider).fetchList();
      if (!ref.mounted) {
        return;
      }
      _loaded = true;
      state = state.copyWith(
        items: result.items,
        unread: result.unread,
        loading: false,
      );
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '通知加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: '通知加载失败');
    }
  }

  /// 标记单条通知已读：乐观更新本地状态，再回写后端。
  Future<void> markRead(int id) async {
    final bool needsRead =
        state.items.any((NotificationItem item) => item.id == id && !item.read);
    if (!needsRead) {
      return;
    }
    _applyRead(id);
    try {
      await ref.read(notificationRepositoryProvider).markRead(id: id);
    } on Exception {
      // 标记已读为单向操作，失败影响小，保持乐观态即可。
    }
  }

  /// 将指定通知置为已读，并相应扣减未读计数。
  void _applyRead(int id) {
    final List<NotificationItem> items =
        state.items.map((NotificationItem item) {
      if (item.id != id) {
        return item;
      }
      return NotificationItem(
        id: item.id,
        uid: item.uid,
        title: item.title,
        content: item.content,
        type: item.type,
        isRead: 1,
        createdAt: item.createdAt,
      );
    }).toList(growable: false);
    state = state.copyWith(
      items: items,
      unread: state.unread > 0 ? state.unread - 1 : 0,
    );
  }
}

/// 通知中心状态实例。
final NotifierProvider<NotificationController, NotificationState>
    notificationControllerProvider =
    NotifierProvider<NotificationController, NotificationState>(
  NotificationController.new,
);
