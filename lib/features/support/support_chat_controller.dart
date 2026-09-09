import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';

/// 客服会话状态。
class SupportChatState {
  const SupportChatState({
    this.messages = const <ChatMessage>[],
    this.loading = false,
    this.sending = false,
    this.online = false,
    this.unread = false,
    this.errorMessage,
  });

  /// 消息列表，按发送时间正序。
  final List<ChatMessage> messages;

  /// 是否正在拉取消息。
  final bool loading;

  /// 是否正在发送消息。
  final bool sending;

  /// 客服是否在线，对应 Vue 端 CustomerServiceButton 的在线小圆点。
  final bool online;

  /// 是否存在未读的客服消息，用于底栏「消息」红标。
  final bool unread;

  /// 错误提示，非空时在页面顶部展示。
  final String? errorMessage;

  /// 复制出新状态。
  SupportChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    bool? online,
    bool? unread,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SupportChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      online: online ?? this.online,
      unread: unread ?? this.unread,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 客服会话控制器。
///
/// 搬迁自 vue_flamecloud/src/pages/console/UserCenter/ChatPage.vue：
/// 进入时拉取全量消息，之后按 5 秒间隔增量轮询 `/v1/chat/poll`。
///
/// 与 Vue 端不同的是，本控制器在登录期间常驻轮询（而非只在聊天页轮询），
/// 因为底栏「消息」需要展示未读红标；未读只在收到客服消息且用户不在
/// 聊天页时置位，进入聊天页即清除。
class SupportChatController extends Notifier<SupportChatState> {
  Timer? _pollTimer;

  /// 增量轮询游标，取已收到消息的最大 id。
  int _lastId = 0;

  /// 用户是否停留在聊天页。
  bool _viewing = false;

  /// 是否已启动过，避免重复开启定时器。
  bool _started = false;

  /// 轮询间隔，与 Vue 端 ChatPage 的 `setInterval(pollMessages, 5000)` 一致。
  static const Duration pollInterval = Duration(seconds: 5);

  @override
  SupportChatState build() {
    ref.onDispose(stop);
    return const SupportChatState();
  }

  /// 启动会话：开启轮询并拉取一次全量消息，登录进入控制台时调用。
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _startTimer();
    await refresh();
  }

  /// 重新拉取全量消息。
  ///
  /// 发送消息成功后也走这里（与 Vue 端 handleSend 一致，
  /// 不在本地拼装临时消息，避免与服务端排序不一致）。
  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final List<ChatMessage> messages =
          await ref.read(chatRepositoryProvider).fetchMessages();
      if (!ref.mounted) {
        return;
      }
      _syncLastId(messages);
      state = state.copyWith(messages: messages, loading: false);
      await _refreshOnline();
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        errorMessage: error.message.isEmpty ? '消息加载失败' : error.message,
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
      state = state.copyWith(loading: false, errorMessage: '消息加载失败');
    }
  }

  /// 发送一条消息，成功返回 true。
  Future<bool> send(String content) async {
    final String text = content.trim();
    if (text.isEmpty) {
      return false;
    }
    state = state.copyWith(sending: true, clearError: true);
    try {
      await ref.read(chatRepositoryProvider).sendMessage(content: text);
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(sending: false);
      await refresh();
      return true;
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(
        sending: false,
        errorMessage: error.message.isEmpty ? '发送失败' : error.message,
      );
      return false;
    } on NetworkException catch (error) {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(sending: false, errorMessage: error.message);
      return false;
    } on Exception {
      if (!ref.mounted) {
        return false;
      }
      state = state.copyWith(sending: false, errorMessage: '发送失败，请稍后重试');
      return false;
    }
  }

  /// 进入聊天页：标记为已读并刷新客服在线状态。
  Future<void> enterChat() async {
    _viewing = true;
    markRead();
    await _refreshOnline();
  }

  /// 离开聊天页，之后收到的客服消息会重新点亮红标。
  void leaveChat() {
    _viewing = false;
  }

  /// 清除未读标记。
  void markRead() {
    if (state.unread) {
      state = state.copyWith(unread: false);
    }
  }

  /// 停止轮询，provider 释放（退出登录）时自动调用。
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _started = false;
    _viewing = false;
    _lastId = 0;
  }

  void _startTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_poll());
    });
  }

  /// 增量拉取新消息，失败静默（与 Vue 端 pollMessages 一致，不影响界面）。
  Future<void> _poll() async {
    try {
      final List<ChatMessage> incoming =
          await ref.read(chatRepositoryProvider).pollMessages(lastId: _lastId);
      if (incoming.isEmpty || !ref.mounted) {
        return;
      }
      final bool hasAdminMessage =
          incoming.any((ChatMessage message) => message.fromAdmin);
      _syncLastId(incoming);
      state = state.copyWith(
        messages: <ChatMessage>[...state.messages, ...incoming],
        unread: state.unread || (hasAdminMessage && !_viewing),
      );
    } on Exception {
      // 轮询失败忽略，等下一轮。
    }
  }

  Future<void> _refreshOnline() async {
    try {
      final bool online =
          await ref.read(chatRepositoryProvider).fetchKfOnline();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(online: online);
    } on Exception {
      // 在线状态拉取失败保持原值。
    }
  }

  void _syncLastId(List<ChatMessage> messages) {
    for (final ChatMessage message in messages) {
      if (message.id > _lastId) {
        _lastId = message.id;
      }
    }
  }

}

/// 客服会话状态。
final NotifierProvider<SupportChatController, SupportChatState>
    supportChatControllerProvider =
    NotifierProvider<SupportChatController, SupportChatState>(
  SupportChatController.new,
);
