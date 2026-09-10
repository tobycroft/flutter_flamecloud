import 'package:flutter/material.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import 'home_data.dart';
import 'home_models.dart';
import 'home_utils.dart';
import 'section_title.dart';

/// 最近访问：可换行 chips。
class HomeRecentVisits extends StatelessWidget {
  const HomeRecentVisits({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HomeSectionTitle('最近访问'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final HomeRecentVisit visit in homeRecentVisits)
              _HomeVisitChip(visit: visit, isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _HomeVisitChip extends StatelessWidget {
  const _HomeVisitChip({required this.visit, required this.isDark});

  final HomeRecentVisit visit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaces.inset,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: () => showHomeComingSoon(context, visit.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(visit.icon, size: 14, color: homeSecondaryColor(isDark)),
              const SizedBox(width: 6),
              Text(
                visit.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
