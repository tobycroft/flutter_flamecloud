import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_update_config.dart';
import '../../core/utils/json_value.dart';
import '../models/app_release.dart';

/// 自动更新仓库。
///
/// Gitee API 与后端网关不是同一套体系（无统一 envelope、无需鉴权头），
/// 因此不复用全局 dioProvider，使用独立的裸 dio 实例。
class AppUpdateRepository {
  AppUpdateRepository() : _dio = _createDio();

  final Dio _dio;

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
        headers: <String, Object?>{
          Headers.acceptHeader: 'application/json',
        },
      ),
    );
  }

  /// 拉取 Gitee 最新 release。
  ///
  /// 网络异常、接口限流等情况直接抛出，由上层决定如何降级。
  Future<AppRelease> fetchLatestRelease() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      AppUpdateConfig.latestReleaseApi,
      queryParameters: AppUpdateConfig.accessToken.isEmpty
          ? null
          : <String, dynamic>{'access_token': AppUpdateConfig.accessToken},
    );
    final Object? data = response.data;
    if (data is! Map) {
      throw const AppUpdateFormatException();
    }
    final Map<String, dynamic> map = data.cast<String, dynamic>();
    final String tagName = (JsonValue.string(map['tag_name']) ?? '').trim();
    if (tagName.isEmpty) {
      throw const AppUpdateFormatException();
    }
    // Gitee 接口不返回 html_url，缺省时用标签拼出 release 详情页。
    return AppRelease.fromMap(
      map,
      fallbackPageUrl: AppUpdateConfig.releaseTagUrl(tagName),
    );
  }

  void dispose() {
    _dio.close();
  }
}

/// Gitee 响应格式异常。
class AppUpdateFormatException implements Exception {
  const AppUpdateFormatException();
}

/// 自动更新仓库实例。
final Provider<AppUpdateRepository> appUpdateRepositoryProvider =
    Provider<AppUpdateRepository>((Ref ref) {
  final AppUpdateRepository repository = AppUpdateRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
