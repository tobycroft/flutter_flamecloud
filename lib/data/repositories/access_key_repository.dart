import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/access_key.dart';

/// AccessKey 接口仓库。
///
/// 搬迁自 vue_flamecloud 的 AK 管理模块：列表、创建、启停、删除、
/// 权限读写与调用日志；接口路径与 API_ENDPOINTS.accessKey 保持一致。
/// 增改删共用 `POST /v1/user/access_key`，靠 `action` 参数区分。
class AccessKeyRepository {
  const AccessKeyRepository(this._dio);

  final Dio _dio;

  /// 拉取当前用户的 AK 列表，对应 `GET /v1/user/access_key`。
  Future<List<AccessKeyItem>> fetchList() async {
    try {
      final Response<dynamic> response =
          await _dio.get<dynamic>(ApiEndpoints.accessKey.list);
      final List<dynamic>? list = _unwrap(response).asList;
      return list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    AccessKeyItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <AccessKeyItem>[];
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 创建 AK，对应 `POST /v1/user/access_key`（action=create）。
  ///
  /// 成功返回 [AccessKeySecret]，`accessSecret` 仅此次返回，之后无法查询。
  Future<AccessKeySecret> createAk({required String name}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.accessKey.list,
        data: FormData.fromMap(<String, Object?>{
          'action': 'create',
          'name': name,
        }),
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiFormatException();
      }
      return AccessKeySecret(
        accessKey: JsonValue.string(data['access_key']) ?? '',
        accessSecret: JsonValue.string(data['access_secret']) ?? '',
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 启用/禁用 AK，对应 `POST /v1/user/access_key`（action=update）。
  Future<void> updateStatus({required int id, required bool enable}) async {
    await _postAction(<String, Object?>{
      'action': 'update',
      'id': id,
      'status': enable ? 1 : 0,
    });
  }

  /// 删除 AK，对应 `POST /v1/user/access_key`（action=delete）。
  Future<void> deleteAk({required int id}) async {
    await _postAction(<String, Object?>{'action': 'delete', 'id': id});
  }

  /// 统一提交 action 表单。
  Future<void> _postAction(Map<String, Object?> fields) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.accessKey.list,
        data: FormData.fromMap(fields),
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 读取 AK 权限，对应 `GET /v1/user/access_key/permission`。
  ///
  /// 返回 `resource_action` 组合集合，如 `ecs_read`、`billing_admin`。
  Future<Set<String>> fetchPermissions({required int akId}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.accessKey.permission,
        queryParameters: <String, Object?>{'ak_id': akId},
      );
      final List<dynamic>? list = _unwrap(response).asList;
      return list
              ?.whereType<Map<dynamic, dynamic>>()
              .map((Map<dynamic, dynamic> item) {
                final String resource =
                    JsonValue.string(item['resource']) ?? '';
                final String action = JsonValue.string(item['action']) ?? '';
                return '${resource}_$action';
              })
              .toSet() ??
          const <String>{};
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 保存 AK 权限，对应 `POST /v1/user/access_key/permission`。
  ///
  /// [grants] 的键为 `resource_action` 组合，值为是否授权；
  /// 与 Vue 端一致，每次全量提交资源（ecs/billing）× 动作（read/write/admin）。
  Future<void> savePermissions({
    required int akId,
    required Map<String, bool> grants,
  }) async {
    final Map<String, Object?> fields = <String, Object?>{'ak_id': akId};
    grants.forEach((String key, bool granted) {
      fields[key] = granted ? 1 : 0;
    });
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.accessKey.permission,
        data: FormData.fromMap(fields),
      );
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取 AK 调用日志，对应 `GET /v1/user/access_key/log`；
  /// [akId] 为空时查询全部 AK 的日志（`/log/all`）。
  ///
  /// 后端返回裸数组，无 total，分页沿用 Vue 端的隐式约定：
  /// 返回条数不足一页即视为最后一页。
  Future<List<AccessKeyLogItem>> fetchLogs({
    int? akId,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        akId == null
            ? ApiEndpoints.accessKey.logAll
            : ApiEndpoints.accessKey.log,
        queryParameters: <String, Object?>{
          'page': page,
          'ak_id': ?akId,
          'page_size': pageSize,
        },
      );
      final List<dynamic>? list = _unwrap(response).asList;
      return list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    AccessKeyLogItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <AccessKeyLogItem>[];
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

/// AccessKey 仓库实例。
final Provider<AccessKeyRepository> accessKeyRepositoryProvider =
    Provider<AccessKeyRepository>((Ref ref) {
  return AccessKeyRepository(ref.watch(dioProvider));
});
