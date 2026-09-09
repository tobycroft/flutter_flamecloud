import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';

/// 自动更新开关设置。
///
/// 开关状态持久化到 SharedPreferences，默认开启：开启时进入 APP 会自动
/// 检查更新，关闭后不再自动检查（用户仍可在需要时手动触发）。
///
/// 这里是开关本身的状态，实际检查逻辑见 [updateControllerProvider]；
/// 与 ThemeModeController 一样属于本地偏好，不上传服务端。
class AutoUpdateSettingController extends Notifier<bool> {
  /// 持久化键名。
  static const String storageKey = 'auto_update';

  /// 默认值：首次安装未写入过时视为开启。
  static const bool defaultValue = true;

  @override
  bool build() {
    final bool? value =
        ref.watch(sharedPreferencesProvider).getBool(storageKey);
    return value ?? defaultValue;
  }

  /// 设置是否开启自动更新。
  Future<void> setEnabled(bool enabled) async {
    await ref.read(sharedPreferencesProvider).setBool(storageKey, enabled);
    state = enabled;
  }

  /// 切换开关。
  Future<void> toggle() => setEnabled(!state);
}

/// 自动更新开关状态，true 为开启。
final NotifierProvider<AutoUpdateSettingController, bool>
    autoUpdateSettingProvider =
    NotifierProvider<AutoUpdateSettingController, bool>(
  AutoUpdateSettingController.new,
);
