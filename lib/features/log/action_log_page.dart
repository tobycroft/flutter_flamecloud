import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/infinite_scroll.dart';

import 'action_log_controller.dart';
import 'action_log_page/action_log_tile.dart';
import 'action_log_page/error_view.dart';
import 'action_log_page/type_filter_bar.dart';

/// 操作日志页，搬迁自 vue_flamecloud/ActionLogsPage。
///
/// 顶部为日志类型筛选条（综合 + 动态类型字典，对应 Vue 端
/// `?log_type_id=` 的筛选行为），下方为分页日志列表。
///
/// 各板块实现拆分在 [action_log_page] 子目录中，本文件只负责组装与
/// 刷新逻辑。
class ActionLogPage extends ConsumerStatefulWidget {
  const ActionLogPage({super.key});

  @override
  ConsumerState<ActionLogPage> createState() => _ActionLogPageState();
}

class _ActionLogPageState extends ConsumerState<ActionLogPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(actionLogControllerProvider.notifier).load());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ActionLogState state = ref.watch(actionLogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('操作日志'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ActionLogTypeFilterBar(state: state),
          const Divider(height: 1),
          Expanded(child: _buildList(state)),
        ],
      ),
    );
  }

  Widget _buildList(ActionLogState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return ActionLogErrorView(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(actionLogControllerProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(actionLogControllerProvider.notifier).refresh(),
        child: ListView(
          children: const <Widget>[
            SizedBox(height: 120),
            Center(
              child: Text(
                '暂无日志',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(actionLogControllerProvider.notifier).refresh(),
      child: InfiniteScrollListener(
        onLoadMore: () =>
            ref.read(actionLogControllerProvider.notifier).loadMore(),
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: state.items.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == state.items.length) {
              return LoadMoreFooter(
                loading: state.loading,
                hasMore: state.hasMore,
              );
            }
            return ActionLogTile(
              item: state.items[index],
              types: state.types,
            );
          },
        ),
      ),
    );
  }
}
