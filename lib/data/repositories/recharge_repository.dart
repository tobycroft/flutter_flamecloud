import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/recharge_order.dart';

/// 充值订单接口仓库。
///
/// 搬迁自 vue_flamecloud/RechargeOrdersPage：订单号搜索 + 真分页，
/// 接口路径与 API_ENDPOINTS.user.recharge.orders 保持一致。
class RechargeRepository {
  const RechargeRepository(this._dio);

  final Dio _dio;

  /// 拉取充值订单列表，对应 `GET /v1/user/recharge/orders`。
  ///
  /// [page] 页码从 1 开始；[keyword] 为空时不做订单号过滤。
  /// 返回 data.list 与 data.total（真分页）。
  Future<RechargeOrderResult> fetchOrders({
    required int page,
    int pageSize = 10,
    String? keyword,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.rechargeOrders,
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
      final List<RechargeOrderItem> items =
          list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    RechargeOrderItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <RechargeOrderItem>[];
      final int total = JsonValue.integer(data?['total']) ?? 0;
      return RechargeOrderResult(items: items, total: total);
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

/// 充值订单仓库实例。
final Provider<RechargeRepository> rechargeRepositoryProvider =
    Provider<RechargeRepository>((Ref ref) {
      return RechargeRepository(ref.watch(dioProvider));
    });
