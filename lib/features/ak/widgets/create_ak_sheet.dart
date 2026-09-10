import 'dart:async';

import '../../../../core/theme/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/net/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/access_key.dart';
import '../ak_list_controller.dart';

/// 弹出「创建 AK」底部弹窗。
Future<void> showCreateAkSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => const CreateAkSheet(),
  );
}

/// 创建 AK 弹窗，搬迁自 vue_flamecloud/CreateAkModal。
///
/// 两阶段交互：输入备注名创建；成功后展示仅此一次的
/// AccessKey / AccessSecret，提示用户立即复制保存。
class CreateAkSheet extends ConsumerStatefulWidget {
  const CreateAkSheet({super.key});

  @override
  ConsumerState<CreateAkSheet> createState() => _CreateAkSheetState();
}

class _CreateAkSheetState extends ConsumerState<CreateAkSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _submitting = false;
  String? _errorText;
  AccessKeySecret? _secret;
  bool _secretVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = '请输入备注名称');
      return;
    }
    setState(() {
      _submitting = true;
      _errorText = null;
    });
    try {
      final AccessKeySecret secret =
          await ref.read(akListControllerProvider.notifier).createAk(name);
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _secret = secret;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = error.message.isEmpty ? '创建失败' : error.message;
      });
    } on NetworkException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = error.message;
      });
    } on Exception {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = '创建失败，请稍后重试';
      });
    }
  }

  Future<void> _copy(String text, String tip) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(tip)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AccessKeySecret? secret = _secret;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            secret == null ? '创建 AK' : 'AK 创建成功',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (secret == null) ...<Widget>[
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: '备注名称，如「服务器部署」',
                errorText: _errorText,
              ),
              onSubmitted: (_) => unawaited(_submit()),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : () => unawaited(_submit()),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('创建'),
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_outlined,
                    size: 18,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AccessSecret 仅在创建时显示一次，请立即复制保存，'
                      '关闭后将无法找回。',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SecretField(
              label: 'AccessKey',
              value: secret.accessKey,
              onCopy: () =>
                  unawaited(_copy(secret.accessKey, 'AccessKey 已复制')),
            ),
            const SizedBox(height: 12),
            _SecretField(
              label: 'AccessSecret',
              value: secret.accessSecret,
              obscure: !_secretVisible,
              onToggleVisible: () =>
                  setState(() => _secretVisible = !_secretVisible),
              onCopy: () => unawaited(
                _copy(secret.accessSecret, 'AccessSecret 已复制'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('我已保存，关闭'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Secret 展示行：等宽字体 + 掩码切换 + 复制按钮。
class _SecretField extends StatelessWidget {
  const _SecretField({
    required this.label,
    required this.value,
    required this.onCopy,
    this.obscure,
    this.onToggleVisible,
  });

  final String label;
  final String value;

  /// 是否掩码展示；为 null 时表示不支持切换（如 AccessKey）。
  final bool? obscure;
  final VoidCallback? onToggleVisible;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hidden = obscure ?? false;
    final String display = hidden ? '•' * 12 : value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaces.inset,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: context.surfaces.line,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onToggleVisible != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onToggleVisible,
              icon: Icon(
                hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
              tooltip: hidden ? '显示' : '隐藏',
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 18),
            color: AppColors.flame500,
            tooltip: '复制',
          ),
        ],
      ),
    );
  }
}
