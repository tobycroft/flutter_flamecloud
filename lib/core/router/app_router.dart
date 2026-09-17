import 'package:flutter/material.dart';

import '../../data/models/access_key.dart';
import '../../data/models/action_log.dart' hide ActionLogPage;
import '../../data/models/balance_log.dart';
import '../../data/models/bill.dart';
import '../../data/models/ecs_instance.dart';
import '../../data/models/recharge_order.dart';
import '../../features/ak/ak_log_detail_page.dart';
import '../../features/ak/ak_log_page.dart';
import '../../features/ak/ak_manage_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/console/console_shell_page.dart';
import '../../features/ecs/ecs_buy_page.dart';
import '../../features/ecs/ecs_instance_detail_page.dart';
import '../../features/ecs/ecs_page.dart';
import '../../features/ecs/ecs_pay_page.dart';
import '../../features/fund/balance_log_detail_page.dart';
import '../../features/fund/bill_detail_page.dart';
import '../../features/fund/fund_manage_page.dart';
import '../../features/fund/recharge_page.dart';
import '../../features/fund/recharge_order_detail_page.dart';
import '../../features/fund/recharge_web_pay_page.dart';
import '../../features/log/action_log_detail_page.dart';
import '../../features/log/action_log_page.dart';
import '../../features/news/news_detail_page.dart';
import '../../features/news/news_list_page.dart';
import '../../features/profile/theme_mode_page.dart';
import '../../features/support/support_chat_page.dart';
import '../../features/ticket/ticket_detail_page.dart';
import '../../features/ticket/ticket_list_page.dart';
import '../../features/ticket/ticket_submit_page.dart';

/// 路由名称。
class AppRoutes {
  const AppRoutes._();

  /// 登录页。
  static const String login = '/login';

  /// 控制台，即底部导航外壳页。
  static const String console = '/console';

  /// 在线客服聊天页。
  static const String supportChat = '/support/chat';

  /// AK 管理页。
  static const String akManage = '/ak/manage';

  /// AK 调用日志页（全部 AK）。
  static const String akLogs = '/ak/logs';

  /// 操作日志页。
  static const String actionLog = '/logs/action';

  /// 资金管理页（余额概览 + 充值订单 + 余额流水）。
  static const String fundManage = '/fund/manage';

  /// 充值页（在线/线下两个 Tab）。
  static const String recharge = '/recharge';

  /// 支付宝支付页，arguments 传入 pay_url 字符串。
  static const String rechargeWebPay = '/recharge/webpay';

  /// 主题模式设置页。
  static const String themeMode = '/theme';

  /// 工单列表页。
  static const String ticketList = '/ticket/list';

  /// 工单详情页，arguments 传入工单 id。
  static const String ticketDetail = '/ticket/detail';

  /// 提交工单页。
  static const String ticketSubmit = '/ticket/submit';

  /// 新闻公告列表页。
  static const String newsList = '/news/list';

  /// 新闻公告详情页，pathParameters 传入公告 id。
  static const String newsDetail = '/news/detail';

  /// ECS 创建（购买）页。
  static const String ecsBuy = '/ecs/buy';

  /// ECS 订单支付页，arguments 传入订单 id。
  static const String ecsPay = '/ecs/pay';

  /// ECS 控制台页（实例列表 / 安全组 / 快照）。
  static const String ecs = '/ecs';

  /// ECS 实例详情页，arguments 传入 [EcsInstance]。
  static const String ecsDetail = '/ecs/detail';

  /// 充值订单详情页，arguments 传入 [RechargeOrderItem]。
  static const String rechargeOrderDetail = '/recharge/order/detail';

  /// 余额流水详情页，arguments 传入 [BalanceLogItem]。
  static const String balanceLogDetail = '/balance/log/detail';

  /// 账单详情页，arguments 传入 [BillItem]。
  static const String billDetail = '/bill/detail';

  /// 操作日志详情页，arguments 传入 [ActionLogDetailArgs]。
  static const String actionLogDetail = '/action/log/detail';

  /// AK 调用日志详情页，arguments 传入 [AccessKeyLogItem]。
  static const String akLogDetail = '/ak/log/detail';
}

/// 命名路由表。
///
/// 当前主入口由 AuthGate 控制，这里为后续控制台内页跳转预留。
class AppRouter {
  const AppRouter._();

