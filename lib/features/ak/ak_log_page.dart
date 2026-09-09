import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ak_log_controller.dart';
import 'widgets/ak_log_list.dart';

/// AK 调用日志页，搬迁自 vue_flamecloud/AkLogsPage。
///
/// 展示全部 AK 的调用记录（对应 `GET /v1/user/access_key/log/all`），
/// 分页沿用「返回条数不足一页则禁用下一页」的隐式约定。
class AkLogPage extends ConsumerStatefulWidget {
  const AkLogPage({super.key});

  @override
  ConsumerState<AkLogPage> createState() => _AkLogPageState();
}

class _AkLogPageState extends ConsumerState<AkLogPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(akLogControllerProvider.notifier).open());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AK 调用日志'),
      ),
      body: const AkLogListView(),
    );
  }
}
