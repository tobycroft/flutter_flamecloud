import '../../core/utils/json_value.dart';

/// 工单列表项。
///
/// 对应 `POST /v1/ticket/list` 返回 data.list 中的元素，
/// 字段与 go_flamecloud 的 `fc_ticket` 表保持一致。
class TicketItem {
  const TicketItem({
    required this.id,
    required this.description,
    required this.category,
    required this.status,
    required this.ticketType,
    required this.createdAt,
    required this.urgency,
  });

  /// 从接口返回的元素构造。
  factory TicketItem.fromMap(Map<String, dynamic> map) {
    return TicketItem(
      id: JsonValue.integer(map['id']) ?? 0,
      description: JsonValue.string(map['description']) ?? '',
      category: JsonValue.string(map['category']) ?? '',
      status: JsonValue.integer(map['status']) ?? 0,
      ticketType: JsonValue.string(map['ticket_type']) ?? 'standard',
      createdAt: JsonValue.string(map['created_at']) ?? '',
      urgency: JsonValue.string(map['urgency']) ?? '',
    );
  }

  /// 工单 id。
  final int id;

  /// 问题描述。
  final String description;

  /// 问题分类 key：ecs / oss / chat ...
  final String category;

  /// 状态：0 待回复、1 客户发送、2 客服答复、3 结案关闭。
  final int status;

  /// 工单类型：standard / chat。
  final String ticketType;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 紧急性：fault / usage / consult。
  final String urgency;

  /// 展示用时间：ISO 串的 `T` 换成空格并截到秒。
  String get displayTime {
    final String text = createdAt.replaceFirst('T', ' ');
    return text.length > 19 ? text.substring(0, 19) : text;
  }
}

/// 工单列表分页结果。
///
/// 后端同时返回两个聚合计数：[processing] 为「服务中」（0+1+2），
/// [confirm] 为「待您确认结果」（客服已答复，即 2）。
class TicketListResult {
  const TicketListResult({
    required this.items,
    required this.total,
    required this.processing,
    required this.confirm,
  });

  /// 当前页工单列表。
  final List<TicketItem> items;

  /// 总条数。
  final int total;

  /// 服务中数量。
  final int processing;

  /// 待确认数量。
  final int confirm;
}

