import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import 'theme_options.dart';

/// 单个主题卡片：图标 + 名称 + 说明 + 配色预览。
class ThemeModeCard extends StatelessWidget {
  const ThemeModeCard({
    required this.option,
    required this.selected,
    required this.isDark,
    required this.onTap,
    super.key,
  });

  final ThemeOption option;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color surface = context.surfaces.panel;
    final Color border = selected
        ? AppColors.flame500
        : (context.surfaces.line);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.flame500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      option.icon,
                      size: 18,
                      color: AppColors.flame500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          option.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.summary,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.flame500,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 20,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFFD1D5DB),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                option.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              _ThemePreview(option: option),
            ],
          ),
        ),
      ),
    );
  }
}

/// 配色预览：背景、卡片、主色三格，直观呈现该主题的实际用色。
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.option});

  final ThemeOption option;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _PreviewChip(
          isDark: false,
          color: option.background,
          gradient: option.gradient,
        ),
        const SizedBox(width: 8),
        _PreviewChip(isDark: true, color: option.surface),
        const SizedBox(width: 8),
        const _PreviewChip(isDark: false, color: AppColors.flame500),
      ],
    );
  }
}

/// 单格预览色块。
class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.isDark,
    required this.color,
    this.gradient,
  });

  final bool isDark;
  final Color color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: context.surfaces.line),
        ),
      ),
    );
  }
}
