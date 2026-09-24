import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_release.dart';
import 'apk_downloader.dart';
import 'app_installer.dart';

/// 更新包下载安装阶段。
enum UpdateInstallPhase {
  /// 初始状态，等待用户确认。
  idle,

  /// 正在下载 APK。
  downloading,

  /// 已下载完成，正在拉起系统安装器。
  installing,

  /// 需要用户在系统设置中授予「安装未知应用」权限。
  permission,

  /// 已成功拉起系统安装器。
  done,

  /// 失败。
  failure,
}

/// 更新包下载安装状态。
@immutable
class UpdateInstallState {
  const UpdateInstallState({
    this.phase = UpdateInstallPhase.idle,
    this.progress = 0,
    this.message = '',
  });

  /// 当前阶段。
  final UpdateInstallPhase phase;

  /// 下载进度，取值 0~1。
  final double progress;

  /// 失败或需要用户操作时的提示文案。
  final String message;

  /// 是否处于不可中断的进行中状态。
  bool get busy =>
      phase == UpdateInstallPhase.downloading ||
      phase == UpdateInstallPhase.installing;

  /// 复制出新状态。
  UpdateInstallState copyWith({
    UpdateInstallPhase? phase,
    double? progress,
    String? message,
  }) {
    return UpdateInstallState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      message: message ?? this.message,
    );
  }
}

/// 更新包下载安装控制器。
///
/// 负责把 release 的 APK 附件下载到应用私有目录，并在下载完成后直接拉起
/// 系统安装器；未授予「安装未知应用」权限时先引导用户到系统设置页，
/// 用户返回后调用 [continueInstall] 继续安装。
class UpdateInstallController extends Notifier<UpdateInstallState> {
  @override
  UpdateInstallState build() {
    return const UpdateInstallState();
  }

  /// 已下载完成的 APK 路径，授权后继续安装时复用。
  String? _apkPath;

  /// 下载并拉起安装。
  Future<void> start(AppRelease release) async {
    if (state.busy) {
      return;
    }
    final String url = release.apkDownloadUrl?.trim() ?? '';
    if (url.isEmpty) {
      state = const UpdateInstallState(
        phase: UpdateInstallPhase.failure,
        message: '未找到可下载的 APK，请前往下载页手动安装',
      );
      return;
    }

    _apkPath = null;
    state = const UpdateInstallState(phase: UpdateInstallPhase.downloading);
    try {
      final String path = await ref.read(apkDownloaderProvider).download(
            url,
            fileName: _fileName(release),
            onProgress: (int received, int total) {
              if (!ref.mounted) {
                return;
              }
              state = UpdateInstallState(
                phase: UpdateInstallPhase.downloading,
                progress: total > 0 ? (received / total).clamp(0.0, 1.0) : 0,
              );
            },
          );
      if (!ref.mounted) {
        return;
      }
      _apkPath = path;
      await _install();
    } on Exception {
      if (!ref.mounted) {
        return;
      }
      state = const UpdateInstallState(
        phase: UpdateInstallPhase.failure,
        message: '下载失败，请检查网络后重试',
      );
    }
  }

  /// 用户在系统设置完成授权后继续安装。
  Future<void> continueInstall() async {
    if (_apkPath == null || state.busy) {
      return;
    }
    await _install();
  }

  /// 回到初始状态，便于关闭弹窗后再次使用。
  void reset() {
    _apkPath = null;
    state = const UpdateInstallState();
  }

  /// 拉起系统安装器安装 [_apkPath]。
  Future<void> _install() async {
    final String? path = _apkPath;
    if (path == null) {
      return;
    }
    state = state.copyWith(
      phase: UpdateInstallPhase.installing,
      progress: 1,
      message: '',
    );

    final bool allowed = await AppInstaller.canRequestInstallPackages();
    if (!ref.mounted) {
      return;
    }
    if (!allowed) {
      await AppInstaller.openInstallPermissionSettings();
      if (!ref.mounted) {
        return;
      }
      state = const UpdateInstallState(
        phase: UpdateInstallPhase.permission,
        progress: 1,
        message: '请在系统设置中允许安装未知应用，完成后返回继续安装',
      );
      return;
    }

    final bool launched = await AppInstaller.installApk(path);
    if (!ref.mounted) {
      return;
    }
    state = launched
        ? const UpdateInstallState(
            phase: UpdateInstallPhase.done,
            progress: 1,
          )
        : const UpdateInstallState(
            phase: UpdateInstallPhase.failure,
            progress: 1,
            message: '唤起安装失败，请前往下载页手动安装',
          );
  }

  /// APK 文件名：带上版本标签，便于排查与清理。
  static String _fileName(AppRelease release) {
    final String tag = release.tagName.trim();
    return 'flamecloud-${tag.isEmpty ? 'latest' : tag}.apk';
  }
}

/// 更新包下载安装状态。
///
/// 使用 autoDispose：弹窗关闭后状态自动重置，下次弹出更新提示时不会残留
/// 上一次的进度或失败信息。
final updateInstallControllerProvider = NotifierProvider.autoDispose<
    UpdateInstallController,
    UpdateInstallState>(
  UpdateInstallController.new,
);
