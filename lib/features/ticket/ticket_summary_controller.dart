import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ticket.dart';
import '../../data/repositories/ticket_repository.dart';

/// 首页待办「待回复工单」计数：取后端列表接口聚合的 `processing`。
///
/// 后端定义 `processing = status 0(待回复) + 1(客户发送) + 2(客服答复)`，
/// 且聚合查询带 `deleted_at IS NULL`，因此天然排除**已结案关闭(3)**与**已软删**的工单，
/// 与列表页顶部的「服务中」统计卡同源，不会出现写死值对不上的情况。
///
/// 只要工单状态发生变化（列表页关闭/重启、详情页关闭/重启/回复），
/// 对应控制器会 `ref.invalidate` 本 provider，首页回到前台即可看到新计数。
final pendingTicketCountProvider = FutureProvider<int>((Ref ref) async {
  final TicketListResult result =
      await ref.watch(ticketRepositoryProvider).fetchList(page: 1, pageSize: 1);
  return result.processing;
});
