import 'package:flutter/foundation.dart';

import '../../core/utils/json_value.dart';

/// GitHub Release 数据。
///
/// 数据源为 `releases/latest` 接口，用于与本地版本比对判断是否需要升级。
@immutable
class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.name,
    required this.changelog,
    required this.pageUrl,
    this.apkDownloadUrl,
  });

  /// 从 GitHub API 返回的 JSON 构造。
  factory AppRelease.fromMap(Map<String, dynamic> map) {
    final List<dynamic> assets = map['assets'] is List
        ? map['assets'] as List<dynamic>
        : const <dynamic>[];

    // 从附件里找第一个 APK，供 Android 端直接下载安装。
    String? apkUrl;
    for (final Object? asset in assets) {
      if (asset is! Map) {
        continue;
      }
      final String name = JsonValue.string(asset['name']) ?? '';
      final String url = JsonValue.string(asset['browser_download_url']) ?? '';
      if (url.isEmpty) {
        continue;
      }
      if (name.toLowerCase().endsWith('.apk')) {
        apkUrl = url;
        break;
      }
    }

    return AppRelease(
      tagName: JsonValue.string(map['tag_name']) ?? '',
      name: JsonValue.string(map['name']) ?? '',
      changelog: JsonValue.string(map['body']) ?? '',
      pageUrl: JsonValue.string(map['html_url']) ?? '',
      apkDownloadUrl: apkUrl,
    );
  }

  /// 版本标签，如 `v1.0.5`。
  final String tagName;

  /// Release 标题，如 `Release v1.0.5`。
  final String name;

  /// 更新日志（release body，Markdown 原文）。
  final String changelog;

  /// Release 页面地址。
  final String pageUrl;

  /// APK 附件直链（Android 端直接下载），无附件时为 null。
  final String? apkDownloadUrl;

  /// 解析后的语义化版本号（去掉 `v` 前缀），如 `[1, 0, 5]`。
  List<int> get versionParts => _parseVersion(tagName);

  /// 与本地版本比较，远程更新时返回 true。
  ///
  /// [localVersion] 为 package_info 的 version 字段，如 `1.0.0`。
  bool isNewerThan(String localVersion) {
    final List<int> remote = versionParts;
    final List<int> local = _parseVersion(localVersion);
    if (remote.isEmpty || local.isEmpty) {
      return false;
    }
    final int length =
        remote.length > local.length ? remote.length : local.length;
    for (int i = 0; i < length; i++) {
      final int r = i < remote.length ? remote[i] : 0;
      final int l = i < local.length ? local[i] : 0;
      if (r != l) {
        return r > l;
      }
    }
    return false;
  }

  /// 跳转地址：优先 APK 直链，其次 Release 页面。
  String get targetUrl => apkDownloadUrl ?? pageUrl;

  /// 解析 `v1.2.3` / `1.2.3` 形式的版本号为整数段，非法时返回空列表。
  static List<int> _parseVersion(String raw) {
    String text = raw.trim();
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }
    // 去掉 build 号（本地版本形如 `1.0.0+1`）与多余后缀。
    final int plus = text.indexOf('+');
    if (plus >= 0) {
      text = text.substring(0, plus);
    }
    final List<String> segments = text.split('.');
    if (segments.isEmpty) {
      return const <int>[];
    }
    final List<int> parts = <int>[];
    for (final String segment in segments) {
      final int? value = int.tryParse(segment.trim());
      if (value == null) {
        return const <int>[];
      }
      parts.add(value);
    }
    return parts;
  }
}
