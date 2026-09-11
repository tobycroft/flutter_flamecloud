import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/recharge_order.dart';
import '../fund_meta.dart';

/// 单条充值订单卡片，对齐 Vue 端表格行展示的字段。
class RechargeOrderTile extends StatelessWidget {
  const RechargeOrderTile({required this.item, super.key});

  final RechargeOrderItem item;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color metaColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final Color orderNoColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.orderNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: orderNoColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(
                text: FundMeta.orderStatusText(item.status),
                color: FundMeta.orderStatusColor(item.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '¥${item.amountText}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.flame500,
                ),
              ),
              const Spacer(),
              Text(
                item.displayTime,
                style: TextStyle(fontSize: 12, color: metaColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _MetaTag(text: FundMeta.payMethodText(item.payMethod)),
              const SizedBox(width: 6),
              _MetaTag(text: item.type == 2 ? '线下充值' : '在线充值'),
              if (item.remitTimeText.isNotEmpty) ...<Widget>[
                const SizedBox(width: 6),
                Flexible(child: _MetaTag(text: '汇款 ${item.remitTimeText}')),
              ],
            ],
          ),
          if (item.remark.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '备注：${item.remark}',
                style: TextStyle(fontSize: 12, color: metaColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// 订单状态徽标。
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 支付方式 / 来源等次要信息标签。
class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.surfaces.inset,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF4B5563),
        ),
      ),
    );
  }
}
