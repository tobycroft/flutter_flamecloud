/// 自动更新来源（GitHub Releases）常量。
class AppUpdateConfig {
  const AppUpdateConfig._();

  /// GitHub 仓库所有者。
  static const String githubOwner = 'tobycroft';

  /// GitHub 仓库名。
  static const String githubRepo = 'flutter_flamecloud';

  /// GitHub API：最新 release 端点。
  static const String latestReleaseApi =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// GitHub Releases 页面地址（无 APK 附件时兜底跳转）。
  static const String releasesPageUrl =
      'https://github.com/$githubOwner/$githubRepo/releases';
}
