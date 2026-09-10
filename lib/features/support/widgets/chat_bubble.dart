import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../data/models/chat_message.dart';

/// 聊天气泡。
///
/// 搬迁自 vue_flamecloud/src/pages/console/UserCenter/ChatPage.vue 的消息项：
/// 自己（`is_admin=0`）居右、蓝底白字、右下角收窄；客服（`is_admin=1`）
/// 居左、灰底、左下角收窄；两侧均为头像 + 昵称 + 时间。
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    required this.selfName,
    super.key,
  });

  /// 消息数据。
  final ChatMessage message;

  /// 自己的展示名，对应 Vue 端的 `userName || '我'`。
  final String selfName;

  @override
  Widget build(BuildContext context) {
    final bool isSelf = !message.fromAdmin;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isSelf) const _Avatar(admin: true),
          if (!isSelf) const SizedBox(width: 8),
          Flexible(
            // SizedBox(width: double.infinity) 让 Column 占满整行宽度，
            // 否则 Column 会收缩到内容宽度，crossAxisAlignment 的 end/start
            // 对齐将失效，导致所有气泡都贴着左侧。
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment:
                    isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isSelf ? selfName : message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelf
                          ? const Color(0xFF2563EB)
                          : AppColors.orange500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelf
                          ? const Color(0xFF3B82F6)
                          : (isDark
                              ? context.surfaces.inset
                              : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isSelf ? 16 : 4),
                        bottomRight: Radius.circular(isSelf ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isSelf
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF111827)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatChatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSelf) const SizedBox(width: 8),
          if (isSelf) const _Avatar(admin: false),
        ],
      ),
    );
  }
}

/// 头像：客服为橙色耳机，自己为蓝色人像。
class _Avatar extends StatelessWidget {
  const _Avatar({required this.admin});

  /// 是否客服。
  final bool admin;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          admin ? const Color(0xFFFFEDD5) : const Color(0xFFDBEAFE),
      child: Icon(
        admin ? Icons.headphones : Icons.person_outline,
        size: 16,
        color: admin ? const Color(0xFFEA580C) : const Color(0xFF2563EB),
      ),
    );
  }
}

/// 格式化消息时间。
///
/// 当天显示 `HH:mm`，同年显示 `MM-DD HH:mm`，跨年显示完整日期；
/// 后端若返回无法解析的格式（例如秒级时间戳）则原样回退。
String formatChatTime(String raw) {
  final DateTime? time = DateTime.tryParse(raw);
  if (time == null) {
    return raw;
  }
  final DateTime now = DateTime.now();
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  final bool isToday =
      time.year == now.year && time.month == now.month && time.day == now.day;
  if (isToday) {
    return '$hour:$minute';
  }
  final String month = time.month.toString().padLeft(2, '0');
  final String day = time.day.toString().padLeft(2, '0');
  if (time.year == now.year) {
    return '$month-$day $hour:$minute';
  }
  return '${time.year}-$month-$day $hour:$minute';
}
