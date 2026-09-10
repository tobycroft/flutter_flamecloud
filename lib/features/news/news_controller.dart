import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../models/news.dart';
import '../repositories/news_repository.dart';

/// 新闻公告首页列表状态。
class NewsState {
  const NewsState({
    this.items = const <NewsItem>[],
    this.loading = false,
    this.errorMessage,
  });

  /// 公告条目。
  final List<NewsItem> items;

  /// 是否加载中。
  final bool loading;

  /// 加载失败提示（无错误时为 null）。
  final String? errorMessage;

  NewsState copyWith({
    List<NewsItem>? items,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NewsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 首页新闻公告控制器：拉取最新若干条已发布公告。
class NewsController extends Notifier<NewsState> {
  @override
  NewsState build() => const NewsState();

  /// 加载最新公告，默认取前 5 条用于首页展示。
  Future<void> load({int pageSize = 5}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final NewsListResult result = await ref
          .read(newsRepositoryProvider)
          .fetchList(page: 1, pageSize: pageSize);
      state = state.copyWith(items: result.items, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.message.isEmpty ? '新闻公告加载失败' : e.message,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    } on Exception {
      state = state.copyWith(loading: false, errorMessage: '新闻公告加载失败');
    }
  }
}

/// 首页新闻公告列表 Provider。
final NotifierProvider<NewsController, NewsState> newsControllerProvider =
    NotifierProvider<NewsController, NewsState>(NewsController.new);

/// 新闻公告详情 Provider（按 id 缓存，避免重复请求）。
final FutureProviderFamily<NewsItem, int> newsDetailProvider =
    FutureProvider.family<NewsItem, int>((Ref ref, int id) {
  return ref.read(newsRepositoryProvider).fetchDetail(id: id);
});
