import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ticket_detail_controller.dart';
import '../ticket_meta.dart';

/// 聊天工单转标准工单的底部弹窗内容：补齐分类与紧急性后调用控制器转换。
class TicketDetailConvertSheet extends ConsumerStatefulWidget {
  const TicketDetailConvertSheet({required this.onError, super.key});

  /// 转换失败时的错误提示回调（由页面统一弹出 SnackBar）。
  final void Function(Object error) onError;

  @override
  ConsumerState<TicketDetailConvertSheet> createState() =>
      _TicketDetailConvertSheetState();
}

class _TicketDetailConvertSheetState
    extends ConsumerState<TicketDetailConvertSheet> {
  String _category = 'ecs';
  String _urgency = 'fault';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            '转为标准工单',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            '补齐问题分类与紧急性后，该工单将按标准流程处理',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: '问题分类'),
            items: <DropdownMenuItem<String>>[
              for (final (String, String) item in TicketMeta.categories)
                DropdownMenuItem<String>(
                  value: item.$1,
                  child: Text(item.$2),
                ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _urgency,
            decoration: const InputDecoration(labelText: '紧急性'),
            items: <DropdownMenuItem<String>>[
              for (final (String, String) item in TicketMeta.urgencies)
                DropdownMenuItem<String>(
                  value: item.$1,
                  child: Text(item.$2),
                ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _urgency = value);
              }
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final String selectedCategory = _category;
                    final String selectedUrgency = _urgency;
                    try {
                      await ref
                          .read(ticketDetailControllerProvider.notifier)
                          .convert(
                            category: selectedCategory,
                            urgency: selectedUrgency,
                          );
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('工单转换成功')),
                        );
                    } on Exception catch (error) {
                      widget.onError(error);
                    }
                  },
                  child: const Text('确认转换'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
