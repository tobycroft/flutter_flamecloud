import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../data/models/news.dart';
import '../../data/repositories/news_repository.dart';

/// 新闻公告列表页（对应 Vue 端「新闻公告」列表页）。
class NewsListPage extends ConsumerStatefulWidget {
  const NewsListPage({super.key});

  @override
  ConsumerState<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends ConsumerState<NewsListPage> {
  final List<NewsItem> _items = <NewsItem>[];
  int _page = 1;
  final int _pageSize = 20;
  bool _loading = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (_finished && !reset)) return;
    setState(() => _loading = true);
    try {
      final int page = reset ? 1 : _page;
      final NewsListResult result = await ref
          .read(newsRepositoryProvider)
          .fetchList(page: page, pageSize: _pageSize);
      setState(() {
        if (reset) _items.clear();
        _items.addAll(result.items);
        _page = page + 1;
        _finished = result.items.length < _pageSize;
      });
    } on Exception {
      // 忽略单页错误，保留已加载内容，不阻断浏览。
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('新闻公告')),
      body: _items.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('暂无公告', style: TextStyle(color: Colors.grey)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length + (_finished ? 0 : 1),
                  separatorBuilder: (_, _) => Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == _items.length) {
                      return TextButton(
                        onPressed: () => _load(),
                        child: const Text('加载更多'),
                      );
                    }
                    final NewsItem item = _items[index];
                    return ListTile(
                      title: Text(item.title ?? ''),
                      subtitle: Text(
                        item.dateLabel,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.newsDetail,
                        arguments: item.id,
                      ),
                    );
                  },
                ),
    );
  }
}
