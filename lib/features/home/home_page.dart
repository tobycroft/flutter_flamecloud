import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_surfaces.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/news.dart';
import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import '../news/news_controller.dart';

/// 首页 tab（控制台仪表盘）。
///
/// 板块与布局搬迁自 vue_flamecloud 控制台首页 DashboardPage.vue：
/// 欢迎区、资源概览、推荐云服务、最近访问、最近活动、待办事项、新闻公告、
/// 咨询热线。其中唯一的真实接口 `GET /v1/user/info` 由 session 启动时拉取，
/// 这里直接复用其 `name` / `last_login_time`（昵称与上次登录时间）。
/// 其余为后端暂无对应接口的本地静态数据，与 Vue 端保持一致。
/// 账户余额按产品约定只展示在「我的」页，不在此重复展示。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserInfo? user =
        ref.watch(sessionControllerProvider).asData?.value?.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(sessionControllerProvider.notifier).refreshUser(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _WelcomeHeader(user: user),
            const SizedBox(height: 16),
            const _ResourceOverview(),
            const SizedBox(height: 16),
            const _RecommendedServices(),
            const SizedBox(height: 16),
            const _TodoSection(),
            const SizedBox(height: 16),
            const _RecentActivities(),
            const SizedBox(height: 16),
            const _RecentVisits(),
            const SizedBox(height: 16),
            const _Announcements(),
            const SizedBox(height: 16),
            const _HotlineCard(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 资源概览统计项。
class _ResourceStat {
  const _ResourceStat({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
}

/// 推荐云服务项。
class _ServiceEntry {
  const _ServiceEntry({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

/// 最近访问项。
class _RecentVisit {
  const _RecentVisit({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

/// 最近活动项。
class _Activity {
  const _Activity({
    required this.type,
    required this.title,
    required this.resource,
    required this.time,
  });

  /// 状态类型：success / warning / info。
  final String type;

  final String title;
  final String resource;
  final String time;
}

/// 待办项。
class _TodoItem {
  const _TodoItem({
    required this.title,
    required this.count,
    required this.icon,
    this.route,
  });

  final String title;
  final int count;
  final IconData icon;

  /// 点击跳转的路由，为 null 时提示「搬迁中」。
  final String? route;
}

/// 资源概览（与 Vue 端静态值保持一致，后端暂无统计接口）。
const List<_ResourceStat> _resourceStats = <_ResourceStat>[
  _ResourceStat(title: '云服务器', value: '24', unit: '台', icon: Icons.dns_outlined),
  _ResourceStat(title: 'VPC', value: '3', unit: '个', icon: Icons.hub_outlined),
  _ResourceStat(title: '弹性公网IP', value: '12', unit: '个', icon: Icons.wifi),
  _ResourceStat(title: '对象存储', value: '12.8', unit: 'TB', icon: Icons.storage_outlined),
];

/// 推荐云服务。
const List<_ServiceEntry> _recommendedServices = <_ServiceEntry>[
  _ServiceEntry(name: '云服务器ECS', icon: Icons.dns_outlined),
  _ServiceEntry(name: '私有网络VPC', icon: Icons.hub_outlined),
  _ServiceEntry(name: '弹性公网IP', icon: Icons.wifi),
  _ServiceEntry(name: '负载均衡', icon: Icons.developer_board_outlined),
  _ServiceEntry(name: 'NAT网关', icon: Icons.shield_outlined),
  _ServiceEntry(name: '对象存储OSS', icon: Icons.cloud_outlined),
];

/// 最近访问。
const List<_RecentVisit> _recentVisits = <_RecentVisit>[
  _RecentVisit(name: '云服务器ECS', icon: Icons.dns_outlined),
  _RecentVisit(name: 'VPC', icon: Icons.hub_outlined),
  _RecentVisit(name: '弹性公网IP', icon: Icons.wifi),
  _RecentVisit(name: '子网', icon: Icons.dns_outlined),
  _RecentVisit(name: 'NAT网关', icon: Icons.shield_outlined),
  _RecentVisit(name: '负载均衡', icon: Icons.developer_board_outlined),
  _RecentVisit(name: '对象存储', icon: Icons.storage_outlined),
  _RecentVisit(name: '工单', icon: Icons.confirmation_number_outlined),
];

/// 最近活动。
const List<_Activity> _recentActivities = <_Activity>[
  _Activity(type: 'success', title: 'ECS实例启动成功', resource: 'ecs-flame-001', time: '2分钟前'),
  _Activity(type: 'info', title: '弹性IP绑定成功', resource: 'eip-003', time: '15分钟前'),
  _Activity(type: 'warning', title: 'CPU使用率过高预警', resource: 'ecs-flame-003', time: '30分钟前'),
  _Activity(type: 'info', title: 'VPC创建完成', resource: 'vpc-004', time: '2小时前'),
  _Activity(type: 'success', title: '工单已回复', resource: '工单 #202507001', time: '3小时前'),
];

/// 待办事项（与 Vue 端一致；工单可跳转真实列表，订单暂无页面）。
const List<_TodoItem> _todoItems = <_TodoItem>[
  _TodoItem(
    title: '待支付订单',
    count: 0,
    icon: Icons.wallet_outlined,
  ),
  _TodoItem(
    title: '待回复工单',
    count: 2,
    icon: Icons.confirmation_number_outlined,
    route: AppRoutes.ticketList,
  ),
];

/// 把后端返回的时间字符串格式化为「今天 HH:MM」或「YYYY-MM-DD HH:MM」。
///
/// 兼容 `2025-01-01 00:00:00` 与 ISO `2025-01-01T00:00:00` 两种形态，
/// 与 vue_flamecloud DashboardPage 的 formatDateTime 行为一致。
String _formatLastLogin(String? raw) {
  if (raw == null || raw.isEmpty) {
    return '';
  }
  try {
    final String normalized = raw.replaceAll('T', ' ').trim();
    final String trimmed =
        normalized.length >= 19 ? normalized.substring(0, 19) : normalized;
    final DateTime? date = DateTime.tryParse(trimmed);
    if (date == null) {
      return raw;
    }
    final DateTime now = DateTime.now();
    final bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final String hh = date.hour.toString().padLeft(2, '0');
    final String mm = date.minute.toString().padLeft(2, '0');
    if (isToday) {
      return '今天 $hh:$mm';
    }
    final String mo = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mo-$d $hh:$mm';
  } catch (_) {
    return raw;
  }
}

/// 活动状态对应的（图标色，浅底背景色）。
(Color, Color) _statusColors(String type) {
  switch (type) {
    case 'success':
      const Color green = Color(0xFF16A34A);
      return (green, green.withValues(alpha: 0.1));
    case 'warning':
      const Color amber = Color(0xFFD97706);
      return (amber, amber.withValues(alpha: 0.1));
    default:
      return (AppColors.flame500, AppColors.flame500.withValues(alpha: 0.1));
  }
}

/// 活动状态对应的图标。
IconData _statusIcon(String type) {
  switch (type) {
    case 'success':
      return Icons.check_circle;
    case 'warning':
      return Icons.warning_amber_rounded;
    default:
      return Icons.info;
  }
}

/// 统一的「功能搬迁中」提示。
void _comingSoon(BuildContext context, String name) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('$name 正在搬迁中，敬请期待')),
    );
}

/// 二级文字色（用于次要说明文字）。
Color _secondaryColor(bool isDark) =>
    isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

/// 三级文字色（用于时间、日期等弱信息）。
Color _tertiaryColor(bool isDark) =>
    isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

/// 欢迎头部：渐变卡片展示头像、问候语与上次登录时间（来自 user/info 真实数据）。
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({this.user});

  final UserInfo? user;

  @override
  Widget build(BuildContext context) {
    final String name = user?.displayName ?? '';
    final String lastLogin = _formatLastLogin(user?.lastLoginTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: AppColors.loginButtonGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                child: Text(
                  _initial(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '$name您好！',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '欢迎来到火焰云控制台',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lastLogin.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '上次登录: $lastLogin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initial(String name) =>
      name.isEmpty ? '火' : name.characters.first.toUpperCase();
}

/// 分区标题。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 资源概览：2x2 网格统计卡片。
class _ResourceOverview extends StatelessWidget {
  const _ResourceOverview();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('资源概览'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: <Widget>[
            for (final _ResourceStat stat in _resourceStats)
              _StatCard(stat: stat, isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.isDark});

  final _ResourceStat stat;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _comingSoon(context, stat.title),
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
                        color: _secondaryColor(isDark),
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
                            color: _secondaryColor(isDark),
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

/// 推荐云服务：2 列网格。
class _RecommendedServices extends StatelessWidget {
  const _RecommendedServices();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('推荐云服务'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3.2,
          children: <Widget>[
            for (final _ServiceEntry entry in _recommendedServices)
              _ServiceCard(entry: entry, isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.entry, required this.isDark});

  final _ServiceEntry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _comingSoon(context, entry.name),
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

/// 待办事项。
class _TodoSection extends StatelessWidget {
  const _TodoSection();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('待办事项'),
        Material(
          color: context.surfaces.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < _todoItems.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(height: 1, color: context.surfaces.line),
                _TodoTile(item: _todoItems[i], isDark: isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.item, required this.isDark});

  final _TodoItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bool hasRoute = item.route != null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () {
        if (hasRoute) {
          unawaited(Navigator.of(context).pushNamed(item.route!));
        } else {
          _comingSoon(context, item.title);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(item.icon, size: 20, color: _tertiaryColor(isDark)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.count > 0
                    ? AppColors.flame500.withValues(alpha: 0.12)
                    : context.surfaces.inset,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                '${item.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: item.count > 0
                      ? AppColors.flame500
                      : _tertiaryColor(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 最近活动。
class _RecentActivities extends StatelessWidget {
  const _RecentActivities();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('最近活动'),
        Material(
          color: context.surfaces.panel,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Column(
            children: <Widget>[
              for (int i = 0; i < _recentActivities.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(height: 1, color: context.surfaces.line),
                _ActivityTile(activity: _recentActivities[i], isDark: isDark),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.isDark});

  final _Activity activity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (Color iconColor, Color bgColor) = _statusColors(activity.type);

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
            child: Icon(_statusIcon(activity.type), color: iconColor, size: 18),
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
                    color: _secondaryColor(isDark),
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
              color: _tertiaryColor(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// 最近访问：可换行 chips。
class _RecentVisits extends StatelessWidget {
  const _RecentVisits();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('最近访问'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final _RecentVisit visit in _recentVisits)
              _VisitChip(visit: visit, isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _VisitChip extends StatelessWidget {
  const _VisitChip({required this.visit, required this.isDark});

  final _RecentVisit visit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaces.inset,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        onTap: () => _comingSoon(context, visit.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(visit.icon, size: 14, color: _secondaryColor(isDark)),
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

/// 新闻公告（首页展示，从 `newsControllerProvider` 拉取最新几条）。
class _Announcements extends ConsumerStatefulWidget {
  const _Announcements();

  @override
  ConsumerState<_Announcements> createState() => _AnnouncementsState();
}

class _AnnouncementsState extends ConsumerState<_Announcements> {
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
            const _SectionTitle('新闻公告'),
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
                      style: TextStyle(fontSize: 13, color: _tertiaryColor(isDark)),
                    ),
                  ),
                )
              else
                for (int i = 0; i < items.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: context.surfaces.line),
                  _AnnouncementTile(item: items[i], isDark: isDark),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item, required this.isDark});

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
                color: _tertiaryColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 咨询热线卡片。
class _HotlineCard extends StatelessWidget {
  const _HotlineCard();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: context.surfaces.panel,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.headset_mic_outlined,
                color: Color(0xFF16A34A),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '咨询热线',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '7×24小时服务支持',
                    style: TextStyle(
                      fontSize: 12,
                      color: _secondaryColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '400-096-8858',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.flame500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
