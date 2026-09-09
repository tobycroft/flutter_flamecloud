import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/action_log.dart';

/// 操作日志接口仓库。
///
/// 搬迁自 vue_flamecloud 的操作日志模块：类型字典与分页列表；
/// 接口路径与 API_ENDPOINTS.actionLog 保持一致。
class ActionLogRepository {
  const ActionLogRepository(this._dio);

  final Dio _dio;

  /// 拉取日志类型字典，对应 `GET /v1/actionlog/type`。
  Future<List<ActionLogType>> fetchTypes() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.actionLog.type);
      final List<dynamic>? list = _unwrap(response).asList;
      return list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    ActionLogType.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <ActionLogType>[];
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取操作日志列表，对应 `GET /v1/actionlog/list`。
  ///
  /// [page] 页码从 1 开始；[typeId] 为空时查询全部类型。
  /// 返回 data.list 与 data.total（真分页）。
  Future<ActionLogPage> fetchLogs({
    required int page,
    int pageSize = 20,
    int? typeId,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.actionLog.list,
        queryParameters: <String, Object?>{
          'page': page,
          'page_size': pageSize,
          'log_type_id': ?typeId,
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      final List<dynamic>? list =
          data?['list'] is List ? data!['list'] as List<dynamic> : null;
      final List<ActionLogItem> items = list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    ActionLogItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <ActionLogItem>[];
      final int total = JsonValue.integer(data?['total']) ?? 0;
      return ActionLogPage(items: items, total: total);
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

/// 操作日志仓库实例。
final Provider<ActionLogRepository> actionLogRepositoryProvider =
    Provider<ActionLogRepository>((Ref ref) {
  return ActionLogRepository(ref.watch(dioProvider));
});
