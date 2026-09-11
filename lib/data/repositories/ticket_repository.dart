import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/ticket.dart';
import '../models/ticket_attachment_draft.dart';

/// 工单接口仓库。
///
/// 搬迁自 vue_flamecloud 的工单模块（TicketListPage / TicketDetailPage /
/// TicketSubmitPage），并与 go_flamecloud 的实现对齐，注意以下后端约束：
/// - 列表与详情必须用 POST：列表的 GET 分支下 `page`/`page_size` 恒为 1/20；
///   详情的 GET 分支返回的 data 中**缺少 `info` 字段**，只有 POST 才完整；
/// - poll 走 GET，其余写操作走 POST 表单；
/// - 数组参数（attachments / links / contacts / ids）用单字段 JSON 字符串。
class TicketRepository {
  const TicketRepository(this._dio);

  final Dio _dio;

  /// 拉取工单列表，对应 `POST /v1/ticket/list`。
  ///
  /// [status] 取 0/1/2/3，为空表示不筛选；后端同时返回
  /// `processing`（服务中）与 `confirm`（待确认）两个聚合计数。
  Future<TicketListResult> fetchList({
    required int page,
    int pageSize = 20,
    int? status,
    String? category,
    String? keyword,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.ticket.list,
        data: FormData.fromMap(<String, Object?>{
          'page': page,
          'page_size': pageSize,
          'status': ?_statusValue(status),
          if (category != null && category.isNotEmpty) 'category': category,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        }),
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      final List<dynamic>? list =
          data?['list'] is List ? data!['list'] as List<dynamic> : null;
      final List<TicketItem> items = list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    TicketItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <TicketItem>[];
      return TicketListResult(
        items: items,
        total: JsonValue.integer(data?['total']) ?? 0,
        processing: JsonValue.integer(data?['processing']) ?? 0,
        confirm: JsonValue.integer(data?['confirm']) ?? 0,
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取工单详情，对应 `POST /v1/ticket/detail`。
  ///
  /// 后端 GET 分支有个坑：返回的 data 里**没有 `info` 字段**（只有 replies），
  /// 只有 POST 才返回完整的 info / attachments / links / contacts，
  /// 因此这里走 POST（与列表一致）。
  Future<TicketDetail> fetchDetail({required int id}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.ticket.detail,
        data: FormData.fromMap(<String, Object?>{'id': id}),
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiFormatException();
      }
      // 容错：若后端哪天直接把工单主体平铺在 data 上（缺少 info 包裹），
      // 只要带 id 就当作 info 解析，避免整页空白。
      final Object? rawInfo = data['info'] is Map ? data['info'] : (data['id'] == null ? null : data);
      if (rawInfo is! Map) {
        throw const ApiFormatException();
      }
      return TicketDetail(
        info: TicketInfo.fromMap(rawInfo.cast<String, dynamic>()),
        replies: _toList(data['replies'], TicketReply.fromMap),
        attachments: TicketAttachment.fromList(data['attachments']),
        links: _toList(data['links'], TicketLink.fromMap),
        contacts: _toList(data['contacts'], TicketContact.fromMap),
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 轮询是否出现新回复，对应 `GET /v1/ticket/poll`。
  ///
  /// 游标为服务端返回的 `last_reply_at` 时间串；后端只回布尔量，
  /// 需自行决定是否重拉详情。
  Future<TicketPollResult> poll({
    required int id,
    required String lastReplyAt,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.ticket.poll,
        queryParameters: <String, Object?>{
          'id': id,
          'last_reply_at': lastReplyAt,
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      return TicketPollResult(
        hasNew: JsonValue.boolean(data?['has_new']) ?? false,
        lastReplyAt: JsonValue.string(data?['last_reply_at']) ?? lastReplyAt,
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 提交标准工单，对应 `POST /v1/ticket/submit`。
  ///
  /// [attachments] 为已通过三段式上传得到的附件草稿（name/url/hash），
  /// 以 JSON 数组随 `attachments` 字段提交，与 Vue 端一致；为空则省略。
  /// 返回新工单 id。
  Future<int> submit({
    required String description,
    required String urgency,
    required String category,
    String? otherCategory,
    String? contactPhone,
    List<TicketAttachmentDraft>? attachments,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.ticket.submit,
        data: FormData.fromMap(<String, Object?>{
          'description': description,
          'urgency': urgency,
          'category': category,
          'other_category': ?otherCategory,
          'contact_phone': ?contactPhone,
          if (attachments != null && attachments.isNotEmpty)
            'attachments': jsonEncode(
              attachments.map((TicketAttachmentDraft a) => a.toJson()).toList(),
            ),
        }),
      );
      return JsonValue.integer(_unwrap(response).asMap?['id']) ?? 0;
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 追加回复，对应 `POST /v1/ticket/reply`。
  ///
  /// [attachments] 同上，为已上传的图片草稿；为空则省略。
  /// 注意后端会把工单状态置为 1（客户发送），即使工单已关闭也会被改回。
  Future<void> reply({
    required int id,
    required String content,
    List<TicketAttachmentDraft>? attachments,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.ticket.reply,
        data: FormData.fromMap(<String, Object?>{
          'id': id,
          'content': content,
          if (attachments != null && attachments.isNotEmpty)
            'attachments': jsonEncode(
              attachments.map((TicketAttachmentDraft a) => a.toJson()).toList(),
            ),
        }),
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 关闭工单，对应 `POST /v1/ticket/close`（状态置 3）。
  Future<void> close({required int id}) async {
    await _post(<String, Object?>{'id': id}, ApiEndpoints.ticket.close);
  }

  /// 重启工单，对应 `POST /v1/ticket/reopen`（仅 status=3 可用）。
  Future<void> reopen({required int id}) async {
    await _post(<String, Object?>{'id': id}, ApiEndpoints.ticket.reopen);
  }

  /// 删除单条工单，对应 `POST /v1/ticket/delete`（主表软删）。
  Future<void> deleteTicket({required int id}) async {
    await _post(<String, Object?>{'id': id}, ApiEndpoints.ticket.delete);
  }

  /// 聊天工单转标准工单，对应 `POST /v1/ticket/convert`。
  ///
  /// 仅 `ticket_type=chat` 的工单可转，后端由此补齐 category / urgency。
  Future<void> convert({
    required int id,
    required String category,
    required String urgency,
  }) async {
    await _post(
      <String, Object?>{
        'id': id,
        'category': category,
        'urgency': urgency,
      },
      ApiEndpoints.ticket.convert,
    );
  }

  /// 统一提交单表单写操作。
  Future<void> _post(Map<String, Object?> fields, String path) async {
    try {
      await _dio.post<dynamic>(path, data: FormData.fromMap(fields));
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 状态参数序列化：后端要求字符串，无筛选项时省略该字段。
  static String? _statusValue(int? status) => status?.toString();

  /// 将任意数组解析为指定模型列表。
  static List<T> _toList<T>(
    Object? value,
    T Function(Map<String, dynamic> map) fromMap,
  ) {
    if (value is! List) {
      return <T>[];
    }
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) => fromMap(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  /// 解析统一响应包。
  ApiEnvelope _unwrap(Response<dynamic> response) {
    final Object? data = response.data;
    if (data is ApiEnvelope) {
      return data;
    }
    throw const ApiFormatException();
  }
}

/// 工单仓库实例。
final Provider<TicketRepository> ticketRepositoryProvider =
    Provider<TicketRepository>((Ref ref) {
  return TicketRepository(ref.watch(dioProvider));
});
