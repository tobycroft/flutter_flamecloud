import 'package:flutter/material.dart';

import '../../../core/theme/app_surfaces.dart';

/// 筛选 chip。
class TicketListFilterChip extends StatelessWidget {
  const TicketListFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
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
