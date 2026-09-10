import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/news.dart';
import '../../news/news_controller.dart';
import 'home_utils.dart';
import 'section_title.dart';

/// 新闻公告（首页展示，从 `newsControllerProvider` 拉取最新几条）。
class HomeAnnouncements extends ConsumerStatefulWidget {
  const HomeAnnouncements({super.key});

  @override
  ConsumerState<HomeAnnouncements> createState() => _HomeAnnouncementsState();
}

class _HomeAnnouncementsState extends ConsumerState<HomeAnnouncements> {
  @override
  void initState() {
    super.initState();
    // 进入首页时拉取一次最新公告（无登录态也可访问公开接口）。
    Future<void>.microtask(
      () => ref.read(newsControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final NewsState state = ref.watch(newsControllerProvider);
    final List<NewsItem> items = state.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const HomeSectionTitle('新闻公告'),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.newsList),
              child: Text(
                '更多',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.flame500,
                ),
              ),
            ),
          ],
        ),
        Material(
          color: context.surfaces.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Column(
            children: <Widget>[
              if (state.loading && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!state.loading && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      '暂无公告',
                      style: TextStyle(fontSize: 13, color: homeTertiaryColor(isDark)),
                    ),
                  ),
                )
              else
                for (int i = 0; i < items.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: context.surfaces.line),
                  _HomeAnnouncementTile(item: items[i], isDark: isDark),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeAnnouncementTile extends StatelessWidget {
  const _HomeAnnouncementTile({required this.item, required this.isDark});

  final NewsItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.newsDetail,
        arguments: item.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                item.title ?? '',
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.dateLabel,
              style: TextStyle(
                fontSize: 12,
                color: homeTertiaryColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
