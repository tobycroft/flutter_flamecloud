import 'package:flutter/material.dart';

/// 资源概览统计项。
class HomeResourceStat {
  const HomeResourceStat({
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
class HomeServiceEntry {
  const HomeServiceEntry({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

/// 最近访问项。
class HomeRecentVisit {
  const HomeRecentVisit({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

/// 最近活动项。
class HomeActivity {
  const HomeActivity({
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
class HomeTodoItem {
  const HomeTodoItem({
    required this.title,
    this.count = 0,
    required this.icon,
    this.route,
    this.liveTicketCount = false,
  });

  final String title;

  /// 静态数量；[liveTicketCount] 为真时该值仅作为加载中的占位。
  final int count;
  final IconData icon;

  /// 点击跳转的路由，为 null 时提示「搬迁中」。
  final String? route;

  /// 为真时数量取自后端聚合计数（未关闭且未删除的工单数），不写死。
  final bool liveTicketCount;
}
