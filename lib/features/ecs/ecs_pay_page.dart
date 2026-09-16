import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/ecs.dart';
import '../../data/repositories/ecs_repository.dart';

/// 支付方式。
enum EcsPayMethod {
  /// 余额支付。
  balance('balance', '余额支付'),

  /// 支付宝。
  alipay('alipay', '支付宝'),

  /// 微信支付。
  wechat('wechat', '微信支付');

  const EcsPayMethod(this.value, this.label);

  /// 提交给后端的 pay_method 值。
  final String value;

  /// 展示名。
  final String label;
}

/// ECS 订单支付页。
///
/// 搬迁自 vue_flamecloud 的 console/EcsPayPage：展示订单金额与状态，
/// 提供余额 / 支付宝 / 微信三种支付方式；余额支付需校验余额充足，
/// 第三方支付返回 `pay_url` 后由 [url_launcher] 拉起。
class EcsPayPage extends ConsumerStatefulWidget {
  const EcsPayPage({super.key, required this.orderId});

  /// 待支付订单 id（由购买页跳转时传入）。
  final int orderId;

  @override
  ConsumerState<EcsPayPage> createState() => _EcsPayPageState();
}

class _EcsPayPageState extends ConsumerState<EcsPayPage> {
  EcsOrder? _order;
  String _balance = '0.00';
  EcsPayMethod _method = EcsPayMethod.balance;
  bool _loading = true;
  bool _paying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_load());
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final EcsRepository repo = ref.read(ecsRepositoryProvider);
      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
        repo.fetchOrderDetail(widget.orderId),
        repo.fetchBalance(),
      ]);
      if (!mounted) {
        return;
      }
      _order = results[0] as EcsOrder;
      _balance = results[1] as String;
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _errorMessage = _messageOf(error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _messageOf(Object error) {
    if (error is Exception) {
      final String text = error.toString();
      return text.startsWith('Exception: ') ? text.substring(11) : text;
    }
    return '加载失败，请稍后重试';
  }

  Future<void> _pay() async {
    if (_order == null || _paying) {
      return;
    }

    if (_method == EcsPayMethod.balance) {
      final double balance = double.tryParse(_balance) ?? 0;
      final double amount = double.tryParse(_order!.amount) ?? 0;
      if (balance < amount) {
        _toast('余额不足，请先充值');
        return;
      }
    }

    setState(() {
      _paying = true;
      _errorMessage = null;
    });
    try {
      final EcsPayResult result = await ref
          .read(ecsRepositoryProvider)
          .payOrder(orderId: widget.orderId, payMethod: _method.value);

      if (!mounted) {
        return;
      }

      if (result.payUrl != null && result.payUrl!.isNotEmpty) {
        final Uri uri = Uri.parse(result.payUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _toast('请使用浏览器打开：${result.payUrl}');
        }
      } else {
        _toast('支付成功');
        Navigator.of(context)
            .popUntil((Route<dynamic> route) => route.isFirst);
        return;
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _toast(_messageOf(error));
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('订单支付'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _ErrorView(message: _errorMessage!, onRetry: _load)
              : _order == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        _AmountCard(order: _order!, balance: _balance),
                        const SizedBox(height: 16),
                        _buildMethodList(theme),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _order!.status == 1 || _paying ? null : _pay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.flame500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _order!.status == 1
                                  ? '已支付'
                                  : _paying
                                      ? '支付中…'
                                      : '立即支付',
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildMethodList(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: EcsPayMethod.values.map((EcsPayMethod m) {
          return RadioListTile<EcsPayMethod>(
            title: Text(m.label),
            subtitle: m == EcsPayMethod.balance
                ? Text('当前余额：¥$_balance',
                    style: const TextStyle(fontSize: 12))
                : null,
            value: m,
            groupValue: _method,
            activeColor: AppColors.flame500,
            onChanged: _order!.status == 1
                ? null
                : (EcsPayMethod? value) {
                    if (value != null) {
                      setState(() => _method = value);
                    }
                  },
          );
        }).toList(),
      ),
    );
  }
}

/// 订单金额卡片。
class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.order, required this.balance});

  final EcsOrder order;
  final String balance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('订单号', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(order.orderNo, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text('应付金额', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            '¥${order.amount}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Text('状态', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(width: 8),
              _StatusTag(status: order.status),
            ],
          ),
          if (order.remark.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            const Text('备注', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(order.remark, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

/// 订单状态标签。
class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      0 => Colors.orange,
      1 => Colors.green,
      _ => Colors.grey,
    };
    final String text = switch (status) {
      0 => '待支付',
      1 => '已支付',
      2 => '已取消',
      _ => '未知',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

/// 加载失败视图。
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
