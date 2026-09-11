import 'package:flutter/material.dart';

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

  /// 点击跳转的路由；当前所有待办均有真实页面。
  final String? route;

  /// 为真时数量取自后端聚合计数（未关闭且未删除的工单数），不写死。
  final bool liveTicketCount;
}
