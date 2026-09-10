/// 自动更新来源（Gitee Releases）常量。
///
/// 发布仓库：https://gitee.com/tuuz/firecloud-app/releases
class AppUpdateConfig {
  const AppUpdateConfig._();

  /// Gitee 仓库所有者。
  static const String owner = 'tuuz';

  /// Gitee 发布仓库名。
  static const String repo = 'firecloud-app';

  /// Gitee API：最新 release 端点。
  static const String latestReleaseApi =
      'https://gitee.com/api/v5/repos/$owner/$repo/releases/latest';

  /// Gitee Releases 页面地址（无 APK 附件时兜底跳转）。
  static const String releasesPageUrl = 'https://gitee.com/$owner/$repo/releases';

  /// Gitee 私人令牌（可选）。
  ///
  /// 留空时匿名访问接口；如需提高调用限额，可通过
  /// `flutter run --dart-define=GITEE_ACCESS_TOKEN=xxx` 注入。
  static const String accessToken = String.fromEnvironment('GITEE_ACCESS_TOKEN');

  /// 指定版本标签的 release 详情页地址。
  ///
  /// Gitee 接口不返回 `html_url`，由客户端按标签拼接。
  static String releaseTagUrl(String tagName) =>
      '$releasesPageUrl/tag/$tagName';
}
