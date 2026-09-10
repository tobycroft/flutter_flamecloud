import 'package:flutter/material.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ticket.dart';
import '../ticket_meta.dart';
import 'attachment_chip.dart';

/// 主帖卡片：紧急性、分类、联系方式、正文与附件区。
class TicketDetailInfoCard extends StatelessWidget {
  const TicketDetailInfoCard({
    required this.info,
    required this.attachments,
    required this.links,
    required this.contacts,
    super.key,
  });

  final TicketInfo info;
  final List<TicketAttachment> attachments;
  final List<TicketLink> links;
  final List<TicketContact> contacts;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasExtras =
        attachments.isNotEmpty || links.isNotEmpty || contacts.isNotEmpty;

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  TicketMeta.urgencyText(info.urgency),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TicketMeta.urgencyColor(info.urgency),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: TicketMeta.statusColor(info.status)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    TicketMeta.statusText(info.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TicketMeta.statusColor(info.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              info.description,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  Icons.label_outline,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  TicketMeta.categoryText(info.category),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 4),
                Text(
                  info.displayTime,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            if (info.contactPhone.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                '联系电话 ${info.contactPhone}',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                ),
              ),
            ],
            if (hasExtras) ...<Widget>[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (attachments.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final TicketAttachment file in attachments)
                      TicketDetailAttachmentChip(attachment: file),
                  ],
                ),
              if (links.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                for (final TicketLink link in links)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${link.text} ${link.url}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
              if (contacts.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                for (final TicketContact contact in contacts)
                  Row(
                    children: <Widget>[
                      Icon(
                        contact.isEmail
                            ? Icons.mail_outline
                            : Icons.phone_outlined,
                        size: 14,
                        color: const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contact.label.isEmpty ? contact.value : contact.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
