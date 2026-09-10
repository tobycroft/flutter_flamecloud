import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 表面与容器配色。
///
/// 拆成三级，让「底色 / 组件面 / 组件内层」在不同主题下各自独立：
/// - light：白卡片 + 极浅灰内层
/// - dark：中性深灰底 + 藏青蓝组件面（沿用 dark500 色阶）
/// - oled：纯黑底 + VS Code 风格深灰组件面
///
/// 通过 [AppSurfaces.of] 或 `context.surfaces` 读取，
/// 避免各页面把卡片色写死成 AppColors.dark500。
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.panel,
    required this.inset,
    required this.line,
  });

  /// 浅色。
  const AppSurfaces.light()
      : panel = Colors.white,
        inset = const Color(0xFFF9FAFB),
        line = const Color(0xFFE5E7EB);

  /// 深色：中性深灰底 + 藏青蓝组件面。
  const AppSurfaces.dark()
      : panel = AppColors.dark500,
        inset = AppColors.dark400,
        line = AppColors.dark300;

  /// OLED 纯黑：纯黑底 + 深灰组件面。
  const AppSurfaces.oled()
      : panel = AppColors.oledPanel,
        inset = AppColors.oledInset,
        line = AppColors.oledLine;

  /// 卡片、弹层、底部栏等一级容器面。
  final Color panel;

  /// 二级容器面：输入框、附件块、未选中 chip 等。
  final Color inset;

  /// 描边与分隔线。
  final Color line;

  /// 从当前 Theme 读取，未注册时回退浅色（理论上不会发生）。
  static AppSurfaces of(BuildContext context) {
    return Theme.of(context).extension<AppSurfaces>() ??
        const AppSurfaces.light();
  }

  @override
  AppSurfaces copyWith({Color? panel, Color? inset, Color? line}) {
    return AppSurfaces(
      panel: panel ?? this.panel,
      inset: inset ?? this.inset,
      line: line ?? this.line,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) {
      return this;
    }
    return AppSurfaces(
      panel: Color.lerp(panel, other.panel, t) ?? panel,
      inset: Color.lerp(inset, other.inset, t) ?? inset,
      line: Color.lerp(line, other.line, t) ?? line,
    );
  }
}

/// 便捷读取当前主题的三级表面色。
extension AppSurfacesContext on BuildContext {
  /// 当前主题的容器配色。
  AppSurfaces get surfaces => AppSurfaces.of(this);
}
