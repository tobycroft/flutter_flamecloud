import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/infinite_scroll.dart';
import '../../../data/models/access_key.dart';
import '../ak_log_controller.dart';

/// AK 调用日志列表主体。
///
/// 供单 AK 日志弹窗与全部日志页复用：四态渲染 + 上一页/下一页分页，
/// 分页沿用 Vue 端约定（返回条数不足一页则禁用下一页）。
class AkLogListView extends ConsumerWidget {
  const AkLogListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AkLogState state = ref.watch(akLogControllerProvider);

    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(akLogControllerProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return const Center(
        child: Text(
          '暂无日志',
          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(akLogControllerProvider.notifier).refresh(),
      child: InfiniteScrollListener(
        onLoadMore: () => ref.read(akLogControllerProvider.notifier).loadMore(),
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
            return _AkLogTile(
              item: state.items[index],
              showAkId: state.akId == null,
            );
          },
        ),
      ),
    );
  }
}

/// 加载失败视图，提供重试入口。
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => unawaited(onRetry()),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 单条 AK 调用日志。
class _AkLogTile extends StatelessWidget {
  const _AkLogTile({required this.item, required this.showAkId});

  /// 日志数据。
  final AccessKeyLogItem item;

  /// 全部日志视图下额外展示所属 AK id。
  final bool showAkId;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color actionColor = _actionColor(item.action);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  item.action,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: actionColor,
                  ),
                ),
              ),
              if (showAkId) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  'AK #${item.akId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                item.displayTime,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          if (item.detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                item.detail,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF374151),
                ),
              ),
            ),
          if (item.ip.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'IP ${item.ip}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 操作类型对应主题色：create 绿、delete 红、permission 紫、update 蓝。
  static Color _actionColor(String action) {
    switch (action) {
      case 'create':
        return const Color(0xFF22C55E);
      case 'delete':
        return const Color(0xFFDC2626);
      case 'permission':
        return const Color(0xFFA855F7);
      case 'update':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
