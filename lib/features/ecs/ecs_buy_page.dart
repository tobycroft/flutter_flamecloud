import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ecs.dart';
import '../../features/ecs/ecs_buy_controller.dart';

/// ECS 创建（购买）页。
///
/// 搬迁自 vue_flamecloud 的 console/EcsBuyPage：四段式配置
/// （基础配置 / 网络配置 / 高级配置 / 购买配置），右侧摘要在移动端改为
/// 底部价格栏；任意配置项变化都会触发后端重新询价。
class EcsBuyPage extends ConsumerStatefulWidget {
  const EcsBuyPage({super.key});

  @override
  ConsumerState<EcsBuyPage> createState() => _EcsBuyPageState();
}

class _EcsBuyPageState extends ConsumerState<EcsBuyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(ecsBuyControllerProvider.notifier).init());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final EcsBuyState state = ref.watch(ecsBuyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('创建ECS'),
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: <Widget>[
              if (state.configLoading && state.regions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.errorMessage != null && state.regions.isEmpty)
                _ErrorRetry(
                  message: state.errorMessage!,
                  onRetry: () =>
                      ref.read(ecsBuyControllerProvider.notifier).init(),
                )
              else ...<Widget>[
                _SectionCard(
                  icon: Icons.computer_outlined,
                  title: '基础配置',
                  child: _BasicConfig(state: state),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.hub_outlined,
                  title: '网络配置',
                  child: _NetworkConfig(state: state),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.tune_outlined,
                  title: '高级配置',
                  child: _AdvancedConfig(state: state),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.shopping_cart_outlined,
                  title: '购买配置',
                  child: _PurchaseConfig(state: state),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  icon: Icons.summarize_outlined,
                  title: '配置概览',
                  child: _Summary(state: state),
                ),
              ],
            ],
          ),
          _BottomBar(state: state, onConfirm: _confirm),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    try {
      final int orderId =
          await ref.read(ecsBuyControllerProvider.notifier).createOrder();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushNamed(AppRoutes.ecsPay, arguments: orderId);
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      final String message =
          error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

/// 通用区块卡片。
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: AppColors.flame500),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 配置行：左侧标签 + 右侧内容。
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 可点击的标签 chip（选中态高亮为品牌橙）。
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.flame500.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: selected ? AppColors.flame500 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? AppColors.flame500 : Colors.grey.shade700,
              ),
            ),
            if (badge != null) ...<Widget>[
              const SizedBox(width: 4),
              Text(
                badge!,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 基础配置区。
class _BasicConfig extends ConsumerWidget {
  const _BasicConfig({required this.state});

  final EcsBuyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EcsBuyController controller =
        ref.read(ecsBuyControllerProvider.notifier);

    return Column(
      children: <Widget>[
        // 地域
        _FieldRow(
          label: '地域',
          child: DropdownButtonFormField<int>(
            value: state.selectedRegionId,
            isExpanded: true,
            hint: const Text('请选择地域'),
            items: state.regions
                .map((EcsRegion r) => DropdownMenuItem<int>(
                      value: r.id,
                      child: Text(r.name),
                    ))
                .toList(),
            onChanged: (int? id) {
              if (id != null) {
                unawaited(controller.selectRegion(id));
              }
            },
          ),
        ),
        // 可用区
        _FieldRow(
          label: '可用区',
          child: state.zones.isEmpty
              ? Text('请先选择地域',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.zones
                      .map((EcsZone z) => _Chip(
                            label: z.name,
                            selected: state.selectedZoneId == z.id,
                            onTap: () =>
                                unawaited(controller.selectZone(z.id)),
                          ))
                      .toList(),
                ),
        ),
        // 规格
        _FieldRow(
          label: '规格',
          child: state.configLoading
              ? const Text('加载中…',
                  style: TextStyle(fontSize: 13, color: Colors.grey))
              : state.specs.isEmpty
                  ? Text('该可用区暂无可选规格',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.specs
                          .map((EcsSpec s) => _Chip(
                                label: s.title,
                                selected: state.selectedSpecId == s.id,
                                onTap: () => controller.selectSpec(s.id),
                              ))
                          .toList(),
                    ),
        ),
        // 镜像
        _FieldRow(
          label: '镜像',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: imageTypes
                    .map((String t) => _Chip(
                          label: t,
                          selected: state.imageType == t,
                          onTap: () => controller.selectImageType(t),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: state.imageOs.isEmpty ? null : state.imageOs,
                      isExpanded: true,
                      hint: const Text('操作系统'),
                      items: imageOsOptions
                          .map((String os) => DropdownMenuItem<String>(
                                value: os,
                                child: Text(os),
                              ))
                          .toList(),
                      onChanged: (String? v) {
                        if (v != null) {
                          controller.selectImageOs(v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value:
                          state.imageVersion.isEmpty ? null : state.imageVersion,
                      isExpanded: true,
                      hint: const Text('版本'),
                      items: controller
                          .imageVersionsFor(state.imageOs)
                          .map((String v) => DropdownMenuItem<String>(
                                value: v,
                                child: Text(v),
                              ))
                          .toList(),
                      onChanged: state.imageOs.isEmpty
                          ? null
                          : (String? v) {
                              if (v != null) {
                                controller.selectImageVersion(v);
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 系统盘
        _FieldRow(
          label: '系统盘',
          child: Text(
            '免费赠送 ${state.systemDiskSize}GB ${state.systemDiskType}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        // 数据盘
        _FieldRow(
          label: '数据盘',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: controller.canAddDataDisk
                    ? () => controller.addDataDisk()
                    : null,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('增加数据盘'),
              ),
              const SizedBox(height: 8),
              if (state.dataDisks.isNotEmpty)
                ...state.dataDisks.map((EcsDataDisk disk) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          IconButton(
                            onPressed: () =>
                                controller.adjustDataDiskSize(disk.id, -10),
                            icon: const Icon(Icons.remove, size: 18),
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          SizedBox(
                            width: 56,
                            child: Text('${disk.size}GB',
                                textAlign: TextAlign.center),
                          ),
                          IconButton(
                            onPressed: () =>
                                controller.adjustDataDiskSize(disk.id, 10),
                            icon: const Icon(Icons.add, size: 18),
                            constraints:
                                const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: disk.type,
                              isExpanded: true,
                              items: diskTypes
                                  .map((String t) => DropdownMenuItem<String>(
                                        value: t,
                                        child: Text(t),
                                      ))
                                  .toList(),
                              onChanged: (String? v) {
                                if (v != null) {
                                  controller.setDataDiskType(disk.id, v);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () => controller.removeDataDisk(disk.id),
                            icon: const Icon(Icons.close, size: 18),
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    )),
              Text(
                '最多可添加 ${5 - state.dataDisks.length} 块数据盘',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 网络配置区。
class _NetworkConfig extends ConsumerWidget {
  const _NetworkConfig({required this.state});

  final EcsBuyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EcsBuyController controller =
        ref.read(ecsBuyControllerProvider.notifier);

    return Column(
      children: <Widget>[
        _FieldRow(
          label: '私网',
          child: DropdownButtonFormField<String>(
            value: state.selectedVpc.isEmpty ? null : state.selectedVpc,
            isExpanded: true,
            hint: const Text('请选择私有网络'),
            items: privateNetworks
                .map((VpcOption v) => DropdownMenuItem<String>(
                      value: v.value,
                      child: Text(v.label),
                    ))
                .toList(),
            onChanged: (String? v) {
              if (v != null) {
                controller.selectVpc(v);
              }
            },
          ),
        ),
        _FieldRow(
          label: '线路',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lineTypes
                .map((String l) => _Chip(
                      label: l,
                      selected: state.line == l,
                      onTap: () => controller.setLine(l),
                    ))
                .toList(),
          ),
        ),
        _FieldRow(
          label: '带宽',
          child: Row(
            children: <Widget>[
              Expanded(
                child: Slider(
                  value: state.bandwidth.toDouble(),
                  min: 1,
                  max: 600,
                  divisions: 599,
                  label: '${state.bandwidth} Mbps',
                  onChanged: (double v) => controller.setBandwidth(v.round()),
                ),
              ),
              IconButton(
                onPressed: () => controller.setBandwidth(state.bandwidth - 1),
                icon: const Icon(Icons.remove, size: 18),
              ),
              SizedBox(
                width: 44,
                child: Text('${state.bandwidth}',
                    textAlign: TextAlign.center),
              ),
              IconButton(
                onPressed: () => controller.setBandwidth(state.bandwidth + 1),
                icon: const Icon(Icons.add, size: 18),
              ),
              const Text('Mbps', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        _FieldRow(
          label: '',
          // SwitchListTile 背景画在最近的 Material 上，需自持一层 Material，
          // 否则外层带背景色的容器会遮挡水波纹（测试断言也会报错）。
          child: Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '免费赠送公网 (${state.line}) IP 1 个',
                style: const TextStyle(fontSize: 14),
              ),
              value: state.hasPublicIp,
              onChanged: controller.setHasPublicIp,
            ),
          ),
        ),
      ],
    );
  }
}

/// 高级配置区。
class _AdvancedConfig extends ConsumerWidget {
  const _AdvancedConfig({required this.state});

  final EcsBuyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EcsBuyController controller =
        ref.read(ecsBuyControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: passwordModes
              .map((String m) => _Chip(
                    label: m,
                    selected: state.passwordMode == m,
                    onTap: () => controller.setPasswordMode(m),
                  ))
              .toList(),
        ),
        if (state.passwordMode == '设置密码') ...<Widget>[
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: '账户',
              hintText: 'root',
              isDense: true,
            ),
            controller: TextEditingController(text: 'root'),
            enabled: false,
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
              isDense: true,
            ),
            obscureText: true,
            onChanged: controller.setRootPassword,
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: '确认密码',
              hintText: '请再次输入密码',
              isDense: true,
            ),
            obscureText: true,
            onChanged: controller.setConfirmPassword,
          ),
        ],
      ],
    );
  }
}

/// 购买配置区。
class _PurchaseConfig extends ConsumerWidget {
  const _PurchaseConfig({required this.state});

  final EcsBuyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EcsBuyController controller =
        ref.read(ecsBuyControllerProvider.notifier);

    return Column(
      children: <Widget>[
        _FieldRow(
          label: '购买数量',
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () =>
                    controller.setPurchaseCount(state.purchaseCount - 1),
                icon: const Icon(Icons.remove, size: 18),
              ),
              SizedBox(
                width: 48,
                child: Text('${state.purchaseCount}',
                    textAlign: TextAlign.center),
              ),
              IconButton(
                onPressed: () =>
                    controller.setPurchaseCount(state.purchaseCount + 1),
                icon: const Icon(Icons.add, size: 18),
              ),
              const Text('台', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        _FieldRow(
          label: '购买周期',
          child: state.periods.isEmpty
              ? const Text('加载中…', style: TextStyle(fontSize: 13))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.periods
                      .map((EcsPeriod p) => _Chip(
                            label: p.label,
                            selected: state.selectedPeriod == p.month,
                            badge: p.discountText.isEmpty ? null : p.discountText,
                            onTap: () => controller.selectPeriod(p.month),
                          ))
                      .toList(),
                ),
        ),
        _FieldRow(
          label: '备注',
          child: TextField(
            decoration: const InputDecoration(
              hintText: '请输入实例备注信息（选填）',
              isDense: true,
            ),
            maxLines: 3,
            onChanged: controller.setRemark,
          ),
        ),
      ],
    );
  }
}

/// 配置概览。
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final EcsBuyState state;

  @override
  Widget build(BuildContext context) {
    String findName<T>(
      Iterable<T> items,
      bool Function(T) match,
      String Function(T) pick,
    ) {
      for (final T item in items) {
        if (match(item)) {
          return pick(item);
        }
      }
      return '-';
    }

    final String region = findName<EcsRegion>(
      state.regions,
      (EcsRegion r) => r.id == state.selectedRegionId,
      (EcsRegion r) => r.name,
    );
    final String zone = findName<EcsZone>(
      state.zones,
      (EcsZone z) => z.id == state.selectedZoneId,
      (EcsZone z) => z.name,
    );
    final String spec = findName<EcsSpec>(
      state.specs,
      (EcsSpec s) => s.id == state.selectedSpecId,
      (EcsSpec s) => s.title,
    );
    final String image = state.imageOs.isNotEmpty && state.imageVersion.isNotEmpty
        ? '${state.imageOs} ${state.imageVersion}'
        : '-';
    final String disks = state.dataDisks.isEmpty
        ? '-'
        : state.dataDisks
            .map((EcsDataDisk d) => '${d.type}-${d.size}GB')
            .join('，');

    final List<Widget> rows = <Widget>[
      _summaryRow('地域', region),
      _summaryRow('可用区', zone),
      _summaryRow('规格', spec),
      _summaryRow('镜像', image),
      _summaryRow('系统盘', '${state.systemDiskSize}GB ${state.systemDiskType}'),
      _summaryRow('数据盘', disks),
      _summaryRow('线路', state.line),
      _summaryRow('带宽', '${state.bandwidth}M'),
      if (state.passwordMode == '设置密码') _summaryRow('账户', 'root'),
    ];

    return Column(children: rows);
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部价格栏 + 确认按钮。
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.state, required this.onConfirm});

  final EcsBuyState state;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String total = state.price?.totalPrice ?? '0.00';
    final bool busy = state.submitting || state.priceLoading;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('计费价格', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    if (state.price?.hasDiscount ?? false)
                      Text(
                        '原价 ¥${state.price!.originalPrice}  ${state.price!.discountRate}折',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough),
                      ),
                    if (state.priceLoading)
                      const Text('计算中…',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red))
                    else
                      Text(
                        '¥$total',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: busy || state.submitting ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.flame500,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: Text(state.submitting ? '创建订单中…' : '确认订单'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 加载失败重试块。
class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 48),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: <Widget>[
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
