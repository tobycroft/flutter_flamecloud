import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/net/api_exception.dart';
import '../../data/models/news.dart';
import 'news_controller.dart';

/// 新闻公告详情页。
///
/// 正文为后端存储的 HTML 富文本，使用 flutter_html 渲染。
/// 为避免与 Web 端（vue_flamecloud 的 v-html）出现错位：
///  - 图片强制 width:100% 自适应容器宽度；
///  - 通过 `style` 统一排版（字号/行高/颜色/间距），与 `src/styles/rich-text.css` 思路一致；
///  - 富文本作者端应避免固定像素宽度、flex 等复杂布局，以免两端错位。
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
            style: _htmlStyle(textColor, isDark),
            onLinkTap: (String? url, Map<String, String> attributes, _) {
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

  /// 与 Web 端 `src/styles/rich-text.css` 一致的富文本排版约束。
  static Map<String, Style> _htmlStyle(Color textColor, bool isDark) {
    final Color blockBg = isDark
        ? const Color(0x1AFFEDD6)
        : const Color(0xFFFFF7ED);
    final Color blockText = isDark
        ? const Color(0xFFFDBA74)
        : const Color(0xFF9A3412);
    final Color codeBg = isDark
        ? const Color(0x1AFFFFFF)
        : const Color(0xFFF3F4F6);
    final Color codeText = const Color(0xFFDB2777);
    final Color preBg = const Color(0xFF1F2937);
    final Color preText = const Color(0xFFF9FAFB);
    final Color borderColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);

    return <String, Style>{
      'body': Style(
        color: textColor,
        fontSize: FontSize(15),
        lineHeight: LineHeight(1.8),
        margin: Margins.zero,
      ),
      'p': Style(color: textColor, margin: Margins.symmetric(vertical: 8)),
      'h1': Style(
        fontSize: FontSize(22),
        fontWeight: FontWeight.bold,
        color: textColor,
        margin: Margins.only(top: 16, bottom: 8),
      ),
      'h2': Style(
        fontSize: FontSize(19),
        fontWeight: FontWeight.bold,
        color: textColor,
        margin: Margins.only(top: 16, bottom: 8),
      ),
      'h3': Style(
        fontSize: FontSize(17),
        fontWeight: FontWeight.bold,
        color: textColor,
        margin: Margins.only(top: 14, bottom: 6),
      ),
      'a': Style(
        color: const Color(0xFFF97316),
        textDecoration: TextDecoration.underline,
      ),
      // 图片宽度自适应容器，避免 App 端溢出/与 Web 端错位。
      'img': Style(width: Width(100, Unit.percent)),
      'blockquote': Style(
        backgroundColor: blockBg,
        color: blockText,
        border: Border(left: BorderSide(color: const Color(0xFFFB923C), width: 4)),
        padding: HtmlPaddings.all(12),
        margin: Margins.symmetric(vertical: 12),
      ),
      'code': Style(
        backgroundColor: codeBg,
        color: codeText,
        padding: HtmlPaddings.all(4),
        fontSize: FontSize(13),
      ),
      'pre': Style(
        backgroundColor: preBg,
        color: preText,
        padding: HtmlPaddings.all(12),
        margin: Margins.symmetric(vertical: 8),
        fontSize: FontSize(13),
      ),
      'ul': Style(
        padding: HtmlPaddings.only(left: 20),
        margin: Margins.symmetric(vertical: 8),
      ),
      'ol': Style(
        padding: HtmlPaddings.only(left: 20),
        margin: Margins.symmetric(vertical: 8),
      ),
      'li': Style(margin: Margins.symmetric(vertical: 4), color: textColor),
      'table': Style(
        width: Width(100, Unit.percent),
        margin: Margins.symmetric(vertical: 8),
      ),
      'th': Style(
        border: Border.all(color: borderColor),
        padding: HtmlPaddings.all(6),
        color: textColor,
      ),
      'td': Style(
        border: Border.all(color: borderColor),
        padding: HtmlPaddings.all(6),
        color: textColor,
      ),
    };
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
