import 'package:flutter/material.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket.dart';
import 'attachment_chip.dart';

/// 单条回复：客服左侧橙色、自己蓝色，回复可带附件。
class TicketDetailReplyCard extends StatelessWidget {
  const TicketDetailReplyCard({required this.reply, super.key});

  final TicketReply reply;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent =
        reply.fromAdmin ? const Color(0xFFEA580C) : const Color(0xFF2563EB);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: BorderSide.none,
          right: BorderSide.none,
          bottom: BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person_outline, size: 16, color: accent),
                ),
                const SizedBox(width: 8),
                Text(
                  reply.fromAdmin ? '客服' : '我',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                if (reply.fromAdmin) ...<Widget>[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '官方',
                      style: TextStyle(fontSize: 10, color: accent),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  reply.displayTime,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            if (reply.content.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                reply.content,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
            if (reply.attachments.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final TicketAttachment file in reply.attachments)
                    TicketDetailAttachmentChip(attachment: file),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
