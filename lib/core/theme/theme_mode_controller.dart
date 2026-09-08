import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';

/// 主题模式控制器。
///
/// 行为对齐 vue_flamecloud/src/composables/useTheme.ts：
/// 三态循环 light -> dark -> system，并持久化到 SharedPreferences。
class ThemeModeController extends Notifier<ThemeMode> {
  /// 持久化键名，与 Vue 端 localStorage 的 `theme` 对应。
  static const String storageKey = 'theme';

  @override
  ThemeMode build() {
    final String? value = ref.watch(sharedPreferencesProvider).getString(storageKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// 切换主题：light -> dark -> system -> light。
  Future<void> toggle() async {
    final ThemeMode next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    await setMode(next);
  }

  /// 指定主题模式。
  Future<void> setMode(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(storageKey, mode.name);
    state = mode;
  }
}

/// 全局主题模式。
final NotifierProvider<ThemeModeController, ThemeMode> themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
