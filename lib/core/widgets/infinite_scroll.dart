import 'package:flutter/material.dart';

/// 无限滚动加载通用组件。
///
/// 包裹任意可滚动列表，当剩余可滚动距离小于 [threshold]（默认 300 逻辑像素，
/// 即「快滑动到底部」）时触发 [onLoadMore]，实现上拉无极加载下一页。
/// 重复触发由调用方（控制器）负责去重（loading 中或没有更多时直接跳过）。
class InfiniteScrollListener extends StatelessWidget {
  const InfiniteScrollListener({
    required this.child,
    required this.onLoadMore,
    this.threshold = 300,
    super.key,
  });

  /// 包裹的可滚动列表。
  final Widget child;

  /// 快到底部时的加载回调。
  final VoidCallback onLoadMore;

  /// 触发加载的剩余滚动距离阈值。
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.extentAfter < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// 列表底部加载状态：还有更多时转圈提示，否则展示「已全部加载」。
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    required this.loading,
    required this.hasMore,
    this.showNoMore = true,
    super.key,
  });

  /// 是否正在加载（加载中显示转圈）。
  final bool loading;

  /// 是否还有更多数据。
  final bool hasMore;

  /// 没有更多时是否显示「已全部加载」提示。
  final bool showNoMore;

  @override
  Widget build(BuildContext context) {
    if (loading && hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              '加载中...',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }
    if (showNoMore && !hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '已全部加载',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
