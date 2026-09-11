import 'package:flutter/material.dart';

/// 资金管理页底部分页条。
///
/// 充值订单与余额流水两个 tab 共用，展示「第 X / Y 页 (共 N 条)」。
class FundPager extends StatelessWidget {
  const FundPager({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.loading,
    required this.onPrev,
    required this.onNext,
    super.key,
  });

  /// 当前页码。
  final int page;

  /// 总页数。
  final int totalPages;

  /// 总条数。
  final int total;

  /// 列表是否正在加载，加载中禁用翻页。
  final bool loading;

  /// 上一页回调。
  final VoidCallback onPrev;

  /// 下一页回调。
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton(
            onPressed: loading || page <= 1 ? null : onPrev,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('上一页'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '第 $page / $totalPages 页 (共 $total 条)',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          OutlinedButton(
            onPressed: loading || page >= totalPages ? null : onNext,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('下一页'),
          ),
        ],
      ),
    );
  }
}
