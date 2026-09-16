import 'package:flutter/material.dart';

import '../../core/theme/app_surfaces.dart';
import '../../core/theme/app_theme.dart';

/// 详情页通用的键值行：标签（灰色小字）在上，内容在下。
///
/// 用于各「列表 → 详情」二级页统一展示单条记录的全部字段，
/// 长文本（如日志详情、备注、IP）自动换行；[selectable] 开启后
/// 可长按选择复制，方便复制订单号 / IP / ID。
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.selectable = true,
    super.key,
  });

  /// 字段名。
  final String label;

  /// 字段值。
  final String value;

  /// 等宽字体（用于订单号、IP、ID 等需要精确对齐/复制的内容）。
  final bool mono;

  /// 是否允许长按选择复制，默认开启。
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);
    final Color valueColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1F2937);

    final TextStyle valueStyle = TextStyle(
      fontSize: 14,
      color: valueColor,
      fontFamily: mono ? 'monospace' : null,
      height: 1.5,
    );

    final Widget valueChild = selectable
        ? SelectableText(value.isEmpty ? '—' : value, style: valueStyle)
        : Text(value.isEmpty ? '—' : value, style: valueStyle);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
          const SizedBox(height: 4),
          valueChild,
        ],
      ),
    );
  }
}

/// 详情卡片：Panel 背景，内部竖向排列若干 [DetailRow]，行间以细分隔线分隔。
class DetailCard extends StatelessWidget {
  const DetailCard({required this.rows, super.key});

  /// 字段行列表。
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}