/// 工单主体信息。
///
/// 对应 `GET /v1/ticket/detail` 返回 data.info。
class TicketInfo {
  const TicketInfo({
    required this.id,
    required this.uid,
    required this.description,
    required this.category,
    required this.otherCategory,
    required this.urgency,
    required this.status,
    required this.contactPhone,
    required this.ticketType,
    required this.lastReplyAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从接口返回的元素构造。
  factory TicketInfo.fromMap(Map<String, dynamic> map) {
    return TicketInfo(
      id: JsonValue.integer(map['id']) ?? 0,
      uid: JsonValue.integer(map['uid']) ?? 0,
      description: JsonValue.string(map['description']) ?? '',
      category: JsonValue.string(map['category']) ?? '',
      otherCategory: JsonValue.string(map['other_category']) ?? '',
      urgency: JsonValue.string(map['urgency']) ?? '',
      status: JsonValue.integer(map['status']) ?? 0,
      contactPhone: JsonValue.string(map['contact_phone']) ?? '',
      ticketType: JsonValue.string(map['ticket_type']) ?? 'standard',
      lastReplyAt: JsonValue.string(map['last_reply_at']) ?? '',
      createdAt: JsonValue.string(map['created_at']) ?? '',
      updatedAt: JsonValue.string(map['updated_at']) ?? '',
    );
  }

  /// 工单 id。
  final int id;

  /// 归属用户 id。
  final int uid;

  /// 问题描述。
  final String description;

  /// 问题分类 key。
  final String category;

  /// 其他分类备注。
  final String otherCategory;

  /// 紧急性：fault / usage / consult。
  final String urgency;

  /// 状态：0/1/2/3。
  final int status;

  /// 联系手机。
  final String contactPhone;

  /// 工单类型：standard / chat。
  final String ticketType;

  /// 最后回复时间，兼作轮询游标。
  final String lastReplyAt;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 更新时间，后端返回的原始时间串。
  final String updatedAt;

  /// 是否已结案关闭（status = 3）。
  bool get closed => status == 3;

  /// 展示用时间：ISO 串的 `T` 换成空格并截到秒。
  String get displayTime {
    final String text = createdAt.replaceFirst('T', ' ');
    return text.length > 19 ? text.substring(0, 19) : text;
  }
}

/// 工单回复。
///
/// 对应 `GET /v1/ticket/detail` 返回 data.replies 中的元素；
/// [isAdmin] 为 1 时表示客服发言（当前 Go 端只写 0，
/// 客服回复由后台服务直写库）。
class TicketReply {
  const TicketReply({
    required this.id,
    required this.ticketId,
    required this.uid,
    required this.content,
    required this.isAdmin,
    required this.createdAt,
    this.attachments = const <TicketAttachment>[],
  });

  /// 从接口返回的元素构造。
  factory TicketReply.fromMap(Map<String, dynamic> map) {
    return TicketReply(
      id: JsonValue.integer(map['id']) ?? 0,
      ticketId: JsonValue.integer(map['ticket_id']) ?? 0,
      uid: JsonValue.integer(map['uid']) ?? 0,
      content: JsonValue.string(map['content']) ?? '',
      isAdmin: JsonValue.integer(map['is_admin']) ?? 0,
      createdAt: JsonValue.string(map['created_at']) ?? '',
      attachments: TicketAttachment.fromList(map['attachments']),
    );
  }

  /// 回复 id。
  final int id;

  /// 所属工单 id。
  final int ticketId;

  /// 发言人 uid。
  final int uid;

  /// 回复正文。
  final String content;

  /// 是否客服：0 客户、1 客服。
  final int isAdmin;

  /// 创建时间，后端返回的原始时间串。
  final String createdAt;

  /// 该回复挂载的附件。
  final List<TicketAttachment> attachments;

  /// 是否客服发言。
  bool get fromAdmin => isAdmin == 1;

  /// 展示用时间：ISO 串的 `T` 换成空格并截到秒。
  String get displayTime {
    final String text = createdAt.replaceFirst('T', ' ');
    return text.length > 19 ? text.substring(0, 19) : text;
  }
}

/// 工单附件。
class TicketAttachment {
  const TicketAttachment({
    required this.id,
    required this.ticketId,
    required this.name,
    required this.url,
    required this.hash,
  });

  /// 从接口返回的元素构造。
  factory TicketAttachment.fromMap(Map<String, dynamic> map) {
    return TicketAttachment(
      id: JsonValue.integer(map['id']) ?? 0,
      ticketId: JsonValue.integer(map['ticket_id']) ?? 0,
      name: JsonValue.string(map['name']) ?? '',
      url: JsonValue.string(map['url']) ?? '',
      hash: JsonValue.string(map['hash']) ?? '',
    );
  }

  /// 解析附件数组，类型不匹配时返回空数组。
  static List<TicketAttachment> fromList(Object? value) {
    if (value is! List) {
      return const <TicketAttachment>[];
    }
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) =>
              TicketAttachment.fromMap(item.cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  /// 附件 id。
  final int id;

  /// 所属工单 id。
  final int ticketId;

  /// 文件名。
  final String name;

  /// 访问地址。
  final String url;

  /// 文件 hash。
  final String hash;

  /// 是否为图片（按扩展名判断，详情页据此渲染缩略图）。
  bool get isImage =>
      RegExp(r'\.(jpg|jpeg|gif|png|bmp|webp)$', caseSensitive: false)
          .hasMatch(name);
}

/// 工单关联链接。
class TicketLink {
  const TicketLink({
    required this.id,
    required this.ticketId,
    required this.url,
    required this.text,
  });

  /// 从接口返回的元素构造。
  factory TicketLink.fromMap(Map<String, dynamic> map) {
    return TicketLink(
      id: JsonValue.integer(map['id']) ?? 0,
      ticketId: JsonValue.integer(map['ticket_id']) ?? 0,
      url: JsonValue.string(map['url']) ?? '',
      text: JsonValue.string(map['text']) ?? '',
    );
  }

  /// 链接 id。
  final int id;

  /// 所属工单 id。
  final int ticketId;

  /// 链接地址。
  final String url;

  /// 展示文本。
  final String text;
}

/// 工单联系方式。
class TicketContact {
  const TicketContact({
    required this.id,
    required this.ticketId,
    required this.type,
    required this.value,
    required this.label,
  });

  /// 从接口返回的元素构造。
  factory TicketContact.fromMap(Map<String, dynamic> map) {
    return TicketContact(
      id: JsonValue.integer(map['id']) ?? 0,
      ticketId: JsonValue.integer(map['ticket_id']) ?? 0,
      type: JsonValue.string(map['type']) ?? '',
      value: JsonValue.string(map['value']) ?? '',
      label: JsonValue.string(map['label']) ?? '',
    );
  }

  /// 联系方式 id。
  final int id;

  /// 所属工单 id。
  final int ticketId;

  /// 类型：phone / email。
  final String type;

  /// 具体值。
  final String value;

  /// 展示标签，形如「手机(138xxx) 09:00-18:00」。
  final String label;

  /// 是否邮箱类型。
  bool get isEmail => type == 'email';
}

/// 工单详情聚合结果。
class TicketDetail {
  const TicketDetail({
    required this.info,
    required this.replies,
    required this.attachments,
    required this.links,
    required this.contacts,
  });

  /// 工单主体。
  final TicketInfo info;

  /// 回复列表，按 id 正序。
  final List<TicketReply> replies;

  /// 主帖附件（reply_id = 0）。
  final List<TicketAttachment> attachments;

  /// 关联链接。
  final List<TicketLink> links;

  /// 联系方式。
  final List<TicketContact> contacts;
}

/// 轮询结果。
///
/// 后端只返回是否更新与最新回复时间，不含增量消息体，
/// 因此拿到 [hasNew] 后需重新拉取详情。
class TicketPollResult {
  const TicketPollResult({required this.hasNew, required this.lastReplyAt});

  /// 是否有新回复。
  final bool hasNew;

  /// 服务端最新回复时间，用作下一次轮询游标。
  final String lastReplyAt;
}
