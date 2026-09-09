import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../data/models/access_key.dart';
import 'ak_list_controller.dart';
import 'widgets/ak_card.dart';
import 'widgets/ak_log_sheet.dart';
import 'widgets/ak_permission_sheet.dart';
import 'widgets/create_ak_sheet.dart';

/// AK 管理页，搬迁自 vue_flamecloud/UsersPage。
///
/// 展示当前用户的 AccessKey 列表，支持创建（Secret 仅显示一次）、
/// 启用/禁用、权限配置、查看单个 AK 日志与删除；
/// AppBar 右上角入口对应 Vue 端侧边栏的「AK日志」子菜单。
class AkManagePage extends ConsumerStatefulWidget {
  const AkManagePage({super.key});

  @override
  ConsumerState<AkManagePage> createState() => _AkManagePageState();
}

class _AkManagePageState extends ConsumerState<AkManagePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(akListControllerProvider.notifier).load());
      }
    });
  }

  /// 统一弹出错误提示。
  void _showError(Object error, String fallback) {
    String message = fallback;
    if (error is ApiException && error.message.isNotEmpty) {
      message = error.message;
    } else if (error is NetworkException) {
      message = error.message;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createAk() async {
    await showCreateAkSheet(context);
  }

  Future<void> _toggleStatus(AccessKeyItem ak) async {
    try {
      await ref
          .read(akListControllerProvider.notifier)
          .setStatus(ak, !ak.enabled);
    } on Exception catch (error) {
      _showError(error, ak.enabled ? '禁用失败' : '启用失败');
    }
  }

  Future<void> _deleteAk(AccessKeyItem ak) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final String displayName = ak.name.isEmpty ? ak.accessKey : ak.name;
        return AlertDialog(
          title: const Text('删除 AK'),
          content: Text('确定删除 AK「$displayName」吗？删除后不可恢复。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                '删除',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(akListControllerProvider.notifier).deleteAk(ak);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('AK 已删除')));
    } on Exception catch (error) {
      _showError(error, '删除失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AkListState state = ref.watch(akListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AK 管理'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'AK 调用日志',
            onPressed: () =>
                unawaited(Navigator.of(context).pushNamed(AppRoutes.akLogs)),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '创建 AK',
            onPressed: () => unawaited(_createAk()),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AkListState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(akListControllerProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(akListControllerProvider.notifier).refresh(),
        child: ListView(
          children: const <Widget>[
            SizedBox(height: 120),
            Center(
              child: Text(
                '暂无 AccessKey，点击右上角创建',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(akListControllerProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length,
        itemBuilder: (BuildContext context, int index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AkCard(
            ak: state.items[index],
            onToggle: () => unawaited(_toggleStatus(state.items[index])),
            onPermission: () => unawaited(
              showAkPermissionSheet(context, state.items[index]),
            ),
            onLogs: () =>
                unawaited(showAkLogSheet(context, state.items[index])),
            onDelete: () => unawaited(_deleteAk(state.items[index])),
          ),
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
