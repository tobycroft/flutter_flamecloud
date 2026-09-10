import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/net/api_exception.dart';
import '../news_controller.dart';

/// 新闻公告详情页。
///
/// 正文为后端存储的 HTML 富文本，使用 flutter_html 渲染。
/// 为避免与 Web 端 vue_flamecloud 的 v-html 出现错位，这里通过 customStylesBuilder
/// 以 CSS 字符串约束排版，并强制图片宽度 100%（与 `src/styles/rich-text.css` 思路一致）。
class NewsDetailPage extends ConsumerWidget {
  const NewsDetailPage({required this.id, super.key});

  /// 公告 id（来自路由参数）。
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<NewsItem> asyncItem = ref.watch(newsDetailProvider(id));
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('公告详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: asyncItem.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => _ErrorView(message: _resolveError(error)),
        data: (NewsItem item) => _NewsDetailContent(item: item, isDark: isDark),
      ),
    );
  }

  static String _resolveError(Object error) {
    if (error is ApiException) {
      return error.message.isEmpty ? '公告不存在' : error.message;
    }
    if (error is NetworkException) return error.message;
    return '加载失败，请稍后重试';
  }
}

class _NewsDetailContent extends StatelessWidget {
  const _NewsDetailContent({required this.item, required this.isDark});

  final NewsItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark ? Colors.white70 : const Color(0xFF374151);
    final Color subColor = isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    final List<String> meta = <String>[
      if ((item.source ?? '').isNotEmpty) '来源：${item.source}',
      if ((item.author ?? '').isNotEmpty) '作者：${item.author}',
      if ((item.publishTime ?? '').isNotEmpty) item.publishTime!,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.title ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          if (meta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                meta.join('  ·  '),
                style: TextStyle(fontSize: 12, color: subColor),
              ),
            ),
          if ((item.coverImage ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(item.coverImage!),
              ),
            ),
          const SizedBox(height: 8),
          Html(
            data: item.content ?? '',
            customStylesBuilder: (element) =>
                _styleFor(element.localName, textColor, isDark),
            onLinkTap: (String? url, Map<String, String> attributes) {
              if (url != null) {
                unawaited(
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// 以 CSS 字符串约束每个 HTML 标签的样式，保证与 Web 端一致且响应式。
  static Map<String, String>? _styleFor(String? tag, Color textColor, bool isDark) {
    final String cssColor = _toCss(textColor);
    switch (tag) {
      case 'img':
        return <String, String>{
          'width': '100%',
          'height': 'auto',
          'border-radius': '8px',
        };
      case 'a':
        return <String, String>{
          'color': '#f97316',
          'text-decoration': 'underline',
        };
      case 'h1':
        return <String, String>{
          'font-size': '22px',
          'font-weight': 'bold',
          'color': cssColor,
          'margin': '16px 0 8px',
        };
      case 'h2':
        return <String, String>{
          'font-size': '19px',
          'font-weight': 'bold',
          'color': cssColor,
          'margin': '16px 0 8px',
        };
      case 'h3':
        return <String, String>{
          'font-size': '17px',
          'font-weight': 'bold',
          'color': cssColor,
          'margin': '14px 0 6px',
        };
      case 'p':
        return <String, String>{
          'color': cssColor,
          'margin': '8px 0',
          'line-height': '1.8',
        };
      case 'body':
        return <String, String>{
          'color': cssColor,
          'font-size': '15px',
          'line-height': '1.8',
        };
      case 'blockquote':
        return <String, String>{
          'border-left': '4px solid #fb923c',
          'background': isDark ? 'rgba(254,215,170,0.1)' : '#fff7ed',
          'color': isDark ? '#fdba74' : '#9a3412',
          'padding': '8px 12px',
          'border-radius': '0 8px 8px 0',
          'margin': '12px 0',
        };
      case 'code':
        return <String, String>{
          'background': isDark ? 'rgba(255,255,255,0.1)' : '#f3f4f6',
          'color': '#db2777',
          'padding': '1px 6px',
          'border-radius': '4px',
          'font-size': '13px',
        };
      case 'pre':
        return <String, String>{
          'background': '#1f2937',
          'color': '#f9fafb',
          'padding': '12px',
          'border-radius': '8px',
          'overflow-x': 'auto',
          'font-size': '13px',
        };
      case 'ul':
      case 'ol':
        return <String, String>{'padding-left': '20px', 'margin': '8px 0'};
      case 'li':
        return <String, String>{'margin': '4px 0'};
      case 'table':
        return <String, String>{
          'width': '100%',
          'border-collapse': 'collapse',
          'margin': '8px 0',
        };
      case 'th':
      case 'td':
        return <String, String>{
          'border': '1px solid ${isDark ? '#374151' : '#e5e7eb'}',
          'padding': '6px 10px',
          'text-align': 'left',
        };
      case 'hr':
        return <String, String>{
          'border': 'none',
          'border-top': '1px solid #374151',
          'margin': '16px 0',
        };
      default:
        return null;
    }
  }

  /// Color -> #RRGGBB。
  static String _toCss(Color c) {
    final int r = (c.r * 255).round() & 0xff;
    final int g = (c.g * 255).round() & 0xff;
    final int b = (c.b * 255).round() & 0xff;
    final String hex = r.toRadixString(16).padLeft(2, '0') +
        g.toRadixString(16).padLeft(2, '0') +
        b.toRadixString(16).padLeft(2, '0');
    return '#$hex';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}
