import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_release.dart';

/// 更新提示弹窗。
///
/// 展示远端新版本号与更新日志，确认后跳转 APK 下载（无附件时跳 Releases 页面）。
Future<void> showUpdateDialog(BuildContext context, AppRelease release) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Row(
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
        ),
        content: Column(
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
                      color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '点击「立即更新」将前往下载页面',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('稍后再说'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openDownloadPage(release.targetUrl);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.flame500,
            ),
            child: const Text('立即更新'),
          ),
        ],
      );
    },
  );
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
