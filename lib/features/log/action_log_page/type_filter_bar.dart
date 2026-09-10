/// 操作日志页类型筛选条。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../data/models/action_log.dart';
import '../action_log_controller.dart';

/// 类型筛选条：「综合」+ 动态类型 chips，横向滚动。
class ActionLogTypeFilterBar extends ConsumerWidget {
  const ActionLogTypeFilterBar({super.key, required this.state});

  final ActionLogState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.typesLoading && state.types.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: <Widget>[
          _ActionLogTypeChip(
            label: '综合',
            selected: state.selectedTypeId == null,
            onTap: () => unawaited(
              ref.read(actionLogControllerProvider.notifier).selectType(null),
            ),
          ),
          for (final ActionLogType type in state.types)
            _ActionLogTypeChip(
              label: type.name,
              selected: state.selectedTypeId == type.id,
              onTap: () => unawaited(
                ref
                    .read(actionLogControllerProvider.notifier)
                    .selectType(type.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// 类型筛选 chip。
class _ActionLogTypeChip extends StatelessWidget {
  const _ActionLogTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? primary
                : (context.surfaces.inset),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? primary
                  : (isDark
                      ? const Color(0xFF1A1F4E)
                      : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF4B5563)),
            ),
          ),
        ),
      ),
    );
  }
}
