import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/captcha.dart';
import 'auth_text_field.dart';

/// 验证码输入 + 图片。
///
/// 后端返回 GIF base64，点击图片可刷新，与 Vue 端交互一致。
class CaptchaField extends StatelessWidget {
  const CaptchaField({
    required this.controller,
    required this.captcha,
    required this.loading,
    required this.onRefresh,
    super.key,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
  });

  /// 验证码输入控制器。
  final TextEditingController controller;

  /// 当前验证码，为空时展示占位块。
  final Captcha? captcha;

  /// 是否正在加载验证码。
  final bool loading;

  /// 点击刷新回调。
  final VoidCallback onRefresh;

  /// 键盘动作。
  final TextInputAction? textInputAction;

  /// 提交回调。
  final ValueChanged<String>? onSubmitted;

  /// 是否可编辑。
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AuthTextField(
            controller: controller,
            hintText: '验证码',
            prefixIcon: Icons.shield_outlined,
            enabled: enabled,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            autofillHints: const <String>[AutofillHints.oneTimeCode],
          ),
        ),
        const SizedBox(width: 12),
        _CaptchaImage(
          captcha: captcha,
          loading: loading,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}

class _CaptchaImage extends StatelessWidget {
  const _CaptchaImage({
    required this.captcha,
    required this.loading,
    required this.onRefresh,
  });

  static const double _width = 128;
  static const double _height = 56;

  final Captcha? captcha;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = captcha?.decodeImageBytes();
    final bool hasImage = bytes != null && bytes.isNotEmpty;

    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onRefresh,
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: hasImage
                  ? Colors.transparent
                  : AppColors.flame500.withValues(alpha: 0.35),
            ),
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: hasImage
                ? Image.memory(
                    bytes,
                    key: ValueKey<String>(captcha!.ident),
                    width: _width,
                    height: _height,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                  )
                : Text(
                    loading ? '加载中...' : '点击刷新',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.flame500.withValues(alpha: 0.8),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