  /// 生成路由。
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginPage(),
        );
      case AppRoutes.console:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ConsoleShellPage(),
        );
      case AppRoutes.supportChat:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SupportChatPage(),
        );
      case AppRoutes.akManage:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AkManagePage(),
        );
      case AppRoutes.akLogs:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AkLogPage(),
        );
      case AppRoutes.actionLog:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ActionLogPage(),
        );
      case AppRoutes.fundManage:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const FundManagePage(),
        );
      case AppRoutes.recharge:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RechargePage(),
        );
      case AppRoutes.rechargeWebPay:
        final String payUrl = settings.arguments is String
            ? settings.arguments as String
            : '';
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RechargeWebPayPage(payUrl: payUrl),
        );
      case AppRoutes.themeMode:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ThemeModePage(),
        );
      case AppRoutes.ticketList:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TicketListPage(),
        );
      case AppRoutes.ticketSubmit:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TicketSubmitPage(),
        );
      case AppRoutes.ticketDetail:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => TicketDetailPage(
            ticketId: settings.arguments is int ? settings.arguments as int : 0,
          ),
        );
      case AppRoutes.newsList:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const NewsListPage(),
        );
      case AppRoutes.newsDetail:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => NewsDetailPage(
            id: settings.arguments is int ? settings.arguments as int : 0,
          ),
        );
      case AppRoutes.ecsBuy:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const EcsBuyPage(),
        );
      case AppRoutes.ecsPay:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => EcsPayPage(
            orderId: settings.arguments is int ? settings.arguments as int : 0,
          ),
        );
      case AppRoutes.ecs:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const EcsPage(),
        );
      case AppRoutes.ecsDetail:
        final EcsInstance ecsItem = settings.arguments is EcsInstance
            ? settings.arguments as EcsInstance
            : const EcsInstance(
              id: 0,
              instanceId: '',
              instanceName: '',
              region: '',
              status: 'stopped',
              createdAt: '',
            );
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => EcsInstanceDetailPage(item: ecsItem),
        );
      case AppRoutes.rechargeOrderDetail:
        final RechargeOrderItem rechargeItem =
            settings.arguments is RechargeOrderItem
                ? settings.arguments as RechargeOrderItem
                : const RechargeOrderItem(
                    id: 0,
                    orderNo: '',
                    amount: '0',
                    payMethod: '',
                    type: 1,
                    status: 0,
                    createdAt: '',
                    remitTime: '',
                    remark: '',
                  );
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RechargeOrderDetailPage(item: rechargeItem),
        );
      case AppRoutes.balanceLogDetail:
        final BalanceLogItem balanceItem = settings.arguments is BalanceLogItem
            ? settings.arguments as BalanceLogItem
            : const BalanceLogItem(
                id: 0,
                type: 0,
                orderNo: '',
                amount: '0',
                balanceAfter: '0',
                description: '',
                createdAt: '',
              );
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BalanceLogDetailPage(item: balanceItem),
        );
      case AppRoutes.billDetail:
        final BillItem billItem = settings.arguments is BillItem
            ? settings.arguments as BillItem
            : const BillItem(
                id: 0,
                billNo: '',
                billingPeriod: '',
                product: '',
                instanceId: '',
                instanceName: '',
                moduleType: '',
                payMethod: '',
                totalPrice: '0',
                discountAmount: '0',
                settlementPrice: '0',
                couponAmount: '0',
                balancePay: '0',
                status: 0,
                startTime: '',
                endTime: '',
                chargeTime: '',
              );
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BillDetailPage(item: billItem),
        );
      case AppRoutes.actionLogDetail:
        final dynamic actionArgs = settings.arguments;
        final ActionLogItem actionItem =
            actionArgs is ActionLogDetailArgs ? actionArgs.item : const ActionLogItem(
                id: 0,
                uid: 0,
                logTypeId: 0,
                action: '',
                detail: '',
                ip: '',
                deviceType: null,
                createdAt: '',
              );
        final String? actionTypeName =
            actionArgs is ActionLogDetailArgs ? actionArgs.typeName : null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ActionLogDetailPage(
            item: actionItem,
            typeName: actionTypeName,
          ),
        );
      case AppRoutes.akLogDetail:
        final AccessKeyLogItem akItem = settings.arguments is AccessKeyLogItem
            ? settings.arguments as AccessKeyLogItem
            : const AccessKeyLogItem(
                id: 0,
                akId: 0,
                action: '',
                detail: '',
                ip: '',
                createdAt: '',
              );
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AkLogDetailPage(item: akItem),
        );
      default:
        return null;
    }
  }
}
