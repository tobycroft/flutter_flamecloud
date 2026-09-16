import 'package:flutter/material.dart';

import '../../core/widgets/detail_info.dart';
import '../../data/models/action_log.dart';

/// 操作日志详情页的路由参数。
///
/// 同时携带日志条目与已解析的类型名，避免详情页再去查类型字典。
class ActionLogDetailArgs {
  const ActionLogDetailArgs({required this.item, this.typeName});

  /// 待展示的日志。
  final ActionLogItem item;

  /// 已解析的类型中文名（字典缺失时为 null）。
  final String? typeName;
}

/// 操作日志详情页。
///
/// 承接操作日志列表的钻取：完整展示单条日志的全部字段
/// （操作类型 / 设备 / 操作内容 / 详情 / 来源 IP / 用户 ID / 时间），
/// 其中 IP 等长文本支持长按复制。数据来自列表项，无需额外请求。
class ActionLogDetailPage extends StatelessWidget {
  const ActionLogDetailPage({
    super.key,
    required this.item,
    this.typeName,
  });

  /// 待展示的日志。
  final ActionLogItem item;

  /// 类型中文名。
  final String? typeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('操作详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DetailCard(
            rows: <Widget>[
              DetailRow(
                label: '操作类型',
                value: typeName ?? '类型 ${item.logTypeId}',
              ),
              if (item.deviceType != null && item.deviceType!.isNotEmpty)
                DetailRow(label: '设备', value: item.deviceType!),
              DetailRow(label: '操作', value: item.action),
              DetailRow(label: '详情', value: item.detail),
              DetailRow(
                label: '来源 IP',
                value: item.ip,
                selectable: true,
              ),
              DetailRow(
                label: '用户 ID',
                value: '${item.uid}',
                selectable: true,
              ),
              DetailRow(
                label: '时间',
                value: item.displayTime,
                selectable: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
