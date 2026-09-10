import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';
import 'home_models.dart';

/// 资源概览（与 Vue 端静态值保持一致，后端暂无统计接口）。
const List<HomeResourceStat> homeResourceStats = <HomeResourceStat>[
  HomeResourceStat(title: '云服务器', value: '24', unit: '台', icon: Icons.dns_outlined),
  HomeResourceStat(title: 'VPC', value: '3', unit: '个', icon: Icons.hub_outlined),
  HomeResourceStat(title: '弹性公网IP', value: '12', unit: '个', icon: Icons.wifi),
  HomeResourceStat(title: '对象存储', value: '12.8', unit: 'TB', icon: Icons.storage_outlined),
];

/// 推荐云服务。
const List<HomeServiceEntry> homeRecommendedServices = <HomeServiceEntry>[
  HomeServiceEntry(name: '云服务器ECS', icon: Icons.dns_outlined),
  HomeServiceEntry(name: '私有网络VPC', icon: Icons.hub_outlined),
  HomeServiceEntry(name: '弹性公网IP', icon: Icons.wifi),
  HomeServiceEntry(name: '负载均衡', icon: Icons.developer_board_outlined),
  HomeServiceEntry(name: 'NAT网关', icon: Icons.shield_outlined),
  HomeServiceEntry(name: '对象存储OSS', icon: Icons.cloud_outlined),
];

/// 最近访问。
const List<HomeRecentVisit> homeRecentVisits = <HomeRecentVisit>[
  HomeRecentVisit(name: '云服务器ECS', icon: Icons.dns_outlined),
  HomeRecentVisit(name: 'VPC', icon: Icons.hub_outlined),
  HomeRecentVisit(name: '弹性公网IP', icon: Icons.wifi),
  HomeRecentVisit(name: '子网', icon: Icons.dns_outlined),
  HomeRecentVisit(name: 'NAT网关', icon: Icons.shield_outlined),
  HomeRecentVisit(name: '负载均衡', icon: Icons.developer_board_outlined),
  HomeRecentVisit(name: '对象存储', icon: Icons.storage_outlined),
  HomeRecentVisit(name: '工单', icon: Icons.confirmation_number_outlined),
];

/// 最近活动。
const List<HomeActivity> homeRecentActivities = <HomeActivity>[
  HomeActivity(type: 'success', title: 'ECS实例启动成功', resource: 'ecs-flame-001', time: '2分钟前'),
  HomeActivity(type: 'info', title: '弹性IP绑定成功', resource: 'eip-003', time: '15分钟前'),
  HomeActivity(type: 'warning', title: 'CPU使用率过高预警', resource: 'ecs-flame-003', time: '30分钟前'),
  HomeActivity(type: 'info', title: 'VPC创建完成', resource: 'vpc-004', time: '2小时前'),
  HomeActivity(type: 'success', title: '工单已回复', resource: '工单 #202507001', time: '3小时前'),
];

/// 待办事项（与 Vue 端一致；工单可跳转真实列表，订单暂无页面）。
const List<HomeTodoItem> homeTodoItems = <HomeTodoItem>[
  HomeTodoItem(
    title: '待支付订单',
    count: 0,
    icon: Icons.wallet_outlined,
  ),
  HomeTodoItem(
    title: '待回复工单',
    icon: Icons.confirmation_number_outlined,
    route: AppRoutes.ticketList,
    liveTicketCount: true,
  ),
];
