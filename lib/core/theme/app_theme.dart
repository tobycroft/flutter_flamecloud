import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_surfaces.dart';

/// 应用主题。
///
/// 对齐 vue_flamecloud 的明暗双主题（tailwind `darkMode: 'class'`）。
class AppTheme {
  const AppTheme._();

  /// 卡片圆角，对应 Tailwind `rounded-2xl`(16px)。
  static const double radiusLg = 16;

  /// 输入框圆角，对应 Tailwind `rounded-xl`(12px)。
  static const double radiusMd = 12;

  /// 小圆角，对应 Tailwind `rounded-lg`(8px)。
  static const double radiusSm = 8;

  /// 浅色主题。
  static ThemeData light() => _base(Brightness.light);

  /// 暗色主题。
  static ThemeData dark() => _base(Brightness.dark);

  /// OLED 纯黑主题。
  ///
  /// 页面底色为纯黑（Colors.black），组件面改用 VS Code 风格的深灰，
  /// 既让 OLED 屏幕熄灭底色像素省电，又保留组件的层次。
  static ThemeData oled() => _base(Brightness.dark, oled: true);

  static ThemeData _base(Brightness brightness, {bool oled = false}) {
    final bool isDark = brightness == Brightness.dark;
    // 三级表面色：卡片 / 内层容器 / 描边。
    final AppSurfaces surfaces = !isDark
        ? const AppSurfaces.light()
        : (oled ? const AppSurfaces.oled() : const AppSurfaces.dark());
    final Color surface = surfaces.panel;
    // 页面底色：深色为中性深灰，OLED 为纯黑；两者都与组件面拉开明度差。
    final Color scaffold = !isDark
        ? AppColors.flame50
        : (oled ? Colors.black : AppColors.scaffoldDark);
    final Color inputFill = surfaces.inset;
    final Color inputBorder = surfaces.line;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.flame500,
      brightness: brightness,
      primary: AppColors.flame500,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: isDark ? Colors.white : const Color(0xFF111827),
      error: const Color(0xFFDC2626),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>{surfaces},
      scaffoldBackgroundColor: scaffold,
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
          fontSize: 15,
        ),
        border: _inputBorder(inputBorder),
        enabledBorder: _inputBorder(inputBorder),
        focusedBorder: _inputBorder(AppColors.flame500, width: 1.6),
        errorBorder: _inputBorder(const Color(0xFFDC2626)),
        focusedErrorBorder: _inputBorder(const Color(0xFFDC2626), width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.flame500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.flame500.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.flame500,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: surfaces.line,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        // 选中色沿用品牌主色，与 Vue 端控制台菜单的 flame-500 一致。
        selectedItemColor: AppColors.flame500,
        unselectedItemColor:
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.flame500;
          }
          return Colors.transparent;
        }),
        side: BorderSide(
          color: isDark ? inputBorder : const Color(0xFFD1D5DB),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
