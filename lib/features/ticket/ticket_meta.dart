import 'package:flutter/material.dart';

/// 工单展示元数据：状态、类型、紧急性、分类的文案与配色。
///
/// 搬迁自 vue_flamecloud 三个工单页面里重复的 statusMap / ticketTypeMap /
/// categoryMap / urgencyMap，集中一处供列表与详情复用。
class TicketMeta {
  const TicketMeta._();

  /// 共 10 个分类，在线客服已独立为聊天模块，工单不再使用 chat 分类。
  static const List<(String, String)> categories = <(String, String)>[
    ('ecs', 'ECS'),
    ('oss', '文件存储'),
    ('rds', '云数据库 MySQL'),
    ('waf', 'WAF'),
    ('vpc', 'VPC'),
    ('ddos', 'DDoS 高防防护'),
    ('metal', '裸金属'),
    ('elastic_ip', '弹性 IP'),
    ('auto_scale', '负载均衡'),
    ('other', '其他'),
  ];

  /// 三档紧急性，值为后端枚举。
  static const List<(String, String)> urgencies = <(String, String)>[
    ('fault', '产品故障'),
    ('usage', '产品使用问题'),
    ('consult', '产品咨询'),
  ];

  /// 状态文案：0 待回复、1 客户发送、2 客服答复、3 结案关闭。
  static String statusText(int status) => switch (status) {
        0 => '待回复',
        1 => '客户发送',
        2 => '客服答复',
        3 => '结案关闭',
        _ => '未知',
      };

  /// 状态配色，对齐 Vue 端 badge（黄/蓝/橙/灰）。
  static Color statusColor(int status) => switch (status) {
        0 => const Color(0xFFCA8A04),
        1 => const Color(0xFF2563EB),
        2 => const Color(0xFFEA580C),
        3 => const Color(0xFF9CA3AF),
        _ => const Color(0xFF9CA3AF),
      };

  /// 类型文案。
  static String typeText(String type) => type == 'chat' ? '在线客服' : '标准工单';

  /// 类型配色：chat 绿、standard 蓝。
  static Color typeColor(String type) =>
      type == 'chat' ? const Color(0xFF16A34A) : const Color(0xFF2563EB);

  /// 紧急性文案。
  static String urgencyText(String urgency) {
    for (final (String, String) item in urgencies) {
      if (item.$1 == urgency) {
        return item.$2;
      }
    }
    return '产品咨询';
  }

  /// 紧急性配色：故障红、使用问题橙、咨询灰。
  static Color urgencyColor(String urgency) => switch (urgency) {
        'fault' => const Color(0xFFDC2626),
        'usage' => const Color(0xFFEA580C),
        _ => const Color(0xFF6B7280),
      };

  /// 分类文案，未命中时原样返回 key。
  static String categoryText(String category) {
    for (final (String, String) item in categories) {
      if (item.$1 == category) {
        return item.$2;
      }
    }
    return category.isEmpty ? '其他' : category;
  }
}
