import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import '../ticket/ticket_summary_controller.dart';
import 'home_page/announcements.dart';
import 'home_page/hotline_card.dart';
import 'home_page/recent_activities.dart';
import 'home_page/recent_visits.dart';
import 'home_page/recommended_services.dart';
import 'home_page/resource_overview.dart';
import 'home_page/todo_section.dart';
import 'home_page/welcome_header.dart';

/// 首页 tab（控制台仪表盘）。
///
/// 板块与布局搬迁自 vue_flamecloud 控制台首页 DashboardPage.vue：
/// 欢迎区、资源概览、推荐云服务、最近访问、最近活动、待办事项、新闻公告、
/// 咨询热线。其中唯一的真实接口 `GET /v1/user/info` 由 session 启动时拉取，
/// 这里直接复用其 `name` / `last_login_time`（昵称与上次登录时间）。
/// 其余为后端暂无对应接口的本地静态数据，与 Vue 端保持一致。
/// 账户余额按产品约定只展示在「我的」页，不在此重复展示。
///
/// 各板块实现拆分在 [home_page] 子目录中，本文件只负责组装与刷新逻辑。
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
        onRefresh: () {
          ref.invalidate(pendingTicketCountProvider);
          return ref.read(sessionControllerProvider.notifier).refreshUser();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            HomeWelcomeHeader(user: user),
            const SizedBox(height: 16),
            const HomeResourceOverview(),
            const SizedBox(height: 16),
            const HomeRecommendedServices(),
            const SizedBox(height: 16),
            const HomeTodoSection(),
            const SizedBox(height: 16),
            const HomeRecentActivities(),
            const SizedBox(height: 16),
            const HomeRecentVisits(),
            const SizedBox(height: 16),
            const HomeAnnouncements(),
            const SizedBox(height: 16),
            const HomeHotlineCard(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
