import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/notification.dart';

/// 站内通知接口。
///
/// 搬迁自 go_flamecloud 的 notificationController：拉取通知列表、标记已读等，
/// 接口路径与 vue_flamecloud 的 API_ENDPOINTS.notification 保持一致。
class NotificationRepository {
  const NotificationRepository(this._dio);

  final Dio _dio;

  /// 拉取通知列表。
  ///
  /// [page] 页码（默认 1），[pageSize] 每页数量（默认 20）；
  /// 返回通知项与未读总数，对应 `GET /v1/notification/list` 的
  /// data.list 与 data.unread。
  Future<NotificationList> fetchList({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.notification.list,
        queryParameters: <String, Object?>{
          'page': page,
          'page_size': pageSize,
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      final List<dynamic>? list =
          data?['list'] is List ? data!['list'] as List<dynamic> : null;
      final List<NotificationItem> items = list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    NotificationItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <NotificationItem>[];
      final int unread = JsonValue.integer(data?['unread']) ?? 0;
      return NotificationList(items: items, unread: unread);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 标记单条通知已读，对应 `POST /v1/notification/read`。
  Future<void> markRead({required int id}) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.notification.read,
        data: FormData.fromMap(<String, Object?>{'id': id}),
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
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

/// 通知列表与未读总数。
class NotificationList {
  const NotificationList({required this.items, required this.unread});

  /// 通知列表，后端按 id 倒序返回（最新在前）。
  final List<NotificationItem> items;

  /// 未读总数。
  final int unread;
}

/// 站内通知仓库实例。
final Provider<NotificationRepository> notificationRepositoryProvider =
    Provider<NotificationRepository>((Ref ref) {
  return NotificationRepository(ref.watch(dioProvider));
});
