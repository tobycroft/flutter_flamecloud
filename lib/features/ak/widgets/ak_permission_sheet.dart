import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/net/api_exception.dart';
import '../../../data/models/access_key.dart';
import '../../../data/repositories/access_key_repository.dart';

/// 权限矩阵定义：资源 × 动作，与 vue_flamecloud/PermissionModal 保持一致。
const List<(String, String)> _kResources = <(String, String)>[
  ('ecs', '云服务器'),
  ('billing', '费用中心'),
];
const List<(String, String)> _kActions = <(String, String)>[
  ('read', '只读'),
  ('write', '读写'),
  ('admin', '管理'),
];

/// 弹出「AK 权限配置」底部弹窗。
Future<void> showAkPermissionSheet(
  BuildContext context,
  AccessKeyItem ak,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => AkPermissionSheet(ak: ak),
  );
}

/// AK 权限配置弹窗，搬迁自 vue_flamecloud/PermissionModal。
///
/// 打开时拉取已有权限填充勾选矩阵，保存时全量提交
/// 资源（ecs/billing）× 动作（read/write/admin）的组合。
class AkPermissionSheet extends ConsumerStatefulWidget {
  const AkPermissionSheet({super.key, required this.ak});

  /// 目标 AK。
  final AccessKeyItem ak;

  @override
  ConsumerState<AkPermissionSheet> createState() => _AkPermissionSheetState();
}

class _AkPermissionSheetState extends ConsumerState<AkPermissionSheet> {
  final Set<String> _grants = <String>{};
  bool _loading = true;
  bool _saving = false;
  String? _errorText;

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
      _errorText = null;
    });
    try {
      final Set<String> grants = await ref
          .read(accessKeyRepositoryProvider)
          .fetchPermissions(akId: widget.ak.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _grants.addAll(grants);
        _loading = false;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorText = _errorOf(error, '权限加载失败');
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    final Map<String, bool> payload = <String, bool>{
      for (final (String, String) resource in _kResources)
        for (final (String, String) action in _kActions)
          '${resource.$1}_${action.$1}': _grants.contains(
            '${resource.$1}_${action.$1}',
          ),
    };
    try {
      await ref
          .read(accessKeyRepositoryProvider)
          .savePermissions(akId: widget.ak.id, grants: payload);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('权限保存成功')));
      Navigator.of(context).pop();
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorText = _errorOf(error, '权限保存失败');
      });
    }
  }

  /// 统一提取业务/网络异常的可展示文案。
  static String _errorOf(Object error, String fallback) {
    if (error is ApiException && error.message.isNotEmpty) {
      return error.message;
    }
    if (error is NetworkException) {
      return error.message;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '权限配置${widget.ak.name.isEmpty ? '' : ' · ${widget.ak.name}'}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '配置该 AK 可访问的资源与操作级别',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...<Widget>[
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: <TableRow>[
                TableRow(
                  children: <Widget>[
                    const SizedBox.shrink(),
                    for (final (String, String) action in _kActions)
                      Center(
                        child: Text(
                          action.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final (String, String) resource in _kResources)
                  TableRow(
                    children: <Widget>[
                      Text(
                        resource.$2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      for (final (String, String) action in _kActions)
                        Center(
                          child: Checkbox(
                            value: _grants.contains(
                              '${resource.$1}_${action.$1}',
                            ),
                            onChanged: (bool? value) => setState(() {
                              final String key =
                                  '${resource.$1}_${action.$1}';
                              if (value == true) {
                                _grants.add(key);
                              } else {
                                _grants.remove(key);
                              }
                            }),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => unawaited(_save()),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
