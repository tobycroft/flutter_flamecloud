import 'package:flutter/material.dart';

import '../../core/widgets/detail_info.dart';
import '../../data/models/access_key.dart';

/// AK 调用日志详情页。
///
/// 承接 AK 调用日志列表的钻取：完整展示单条日志的全部字段
/// （所属 AK ID / 操作类型 / 详情 / 来源 IP / 时间），
/// 其中 IP 等长文本支持长按复制。数据来自列表项，无需额外请求。
class AkLogDetailPage extends StatelessWidget {
  const AkLogDetailPage({super.key, required this.item});

  /// 待展示的日志。
  final AccessKeyLogItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('调用详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          DetailCard(
            rows: <Widget>[
              DetailRow(
                label: 'AK ID',
                value: '${item.akId}',
                selectable: true,
              ),
              DetailRow(label: '操作类型', value: item.action),
              DetailRow(label: '详情', value: item.detail),
              DetailRow(
                label: '来源 IP',
                value: item.ip,
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
