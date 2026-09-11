import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../balance_summary_controller.dart';

/// 余额概览卡片：当前余额 + 累计充值 / 累计消费。
///
/// 对应 Vue 端 BalanceLogPage 顶部三张统计卡，移动端合并为一张卡片。
/// 加载失败时展示占位符，点击卡片可重试。
class FundBalanceCard extends ConsumerWidget {
  const FundBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BalanceSummaryState state = ref.watch(
      balanceSummaryControllerProvider,
    );
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color labelColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF6B7280);

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: state.errorMessage == null
            ? null
            : () => unawaited(
                ref.read(balanceSummaryControllerProvider.notifier).refresh(),
              ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '账户余额',
                    style: TextStyle(fontSize: 12, color: labelColor),
                  ),
                  const Spacer(),
                  if (state.loading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (state.errorMessage != null)
                    Text(
                      '点击重试',
                      style: TextStyle(fontSize: 11, color: labelColor),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '¥ ${state.summary?.balanceText ?? '--'}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.flame500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _AmountItem(
                      label: '累计充值',
                      value: state.summary?.totalRechargeText ?? '--',
                      color: const Color(0xFF16A34A),
                      labelColor: labelColor,
                    ),
                  ),
                  Expanded(
                    child: _AmountItem(
                      label: '累计消费',
                      value: state.summary?.totalConsumeText ?? '--',
                      color: const Color(0xFFDC2626),
                      labelColor: labelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单项金额展示：累计充值 / 累计消费。
class _AmountItem extends StatelessWidget {
  const _AmountItem({
    required this.label,
    required this.value,
    required this.color,
    required this.labelColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
        const SizedBox(height: 2),
        Text(
          '¥ $value',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
