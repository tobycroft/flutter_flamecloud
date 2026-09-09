import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/auth/auth_gate.dart';

/// 火焰云控制台 App 根组件。
class FlameCloudApp extends ConsumerWidget {
  const FlameCloudApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeMode themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp(
      title: '火焰云',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // OLED 与深色同属暗色系，只是暗色主题换成纯黑版本。
      darkTheme:
          themeMode == AppThemeMode.oled ? AppTheme.oled() : AppTheme.dark(),
      themeMode: switch (themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark ||
        AppThemeMode.oled => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      home: const AuthGate(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
