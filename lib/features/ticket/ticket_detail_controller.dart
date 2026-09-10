import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/ticket.dart';
import '../../data/repositories/ticket_repository.dart';
import 'ticket_summary_controller.dart';

/// 轮询间隔，与 Vue 端 TicketDetailPage 保持一致（5000ms）。
const Duration _kPollInterval = Duration(seconds: 5);

/// 工单详情状态。
class TicketDetailState {
  const TicketDetailState({
    this.info,
    this.replies = const <TicketReply>[],
    this.attachments = const <TicketAttachment>[],
    this.links = const <TicketLink>[],
    this.contacts = const <TicketContact>[],
    this.loading = false,
    this.sending = false,
    this.errorMessage,
  });

  /// 工单主体。
  final TicketInfo? info;

  /// 回复列表，按 id 正序。
  final List<TicketReply> replies;

  /// 主帖附件。
  final List<TicketAttachment> attachments;

  /// 关联链接。
  final List<TicketLink> links;

  /// 联系方式。
  final List<TicketContact> contacts;

  /// 是否正在加载详情。
  final bool loading;

  /// 是否正在执行写操作（回复/关闭/重启/转单）。
  final bool sending;

  /// 错误提示。
  final String? errorMessage;

  /// 复制出新状态。
  TicketDetailState copyWith({
    TicketInfo? info,
    List<TicketReply>? replies,
    List<TicketAttachment>? attachments,
    List<TicketLink>? links,
    List<TicketContact>? contacts,
    bool? loading,
    bool? sending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TicketDetailState(
      info: info ?? this.info,
      replies: replies ?? this.replies,
      attachments: attachments ?? this.attachments,
      links: links ?? this.links,
      contacts: contacts ?? this.contacts,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 工单详情控制器。
///
/// 搬迁自 vue_flamecloud/TicketDetailPage：进入页面拉全量详情，
/// 之后以 `last_reply_at` 时间串为游标每 5 秒轮询一次，
/// 仅在 `has_new` 为真时整页重拉（后端不返回增量消息体）。
/// 工单关闭后停止轮询，重开后自动恢复，避免无效请求。
class TicketDetailController extends Notifier<TicketDetailState> {
  Timer? _pollTimer;
  String _cursor = '';
  DateTime? _lastFetchAt;

  /// 无时间戳游标时的最小重拉间隔。
  ///
  /// 后端在客户端游标为空（工单从未写入 last_reply_at）时恒返回
  /// `has_new=true`，若不节流会每 5 秒全量重拉一次详情。
  static const Duration _kMinSilentRefresh = Duration(seconds: 15);

  @override
  TicketDetailState build() {
    ref.onDispose(_stopPolling);
    return const TicketDetailState();
  }

  /// 打开指定工单：加载详情并开启轮询。
  Future<void> open(int id) async {
    _stopPolling();
    await _fetchDetail(id);
    _startPollingIfNeeded(id);
  }

  /// 重新拉取详情（会同步刷新游标）。
  Future<void> refresh() async {
    final int id = state.info?.id ?? 0;
    if (id == 0) {
      return;
    }
    await _fetchDetail(id);
  }

  /// 追加回复，成功后重拉详情。
  Future<void> sendReply(String content) async {
    final int id = state.info?.id ?? 0;
    if (id == 0) {
      return;
    }
    state = state.copyWith(sending: true, clearError: true);
    try {
      await ref
          .read(ticketRepositoryProvider)
          .reply(id: id, content: content.trim());
      if (!ref.mounted) {
        return;
      }
      await _fetchDetail(id);
      _startPollingIfNeeded(id);
    } on Exception catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(sending: false, errorMessage: _messageOf(error));
      rethrow;
    }
  }

  /// 关闭工单，成功后重拉并停止轮询。
  Future<void> close() async {
    final int id = state.info?.id ?? 0;
    if (id == 0) {
      return;
    }
    try {
      await ref.read(ticketRepositoryProvider).close(id: id);
      ref.invalidate(pendingTicketCountProvider);
      _stopPolling();
      await _fetchDetail(id);
    } on Exception catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(errorMessage: _messageOf(error));
      rethrow;
    }
  }

  /// 重启工单，成功后重拉并恢复轮询。
  Future<void> reopen() async {
    final int id = state.info?.id ?? 0;
    if (id == 0) {
      return;
    }
    try {
      await ref.read(ticketRepositoryProvider).reopen(id: id);
      ref.invalidate(pendingTicketCountProvider);
      await _fetchDetail(id);
      _startPollingIfNeeded(id);
    } on Exception catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(errorMessage: _messageOf(error));
      rethrow;
    }
  }

  /// 聊天工单转标准工单，补齐分类与紧急性后重拉。
  Future<void> convert({
    required String category,
    required String urgency,
  }) async {
    final int id = state.info?.id ?? 0;
    if (id == 0) {
      return;
    }
    try {
      await ref.read(ticketRepositoryProvider).convert(
            id: id,
            category: category,
            urgency: urgency,
          );
      await _fetchDetail(id);
    } on Exception catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(errorMessage: _messageOf(error));
      rethrow;
    }
  }

  /// 拉取详情。
  Future<void> _fetchDetail(int id) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final TicketDetail detail =
          await ref.read(ticketRepositoryProvider).fetchDetail(id: id);
      if (!ref.mounted) {
        return;
      }
      _cursor = detail.info.lastReplyAt;
      state = state.copyWith(
        info: detail.info,
        replies: detail.replies,
        attachments: detail.attachments,
        links: detail.links,
        contacts: detail.contacts,
        loading: false,
        sending: false,
      );
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        sending: false,
        errorMessage: error.message.isEmpty ? '工单加载失败' : error.message,
      );
    } on NetworkException catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        sending: false,
        errorMessage: error.message,
      );
    } on Exception {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        loading: false,
        sending: false,
        errorMessage: '工单加载失败',
      );
    }
  }

  /// 开启轮询（工单已结案时不轮询）。
  void _startPollingIfNeeded(int id) {
    _stopPolling();
    if (state.info?.closed ?? false) {
      return;
    }
    _pollTimer = Timer.periodic(_kPollInterval, (_) => unawaited(_pollOnce(id)));
  }

  /// 单次轮询：有更新则重拉详情并推进游标。
  Future<void> _pollOnce(int id) async {
    try {
      final TicketPollResult result = await ref
          .read(ticketRepositoryProvider)
          .poll(id: id, lastReplyAt: _cursor);
      _cursor = result.lastReplyAt;
      if (!ref.mounted || !result.hasNew) {
        return;
      }
      if (result.lastReplyAt.isEmpty) {
        final DateTime now = DateTime.now();
        final DateTime? last = _lastFetchAt;
        if (last != null && now.difference(last) < _kMinSilentRefresh) {
          return;
        }
      }
      _lastFetchAt = DateTime.now();
      await _fetchDetail(id);
    } on Exception {
      // 轮询失败静默忽略，等待下一次间隔重试。
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// 统一提取异常文案。
  static String _messageOf(Object error) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    if (error is NetworkException) {
      return error.message;
    }
    return '操作失败，请稍后重试';
  }
}

/// 工单详情状态实例。
final NotifierProvider<TicketDetailController, TicketDetailState>
    ticketDetailControllerProvider =
    NotifierProvider<TicketDetailController, TicketDetailState>(
  TicketDetailController.new,
);