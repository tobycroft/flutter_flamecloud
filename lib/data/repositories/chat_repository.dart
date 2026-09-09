import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/chat_message.dart';

/// 客服会话接口。
///
/// 搬迁自 vue_flamecloud/src/pages/console/UserCenter/ChatPage.vue 与
/// src/components/CustomerServiceButton.vue，接口路径、提交方式与轮询语义
/// 均与 Vue 端保持一致。
class ChatRepository {
  const ChatRepository(this._dio);

  final Dio _dio;

  /// 拉取全部历史消息。
  Future<List<ChatMessage>> fetchMessages() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.chat.list);
      return _messages(response);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 增量拉取新消息。
  ///
  /// [lastId] 为本地已收到的最大消息 id，首次传 0；返回空列表表示期间没有
  /// 新消息，对应 Vue 端 `pollMessages` 的 `last_id` 游标机制。
  Future<List<ChatMessage>> pollMessages({required int lastId}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.chat.poll,
        queryParameters: <String, Object?>{'last_id': lastId},
      );
      return _messages(response);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 发送一条消息。
  ///
  /// Vue 端以 multipart/form-data 提交 `content`，这里同样用 [FormData]；
  /// 发送成功后由调用方整体重拉列表，不在本地拼装临时消息。
  Future<void> sendMessage({required String content}) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.chat.send,
        data: FormData.fromMap(<String, Object?>{'content': content}),
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 客服是否在线，对应 Vue 端头部客服按钮的在线小圆点。
  Future<bool> fetchKfOnline() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.chat.kfOnline);
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      return JsonValue.boolean(data?['online']) ?? false;
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 解析消息列表，后端 data 为 nil 时会退化成 `[]`。
  List<ChatMessage> _messages(Response<dynamic> response) {
    final List<dynamic>? list = _unwrap(response).asList;
    if (list == null) {
      throw const ApiFormatException();
    }
    return list
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) =>
              ChatMessage.fromMap(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  ApiEnvelope _unwrap(Response<dynamic> response) {
    final Object? data = response.data;
    if (data is ApiEnvelope) {
      return data;
    }
    throw const ApiFormatException();
  }
}

/// 客服会话仓库实例。
final Provider<ChatRepository> chatRepositoryProvider =
    Provider<ChatRepository>((Ref ref) {
  return ChatRepository(ref.watch(dioProvider));
});
