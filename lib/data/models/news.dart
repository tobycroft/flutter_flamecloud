import '/core/utils/json_value.dart';

/// 新闻公告条目。
///
/// 列表与详情共用：列表项 [content] 为 null，详情含富文本 [content]（HTML 字符串）。
class NewsItem {
  const NewsItem({
    required this.id,
    this.title,
    this.summary,
    this.coverImage,
    this.source,
    this.author,
    this.publishTime,
    this.content,
  });

  /// 从后端 map 容错构造，字段缺失/类型不符时使用默认值，避免单条脏数据导致整页崩溃。
  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      id: JsonValue.integer(map['id']) ?? 0,
      title: JsonValue.string(map['title']),
      summary: JsonValue.string(map['summary']),
      coverImage: JsonValue.string(map['cover_image']),
      source: JsonValue.string(map['source']),
      author: JsonValue.string(map['author']),
      publishTime: JsonValue.string(map['publish_time']),
      content: JsonValue.string(map['content']),
    );
  }

  /// 主键。
  final int id;

  /// 标题。
  final String? title;

  /// 摘要。
  final String? summary;

  /// 封面图地址。
  final String? coverImage;

  /// 来源。
  final String? source;

  /// 发布人。
  final String? author;

  /// 发布时间（后端返回 `Y-m-d H:i:s` 或 ISO 字符串）。
  final String? publishTime;

  /// 富文本正文（HTML），仅详情接口返回。
  final String? content;

  /// 列表展示用的日期标签（取发布时间前 10 位，如 2025-07-20）。
  String get dateLabel {
    final String raw = publishTime ?? '';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }
}
