import '../../core/utils/json_value.dart';

/// 客服会话消息。
///
/// 对应 `GET /v1/chat/list` 与 `GET /v1/chat/poll` 返回 data 的元素，
/// 字段与 vue_flamecloud/src/pages/console/UserCenter/ChatPage.vue 中的
/// ChatMessage 接口保持一致。
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isAdmin,
    required this.createdAt,
    this.uid,
    this.adminName,
  });

  /// 从接口 data 构造。
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: JsonValue.integer(map['id']) ?? 0,
      uid: JsonValue.string(map['uid']),
      content: JsonValue.string(map['content']) ?? '',
      isAdmin: JsonValue.integer(map['is_admin']) ?? 0,
      adminName: JsonValue.string(map['admin_name']),
      createdAt: JsonValue.string(map['created_at']) ?? '',
    );
  }

  /// 消息 id，同时作为增量轮询的 last_id 游标。
  final int id;

  /// 发送者用户 id。
  final String? uid;

  /// 消息内容。
  final String content;

  /// 发送方标识：0=用户自己，1=客服/管理员，与后端 `is_admin` 一致。
  final int isAdmin;

  /// 客服名称，[fromAdmin] 为真时用于气泡上方展示。
  final String? adminName;

  /// 发送时间，后端返回的原始时间串。
  final String createdAt;

  /// 是否客服发出的消息。
  bool get fromAdmin => isAdmin == 1;

  /// 展示用发送者名称。
  ///
  /// 客服侧取 [adminName]，缺省回落“客服”，与 Vue 端取值一致。
  String get senderName => adminName ?? '客服';
}
