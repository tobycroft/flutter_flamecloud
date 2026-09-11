import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/balance_log.dart';

/// 余额接口仓库。
///
/// 搬迁自 vue_flamecloud/BalanceLogPage：余额概览卡片 + 分页流水，
/// 接口路径与 API_ENDPOINTS.user.balance / balanceLog 保持一致。
class BalanceRepository {
  const BalanceRepository(this._dio);

  final Dio _dio;

  /// 拉取余额概览，对应 `GET /v1/user/balance`。
  Future<BalanceSummary> fetchSummary() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.balance,
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      return BalanceSummary.fromMap(data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取余额流水列表，对应 `GET /v1/user/balance/log`。
  ///
  /// [page] 页码从 1 开始；[keyword] 为空时不做描述过滤。
  /// 返回 data.list 与 data.total（真分页）。
  Future<BalanceLogResult> fetchLogs({
    required int page,
    int pageSize = 10,
    String? keyword,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.balanceLog,
        queryParameters: <String, Object?>{
          'page': page,
          'page_size': pageSize,
          'keyword': ?keyword,
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      final List<dynamic>? list = data?['list'] is List
          ? data!['list'] as List<dynamic>
          : null;
      final List<BalanceLogItem> items =
          list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    BalanceLogItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <BalanceLogItem>[];
      final int total = JsonValue.integer(data?['total']) ?? 0;
      return BalanceLogResult(items: items, total: total);
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

/// 余额仓库实例。
final Provider<BalanceRepository> balanceRepositoryProvider =
    Provider<BalanceRepository>((Ref ref) {
      return BalanceRepository(ref.watch(dioProvider));
    });
