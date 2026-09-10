import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../models/news.dart';

/// 新闻公告接口仓库。
///
/// 对应 go_flamecloud 的 news 公开读接口（无需登录），与 vue_flamecloud 的
/// API_ENDPOINTS.news 保持一致。
class NewsRepository {
  const NewsRepository(this._dio);

  final Dio _dio;

  /// 拉取新闻公告列表，对应 `GET /v1/news/list`。
  ///
  /// [page] 页码（默认 1），[pageSize] 每页数量（默认 10，最大 50）。
  Future<NewsListResult> fetchList({int page = 1, int pageSize = 10}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.news.list,
        queryParameters: <String, Object?>{
          'page': page,
          'page_size': pageSize,
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      final List<dynamic>? list =
          data?['list'] is List ? data!['list'] as List<dynamic> : null;
      final List<NewsItem> items = list
              ?.whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    NewsItem.fromMap(item.cast<String, dynamic>()),
              )
              .toList(growable: false) ??
          const <NewsItem>[];
      final int total = JsonValue.integer(data?['total']) ?? 0;
      return NewsListResult(items: items, total: total);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 拉取新闻公告详情（含富文本 content），对应 `GET /v1/news/detail`。
  ///
  /// 不存在或已隐藏时后端返回非 0 code，由上层（异常）统一提示。
  Future<NewsItem> fetchDetail({required int id}) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.news.detail,
        queryParameters: <String, Object?>{'id': id},
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiException(-1, '公告不存在');
      }
      return NewsItem.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 解析统一响应包（拦截器已把 JSON 转成 [ApiEnvelope]，非 0 code 会直接抛异常）。
  ApiEnvelope _unwrap(Response<dynamic> response) {
    final Object? data = response.data;
    if (data is ApiEnvelope) {
      return data;
    }
    throw const ApiFormatException();
  }
}

/// 新闻公告列表结果。
class NewsListResult {
  const NewsListResult({required this.items, required this.total});

  /// 本页公告条目。
  final List<NewsItem> items;

  /// 已发布公告总数。
  final int total;
}

/// 新闻公告仓库 Provider。
final Provider<NewsRepository> newsRepositoryProvider =
    Provider<NewsRepository>((Ref ref) => NewsRepository(ref.watch(dioProvider)));
