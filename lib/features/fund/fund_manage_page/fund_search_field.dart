import 'package:flutter/material.dart';

import '../../../core/theme/app_surfaces.dart';
import '../../../core/theme/app_theme.dart';

/// 资金管理页搜索框。
///
/// 对应 Vue 端「输入框 + 搜索按钮」的组合，回车与按钮均可提交；
/// 两个 tab 的提示文案不同，通过 [hintText] 传入。
class FundSearchField extends StatefulWidget {
  const FundSearchField({
    required this.hintText,
    required this.onSubmitted,
    super.key,
  });

  /// 输入框占位文案。
  final String hintText;

  /// 提交搜索关键词。
  final ValueChanged<String> onSubmitted;

  @override
  State<FundSearchField> createState() => _FundSearchFieldState();
}

class _FundSearchFieldState extends State<FundSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => widget.onSubmitted(_controller.text);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color hintColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF9CA3AF);
    final Color focusedColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (String _) => _submit(),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(fontSize: 14, color: hintColor),
              prefixIcon: Icon(Icons.search, size: 18, color: hintColor),
              prefixIconConstraints: const BoxConstraints(minWidth: 38),
              isDense: true,
              filled: true,
              fillColor: context.surfaces.inset,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: _border(context.surfaces.line),
              enabledBorder: _border(context.surfaces.line),
              focusedBorder: _border(focusedColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: const Text('搜索'),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      borderSide: BorderSide(color: color),
    );
  }
}
