import 'package:flutter/material.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import 'home_data.dart';
import 'home_models.dart';
import 'home_utils.dart';
import 'section_title.dart';

/// 最近活动。
class HomeRecentActivities extends StatelessWidget {
  const HomeRecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HomeSectionTitle('最近活动'),
        Material(
          color: context.surfaces.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < homeRecentActivities.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(height: 1, color: context.surfaces.line),
                _HomeActivityTile(activity: homeRecentActivities[i], isDark: isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeActivityTile extends StatelessWidget {
  const _HomeActivityTile({required this.activity, required this.isDark});

  final HomeActivity activity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (Color iconColor, Color bgColor) = homeStatusColors(activity.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(homeStatusIcon(activity.type), color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.resource,
                  style: TextStyle(
                    fontSize: 12,
                    color: homeSecondaryColor(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.time,
            style: TextStyle(
              fontSize: 12,
              color: homeTertiaryColor(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
