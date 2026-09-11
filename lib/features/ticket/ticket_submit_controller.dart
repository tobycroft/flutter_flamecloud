import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/ticket_attachment_draft.dart';
import '../../data/repositories/ticket_repository.dart';

/// 提交工单状态。
class TicketSubmitState {
  const TicketSubmitState({
    this.submitting = false,
    this.errorMessage,
    this.createdId,
  });

  /// 是否正在提交。
  final bool submitting;

  /// 错误提示。
  final String? errorMessage;

  /// 提交成功后的工单 id，供页面跳转详情。
  final int? createdId;

  /// 复制出新状态。
  TicketSubmitState copyWith({
    bool? submitting,
    String? errorMessage,
    int? createdId,
    bool clearError = false,
  }) {
    return TicketSubmitState(
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdId: createdId ?? this.createdId,
    );
  }
}

/// 提交工单控制器。
///
/// 搬迁自 vue_flamecloud/TicketSubmitPage：只提交标准工单（`/submit`）。
/// 在线客服已独立为聊天模块，工单区不再创建 chat 类型工单。
class TicketSubmitController extends Notifier<TicketSubmitState> {
  @override
  TicketSubmitState build() {
    return const TicketSubmitState();
  }

  /// 提交标准工单，返回新工单 id。
  Future<int> submitStandard({
    required String description,
    required String urgency,
    required String category,
    String? otherCategory,
    String? contactPhone,
    List<TicketAttachmentDraft>? attachments,
  }) async {
    return _run(() => ref.read(ticketRepositoryProvider).submit(
          description: description.trim(),
          urgency: urgency,
          category: category,
          otherCategory: otherCategory,
          contactPhone: contactPhone,
          attachments: attachments,
        ));
  }

  /// 统一提交流程：置 submitting、捕获异常并回填错误信息。
  Future<int> _run(Future<int> Function() action) async {
    state = const TicketSubmitState(submitting: true);
    try {
      final int id = await action();
      if (!ref.mounted) {
        return 0;
      }
      state = TicketSubmitState(submitting: false, createdId: id);
      return id;
    } on ApiException catch (error) {
      if (!ref.mounted) {
        return 0;
      }
      state = TicketSubmitState(
        submitting: false,
        errorMessage: error.message.isEmpty ? '提交失败' : error.message,
      );
      return 0;
    } on NetworkException catch (error) {
      if (!ref.mounted) {
        return 0;
      }
      state = TicketSubmitState(
        submitting: false,
        errorMessage: error.message,
      );
      return 0;
    } on Exception {
      if (!ref.mounted) {
        return 0;
      }
      state = const TicketSubmitState(
        submitting: false,
        errorMessage: '提交失败，请稍后重试',
      );
      return 0;
    }
  }
}

/// 提交工单状态实例。
final NotifierProvider<TicketSubmitController, TicketSubmitState>
    ticketSubmitControllerProvider =
    NotifierProvider<TicketSubmitController, TicketSubmitState>(
  TicketSubmitController.new,
);