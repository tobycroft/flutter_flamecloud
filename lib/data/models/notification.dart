import '../../core/utils/json_value.dart';

/// 站内通知。
///
/// 对应 `GET /v1/notification/list` 返回 data.list 中的元素，
/// 字段与 go_flamecloud 的 `fc_user_notification` 表保持一致。
class NotificationItem {
  const NotificationItem({
    required this.id,
    this.uid,
    required this.title,
    this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  /// 从接口 data.list 的元素构造。
  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: JsonValue.integer(map['id']) ?? 0,
      uid: JsonValue.string(map['uid']),
      title: JsonValue.string(map['title']) ?? '',
      content: JsonValue.string(map['content']),
      type: JsonValue.string(map['type']) ?? 'info',
      isRead: JsonValue.integer(map['is_read']) ?? 0,
      createdAt: JsonValue.string(map['created_at']) ?? '',
    );
  }

  /// 通知 id。
  final int id;

  /// 接收用户 id。
  final String? uid;

  /// 标题。
  final String title;

  /// 正文内容，可能为空。
  final String? content;

  /// 类型：info / success / warning / system。
  final String type;

  /// 是否已读：0=未读，1=已读，对应后端 `is_read`。
  final int isRead;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 是否已读。
  bool get read => isRead == 1;

  /// 关联的工单 id。
  ///
  /// 后端通知表没有 related_type/related_id 字段，与 Vue 端一致，
  /// 通过标题或正文中的 `#数字` 提取（如「工单 #1 有新的回复」）。
  int? get relatedTicketId {
    final RegExp pattern = RegExp(r'#(\d+)');
    final Iterable<RegExpMatch> titleMatches = pattern.allMatches(title);
    for (final RegExpMatch match in titleMatches) {
      final int? id = int.tryParse(match.group(1) ?? '');
      if (id != null) {
        return id;
      }
    }
    final String? text = content;
    if (text == null) {
      return null;
    }
    for (final RegExpMatch match in pattern.allMatches(text)) {
      final int? id = int.tryParse(match.group(1) ?? '');
      if (id != null) {
        return id;
      }
    }
    return null;
  }
}
