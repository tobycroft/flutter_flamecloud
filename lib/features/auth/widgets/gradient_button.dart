import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 品牌渐变主按钮。
///
/// 对齐 Vue 登录页 `bg-gradient-to-r from-flame-500 to-orange-500`。
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.text,
    super.key,
    this.onPressed,
    this.loading = false,
    this.height = 54,
  });

  /// 按钮文案。
  final String text;

  /// 点击回调，为 null 或加载中时禁用。
  final VoidCallback? onPressed;

  /// 是否展示加载中状态。
  final bool loading;

  /// 高度。
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !loading && onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.loginButtonGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: enabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.flame500.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: SizedBox(
              height: height,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '登录中...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
