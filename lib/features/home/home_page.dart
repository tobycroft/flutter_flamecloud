import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_info.dart';
import '../auth/session_controller.dart';
import '../ticket/ticket_summary_controller.dart';
import 'home_page/announcements.dart';
import 'home_page/recent_activities.dart';
import 'home_page/todo_section.dart';
import 'home_page/welcome_header.dart';

/// 首页 tab（控制台仪表盘）。
///
/// 板块与布局搬迁自 vue_flamecloud 控制台首页 DashboardPage.vue，仅保留已有
/// 真实接口/页面的内容：欢迎区、待回复工单、最近活动、新闻公告。
/// 其中唯一的真实接口 `GET /v1/user/info` 由 session 启动时拉取，
/// 这里直接复用其 `name` / `last_login_time`（昵称与上次登录时间）。
/// 账户余额按产品约定只展示在「我的」页，不在此重复展示。
///
/// 未搬迁完成的业务（云服务器、VPC、订单等）不再在首页占位，统一在
/// 「服务」tab 内点击未搬迁项时提示「正在搬迁中，敬请期待」。
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
            const HomeTodoSection(),
            const SizedBox(height: 16),
            const HomeRecentActivities(),
            const SizedBox(height: 16),
            const HomeAnnouncements(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
