import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import 'home_data.dart';
import 'home_models.dart';
import 'home_utils.dart';
import 'section_title.dart';

/// 资源概览：2x2 网格统计卡片。
class HomeResourceOverview extends StatelessWidget {
  const HomeResourceOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HomeSectionTitle('资源概览'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: <Widget>[
            for (final HomeResourceStat stat in homeResourceStats)
              _HomeStatCard(stat: stat, isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({required this.stat, required this.isDark});

  final HomeResourceStat stat;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => showHomeComingSoon(context, stat.title),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.flame500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(stat.icon, color: AppColors.flame500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      stat.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: homeSecondaryColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Text(
                          stat.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          stat.unit,
                          style: TextStyle(
                            fontSize: 11,
                            color: homeSecondaryColor(isDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
