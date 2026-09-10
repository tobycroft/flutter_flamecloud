import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/models/app_release.dart';
import '../../data/repositories/app_update_repository.dart';

/// 检查结果：无更新时 data 为 null，有更新时为远端 [AppRelease]。
typedef UpdateCheckState = AsyncValue<AppRelease?>;

/// 自动更新控制器。
///
/// 进入控制台后调用 [checkForUpdate] 拉取 Gitee 最新 release 并与本地
/// 版本比较，有新版本时由页面监听状态弹出更新提示。
class UpdateController extends Notifier<UpdateCheckState> {
  @override
  UpdateCheckState build() {
    return const AsyncData<AppRelease?>(null);
  }

  /// 检查更新。
  ///
  /// 检查失败时静默置回 null（不打扰用户），本地版本号读取失败同样视为无更新。
  Future<void> checkForUpdate() async {
    state = const AsyncLoading<AppRelease?>();
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      final AppRelease release =
          await ref.read(appUpdateRepositoryProvider).fetchLatestRelease();
      final bool hasUpdate = release.isNewerThan(info.version);
      if (!ref.mounted) {
        return;
      }
      state = AsyncData<AppRelease?>(hasUpdate ? release : null);
    } on Exception {
      if (!ref.mounted) {
        return;
      }
      state = const AsyncData<AppRelease?>(null);
    }
  }

  /// 用户关闭提示后清除当前结果，避免切页后重复弹窗。
  void dismiss() {
    state = const AsyncData<AppRelease?>(null);
  }
}

/// 自动更新状态。
final NotifierProvider<UpdateController, UpdateCheckState>
    updateControllerProvider =
    NotifierProvider<UpdateController, UpdateCheckState>(
  UpdateController.new,
);
