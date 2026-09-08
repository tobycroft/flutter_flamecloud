import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 登录表单输入框。
///
/// 视觉对齐 Vue 登录页：灰底、圆角 12、左侧图标、聚焦时品牌主色描边。
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    super.key,
    this.obscureText = false,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.keyboardType,
    this.autofillHints,
  });

  /// 文本控制器。
  final TextEditingController controller;

  /// 占位文案。
  final String hintText;

  /// 左侧图标。
  final IconData prefixIcon;

  /// 是否隐藏输入内容。
  final bool obscureText;

  /// 右侧组件，例如明文切换按钮。
  final Widget? suffix;

  /// 键盘动作。
  final TextInputAction? textInputAction;

  /// 提交回调。
  final ValueChanged<String>? onSubmitted;

  /// 是否可编辑。
  final bool enabled;

  /// 键盘类型。
  final TextInputType? keyboardType;

  /// 自动填充提示。
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, size: 20),
        suffixIcon: suffix,
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        isDense: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}
