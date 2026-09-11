import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import 'home_models.dart';

/// 最近活动。
const List<HomeActivity> homeRecentActivities = <HomeActivity>[
  HomeActivity(type: 'success', title: 'ECS实例启动成功', resource: 'ecs-flame-001', time: '2分钟前'),
  HomeActivity(type: 'info', title: '弹性IP绑定成功', resource: 'eip-003', time: '15分钟前'),
  HomeActivity(type: 'warning', title: 'CPU使用率过高预警', resource: 'ecs-flame-003', time: '30分钟前'),
  HomeActivity(type: 'info', title: 'VPC创建完成', resource: 'vpc-004', time: '2小时前'),
  HomeActivity(type: 'success', title: '工单已回复', resource: '工单 #202507001', time: '3小时前'),
];

/// 待办事项（仅保留有真实页面的工单待办；其余未搬迁业务不再在首页占位）。
const List<HomeTodoItem> homeTodoItems = <HomeTodoItem>[
  HomeTodoItem(
    title: '待回复工单',
    icon: Icons.confirmation_number_outlined,
    route: AppRoutes.ticketList,
    liveTicketCount: true,
  ),
];
