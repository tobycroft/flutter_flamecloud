import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_release.dart';
import '../app_installer.dart';
import '../update_install_controller.dart';

/// 弹出更新提示。
///
/// Android 且 release 带 APK 附件时在 APP 内下载并自动拉起安装；
/// 其他平台（iOS）或没有 APK 附件时退回跳转下载页。
Future<void> showUpdateDialog(BuildContext context, AppRelease release) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => UpdateDialog(release: release),
  );
}

/// 更新提示弹窗。
///
/// 展示远端新版本号与更新日志，确认后下载 APK（带进度），下载完成直接拉起
/// 系统安装器，不再跳浏览器手动下载。
class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({
    required this.release,
    super.key,
  });

  /// 本次检查到的远端 release。
  final AppRelease release;

  /// 是否走 APP 内下载安装：仅 Android 且存在 APK 附件。
  bool get _inAppInstall =>
      AppInstaller.supported && (release.apkDownloadUrl?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UpdateInstallState install =
        ref.watch(updateInstallControllerProvider);

    // 已拉起系统安装器后关闭弹窗，交给安装器接管
    ref.listen<UpdateInstallState>(
      updateInstallControllerProvider,
      (UpdateInstallState? previous, UpdateInstallState next) {
        if (next.phase == UpdateInstallPhase.done) {
          Navigator.of(context).pop();
        }
      },
    );

    return PopScope<Object?>(
      // 下载/安装过程中不允许返回键中断
      canPop: !install.busy,
      child: AlertDialog(
        title: _buildTitle(),
        content: _buildContent(context, install),
        actions: _buildActions(context, ref, install),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppColors.flameGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.system_update_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Text('发现新版本')),
      ],
    );
  }

  Widget _buildContent(BuildContext context, UpdateInstallState install) {
    final Color hintColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          release.tagName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (release.changelog.isNotEmpty) ...<Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: SelectableText(
                release.changelog,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: hintColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (install.phase == UpdateInstallPhase.downloading) ...<Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: install.progress > 0 ? install.progress : null,
              minHeight: 6,
              backgroundColor: hintColor.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.flame500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            install.progress > 0
                ? '正在下载… ${(install.progress * 100).toStringAsFixed(0)}%'
                : '正在下载…',
            style: TextStyle(fontSize: 12, color: hintColor),
          ),
        ] else if (install.message.isNotEmpty)
          Text(
            install.message,
            style: TextStyle(fontSize: 12, color: hintColor),
          )
        else
          Text(
            _inAppInstall
                ? '点击「立即更新」将在 APP 内下载并自动安装'
                : '点击「立即更新」将前往下载页面',
            style: TextStyle(fontSize: 12, color: hintColor),
          ),
        if (install.phase == UpdateInstallPhase.failure) ...<Widget>[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _openDownloadPage(release.targetUrl),
            child: const Text(
              '或前往下载页手动安装',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.flame500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    UpdateInstallState install,
  ) {
    final void Function()? later = install.busy
        ? null
        : () {
            ref.read(updateInstallControllerProvider.notifier).reset();
            Navigator.of(context).pop();
          };

    Widget confirm;
    if (!_inAppInstall) {
      confirm = TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          _openDownloadPage(release.targetUrl);
        },
        style: TextButton.styleFrom(foregroundColor: AppColors.flame500),
        child: const Text('立即更新'),
      );
    } else if (install.phase == UpdateInstallPhase.permission) {
      confirm = TextButton(
        onPressed: () => ref
            .read(updateInstallControllerProvider.notifier)
            .continueInstall(),
        style: TextButton.styleFrom(foregroundColor: AppColors.flame500),
        child: const Text('继续安装'),
      );
    } else if (install.phase == UpdateInstallPhase.failure) {
      confirm = TextButton(
        onPressed: () =>
            ref.read(updateInstallControllerProvider.notifier).start(release),
        style: TextButton.styleFrom(foregroundColor: AppColors.flame500),
        child: const Text('重试'),
      );
    } else {
      confirm = TextButton(
        onPressed: install.busy
            ? null
            : () =>
                ref.read(updateInstallControllerProvider.notifier).start(
                      release,
                    ),
        style: TextButton.styleFrom(foregroundColor: AppColors.flame500),
        child: const Text('立即更新'),
      );
    }

    return <Widget>[
      TextButton(
        onPressed: later,
        child: const Text('稍后再说'),
      ),
      confirm,
    ];
  }
}

/// 跳转下载页，失败时静默忽略。
Future<void> _openDownloadPage(String url) async {
  final Uri uri = Uri.tryParse(url) ?? Uri.parse('');
  if (uri.host.isEmpty) {
    return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    // 打不开浏览器不做提示，用户可稍后手动前往 Releases 页面。
  }
}
