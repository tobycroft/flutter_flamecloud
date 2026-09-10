import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import 'home_data.dart';
import 'home_models.dart';
import 'home_utils.dart';
import 'section_title.dart';

/// 推荐云服务：2 列网格。
class HomeRecommendedServices extends StatelessWidget {
  const HomeRecommendedServices({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HomeSectionTitle('推荐云服务'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3.2,
          children: <Widget>[
            for (final HomeServiceEntry entry in homeRecommendedServices)
              _HomeServiceCard(entry: entry, isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _HomeServiceCard extends StatelessWidget {
  const _HomeServiceCard({required this.entry, required this.isDark});

  final HomeServiceEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => showHomeComingSoon(context, entry.name),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.flame500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(entry.icon, color: AppColors.flame500, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
