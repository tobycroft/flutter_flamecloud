import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/access_key.dart';
import '../ak_log_controller.dart';
import 'ak_log_list.dart';

/// 弹出单个 AK 的调用日志底部弹窗。
///
/// 对应 vue_flamecloud 的 LogModal：打开时将共享的
/// [akLogControllerProvider] 切换为按该 AK 筛选，复用 [AkLogListView] 渲染；
/// 关闭后再次打开全量日志页会通过 [AkLogController.open] 自动重置。
Future<void> showAkLogSheet(BuildContext context, AccessKeyItem ak) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => AkLogSheet(ak: ak),
  );
}

/// 单 AK 调用日志弹窗。
class AkLogSheet extends ConsumerStatefulWidget {
  /// 创建弹窗，[ak] 为目标 AK。
  const AkLogSheet({super.key, required this.ak});

  /// 目标 AK。
  final AccessKeyItem ak;

  @override
  ConsumerState<AkLogSheet> createState() => _AkLogSheetState();
}

class _AkLogSheetState extends ConsumerState<AkLogSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref
              .read(akLogControllerProvider.notifier)
              .open(akId: widget.ak.id, akName: widget.ak.name),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * 0.75;
    final String title = widget.ak.name.isEmpty
        ? 'AK #${widget.ak.id}'
        : widget.ak.name;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '调用日志 · $title',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: AkLogListView()),
        ],
      ),
    );
  }
}
