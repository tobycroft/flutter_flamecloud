import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/bill.dart';

/// 账单接口仓库。
///
/// 搬迁自 vue_flamecloud/BillPage：账单号/实例/产品搜索 + 真分页，
/// 接口路径与 API_ENDPOINTS.user.bill.* 保持一致。
class BillRepository {
  const BillRepository(this._dio);

  final Dio _dio;

  /// 拉取账单列表，对应 `GET /v1/user/bill/list`。
  ///
  /// [page] 页码从 1 开始；[status]/[moduleType]/[period] 传 `'all'` 或不传表示不过滤；
  /// [keyword] 为空时不做过滤。返回 data.list 与 data.total（真分页）。
  Future<BillResult> fetchBills({
    required int page,
    int pageSize = 10,
    String? status,
    String? moduleType,
    String? period,
    String? keyword,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.billList,
        queryParameters: <String, Object?>{
          'page': page,
          'page_size': pageSize,
          'status': ?status,
          'module_type': ?moduleType,
          'period': ?period,
          'keyword': ?keyword,
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      final List<dynamic>? list = data?['list'] is List
          ? data!['list'] as List<dynamic>
          : null;
      final List<BillItem> items =
          list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    BillItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <BillItem>[];
      final int total = JsonValue.integer(data?['total']) ?? 0;
      return BillResult(items: items, total: total);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 账单详情，对应 `GET /v1/user/bill/detail`。
  Future<BillItem> fetchBillDetail(int id) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.billDetail,
        queryParameters: <String, Object?>{'id': id},
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiFormatException();
      }
      return BillItem.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 生成账单（按实例出账），对应 `POST /v1/user/bill/generate`。
  ///
  /// [period] 账期 YYYY-MM，为空时后端取当前月。返回生成条数。
  Future<BillGenerateResult> generateBills({String? period}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.user.billGenerate,
        data: FormData.fromMap(<String, Object?>{
          if (period != null && period.isNotEmpty) 'period': period,
        }),
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      return BillGenerateResult(
        period: JsonValue.string(data?['period']) ?? '',
        generated: JsonValue.integer(data?['generated']) ?? 0,
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 可用账期列表，对应 `GET /v1/user/bill/periods`。
  Future<List<String>> fetchPeriods() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.billPeriods,
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      final List<dynamic>? list = data?['list'] is List
          ? data!['list'] as List<dynamic>
          : null;
      final List<String> periods =
          list
              ?.whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> e) {
                final String? p = JsonValue.string(e['period']);
                return p ?? '';
              })
              .where((String p) => p.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      return periods;
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 账单汇总，对应 `GET /v1/user/bill/summary`。
  Future<BillSummary> fetchSummary({String? period}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.billSummary,
        queryParameters: <String, Object?>{
          'period': ?period,
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      return BillSummary(
        totalSettlement: JsonValue.string(data?['total_settlement']) ?? '0',
        billCount: JsonValue.integer(data?['bill_count']) ?? 0,
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

/// 账单仓库实例。
final Provider<BillRepository> billRepositoryProvider =
    Provider<BillRepository>((Ref ref) {
      return BillRepository(ref.watch(dioProvider));
    });

/// 账单分页结果。
class BillResult {
  const BillResult({required this.items, required this.total});

  /// 当前页账单。
  final List<BillItem> items;

  /// 总条数。
  final int total;
}

/// 生成账单结果。
class BillGenerateResult {
  const BillGenerateResult({required this.period, required this.generated});

  /// 出账账期。
  final String period;

  /// 新生成条数。
  final int generated;
}

/// 账单汇总。
class BillSummary {
  const BillSummary({required this.totalSettlement, required this.billCount});

  /// 结算总额（字符串，保留两位小数）。
  final String totalSettlement;

  /// 账单条数。
  final int billCount;

  /// 结算总额展示：固定两位小数并加 ¥。
  String get totalText {
    final double? value = JsonValue.decimal(totalSettlement);
    return value == null ? totalSettlement : '¥${value.toStringAsFixed(2)}';
  }
}
