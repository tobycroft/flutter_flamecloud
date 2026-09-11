import 'package:flutter/material.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/balance_log.dart';
import '../fund_meta.dart';

/// 单条余额流水卡片，对齐 Vue 端表格行展示的字段。
class BalanceLogTile extends StatelessWidget {
  const BalanceLogTile({required this.item, super.key});

  final BalanceLogItem item;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = FundMeta.balanceTypeColor(item.type);
    final bool income = FundMeta.balanceTypeIsIncome(item.type);
    final Color metaColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);
    final Color subColor = isDark
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
              Icon(FundMeta.balanceTypeIcon(item.type), size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                FundMeta.balanceTypeText(item.type),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${income ? '+' : '-'}¥${item.amountText}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (item.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                item.description,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: <Widget>[
                Text(
                  '变动后余额 ¥${item.balanceAfterText}',
                  style: TextStyle(fontSize: 12, color: metaColor),
                ),
                const Spacer(),
                Text(
                  item.displayTime,
                  style: TextStyle(fontSize: 12, color: metaColor),
                ),
              ],
            ),
          ),
          if (item.orderNo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.orderNo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: subColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
