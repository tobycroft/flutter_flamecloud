import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/ecs.dart';
import '../models/ecs_instance.dart';

/// 云服务器接口仓库。
///
/// 搬迁自 vue_flamecloud 的 EcsBuyPage / EcsPayPage：
/// 配置类接口统一走 GET + query（与后端 queryOrPost* 兼容），
/// 下单 / 详情 / 支付走 POST 表单（dio 已默认 form-urlencoded）。
class EcsRepository {
  const EcsRepository(this._dio);

  final Dio _dio;

  /// 解析统一响应包。
  ApiEnvelope _unwrap(Response<dynamic> response) {
    final Object? data = response.data;
    if (data is ApiEnvelope) {
      return data;
    }
    throw const ApiFormatException();
  }

  /// 从 envelope 的 data.list 解析出实体列表。
  List<T> _parseList<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    final Map<String, dynamic>? data = _unwrap(response).asMap;
    final List<dynamic>? list =
        data?['list'] is List ? data!['list'] as List<dynamic> : null;
    if (list == null) {
      return <T>[];
    }
    return list
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> item) =>
            fromMap(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// 拉取地域列表，对应 `GET /v1/ecs/config/regions`。
  Future<List<EcsRegion>> fetchRegions() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.ecs.config.regions);
      return _parseList(response, EcsRegion.fromMap);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取指定地域下的可用区，对应 `GET /v1/ecs/config/zones`。
  Future<List<EcsZone>> fetchZones(int regionId) async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.ecs.config.zones, queryParameters: <String, Object?>{
        'region_id': regionId,
      });
      return _parseList(response, EcsZone.fromMap);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取指定地域/可用区下的可选规格，对应 `GET /v1/ecs/config/specs`。
  Future<List<EcsSpec>> fetchSpecs({
    required int regionId,
    int? zoneId,
  }) async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.ecs.config.specs, queryParameters: <String, Object?>{
        'region_id': regionId,
        if (zoneId != null) 'zone_id': zoneId,
      });
      return _parseList(response, EcsSpec.fromMap);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取购买周期与折扣配置，对应 `GET /v1/ecs/config/periods`。
  Future<List<EcsPeriod>> fetchPeriods() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.ecs.config.periods);
      return _parseList(response, EcsPeriod.fromMap);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 计算当前配置总价，对应 `GET /v1/ecs/config/price`。
  ///
  /// [params] 由上层按当前选择拼装（地域/可用区/规格/带宽/数量/周期/数据盘/镜像）。
  Future<EcsPrice> fetchPrice(Map<String, Object?> params) async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.ecs.config.price, queryParameters: params);
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiException(0, '价格计算失败');
      }
      return EcsPrice.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 创建 ECS 订单，对应 `POST /v1/ecs/order/create`。
  ///
  /// [params] 为表单字段（含 total_price），返回创建的订单（含 id）。
  Future<EcsOrder> createOrder(Map<String, Object?> params) async {
    try {
      final Response<dynamic> response =
          await _dio.post<dynamic>(ApiEndpoints.ecs.order.create, data: params);
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiException(0, '订单创建失败');
      }
      return EcsOrder.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取订单详情，对应 `POST /v1/ecs/order/detail`。
  Future<EcsOrder> fetchOrderDetail(int id) async {
    try {
      final Response<dynamic> response =
          await _dio.post<dynamic>(ApiEndpoints.ecs.order.detail, data: <String, Object?>{
        'id': id,
      });
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiException(0, '获取订单详情失败');
      }
      return EcsOrder.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 发起支付，对应 `POST /v1/ecs/order/pay`。
  Future<EcsPayResult> payOrder({
    required int orderId,
    required String payMethod,
  }) async {
    try {
      final Response<dynamic> response =
          await _dio.post<dynamic>(ApiEndpoints.ecs.order.pay, data: <String, Object?>{
        'order_id': orderId,
        'pay_method': payMethod,
      });
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiException(0, '支付失败');
      }
      return EcsPayResult.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取当前用户的 ECS 实例列表，对应 `GET /v1/ecs/instance/list`。
  ///
  /// 后端按 uid 返回该用户全部实例（无分页），由上层做搜索/地域筛选。
  Future<List<EcsInstance>> fetchInstances() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.ecs.instance.list);
      return _parseList(response, EcsInstance.fromMap);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取账户余额，对应 `GET /v1/user/balance`。
  ///
  /// 余额以原始字符串返回（如 "1234.50"），由上层做数值比较。
  Future<String> fetchBalance() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.user.balance);
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      return JsonValue.string(data?['balance']) ?? '0.00';
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }
}

/// 云服务器仓库实例。
final Provider<EcsRepository> ecsRepositoryProvider =
    Provider<EcsRepository>((Ref ref) {
  return EcsRepository(ref.watch(dioProvider));
});

/// 将当前数据盘列表序列化为下单/询价所需的 JSON 字符串。
///
/// 后端仅读取其中的 `size` 字段做计费，这里同时带上 `type` 以便服务端落库。
String encodeDataDisks(List<EcsDataDisk> disks) {
  final List<Map<String, Object?>> payload = disks
      .map((EcsDataDisk disk) => <String, Object?>{
            'size': disk.size,
            'type': disk.type,
          })
      .toList(growable: false);
  return jsonEncode(payload);
}
