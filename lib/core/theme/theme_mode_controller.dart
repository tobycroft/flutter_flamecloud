import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';

/// 应用主题模式。
///
/// 在 Flutter 原生 [ThemeMode]（light/dark/system）基础上增加 OLED
/// 纯黑模式；oled 归入暗色系，仅在使用的 ThemeData 上有区别。
enum AppThemeMode {
  /// 浅色。
  light,

  /// 深色。
  dark,

  /// OLED 纯黑。
  oled,

  /// 跟随系统。
  system,
}

/// 主题模式控制器。
///
/// 在 vue_flamecloud/src/composables/useTheme.ts 的三态循环基础上
/// 增加 OLED 档位：light -> dark -> oled -> system，并持久化到
/// SharedPreferences。
class ThemeModeController extends Notifier<AppThemeMode> {
  /// 持久化键名，与 Vue 端 localStorage 的 `theme` 对应。
  static const String storageKey = 'theme';

  @override
  AppThemeMode build() {
    final String? value = ref.watch(sharedPreferencesProvider).getString(storageKey);
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      'oled' => AppThemeMode.oled,
      _ => AppThemeMode.system,
    };
  }

  /// 切换主题：light -> dark -> oled -> system -> light。
  Future<void> toggle() async {
    final AppThemeMode next = switch (state) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.oled,
      AppThemeMode.oled => AppThemeMode.system,
      AppThemeMode.system => AppThemeMode.light,
    };
    await setMode(next);
  }

  /// 指定主题模式。
  Future<void> setMode(AppThemeMode mode) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(storageKey, mode.name);
    state = mode;
  }
}

/// 全局主题模式。
final NotifierProvider<ThemeModeController, AppThemeMode>
    themeModeControllerProvider =
    NotifierProvider<ThemeModeController, AppThemeMode>(
  ThemeModeController.new,
);
