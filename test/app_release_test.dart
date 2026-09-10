import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flamecloud/data/models/app_release.dart';

void main() {
  group('AppRelease 版本比较', () {
    test('远端 tag 带前缀 v 时可正确解析并比较', () {
      final AppRelease release = AppRelease(
        tagName: 'v1.0.5',
        name: 'Release v1.0.5',
        changelog: '',
        pageUrl: 'https://gitee.com/tuuz/firecloud-app/releases/tag/v1.0.5',
      );
      expect(release.isNewerThan('1.0.0'), isTrue);
      expect(release.isNewerThan('1.0.5'), isFalse);
      expect(release.isNewerThan('1.0.6'), isFalse);
      expect(release.isNewerThan('1.1.0'), isFalse);
      expect(release.isNewerThan('0.9.9'), isTrue);
    });

    test('本地版本带 build 号时忽略 build 号比较', () {
      final AppRelease release = AppRelease(
        tagName: 'v1.1.0',
        name: 'Release v1.1.0',
        changelog: '',
        pageUrl: 'https://gitee.com/tuuz/firecloud-app/releases/tag/v1.1.0',
      );
      expect(release.isNewerThan('1.0.0+1'), isTrue);
      expect(release.isNewerThan('1.1.0+7'), isFalse);
    });

    test('位数不齐时按 0 补齐比较', () {
      final AppRelease release = AppRelease(
        tagName: 'v2.0',
        name: 'Release v2.0',
        changelog: '',
        pageUrl: 'https://gitee.com/tuuz/firecloud-app/releases/tag/v2.0',
      );
      expect(release.isNewerThan('1.9.9'), isTrue);
      expect(release.isNewerThan('2.0.0'), isFalse);
    });

    test('非法版本号时视为无更新', () {
      final AppRelease release = AppRelease(
        tagName: 'not-a-version',
        name: 'Release',
        changelog: '',
        pageUrl: 'https://gitee.com/tuuz/firecloud-app/releases',
      );
      expect(release.isNewerThan('1.0.0'), isFalse);
    });

    test('从 Gitee release JSON 构造时提取 APK 直链', () {
      final AppRelease release = AppRelease.fromMap(
        <String, dynamic>{
          'tag_name': 'v1.0.37',
          'name': 'Release v1.0.37',
          'body': '自动发布的新版本 v1.0.37',
          'assets': <dynamic>[
            <String, dynamic>{
              'name': 'v1.0.37.zip',
              'browser_download_url':
                  'https://gitee.com/tuuz/firecloud-app/archive/refs/tags/v1.0.37.zip',
            },
            <String, dynamic>{
              'name': 'app-release.apk',
              'browser_download_url':
                  'https://gitee.com/tuuz/firecloud-app/releases/download/v1.0.37/app-release.apk',
            },
          ],
        },
        fallbackPageUrl:
            'https://gitee.com/tuuz/firecloud-app/releases/tag/v1.0.37',
      );
      expect(release.tagName, 'v1.0.37');
      expect(
        release.apkDownloadUrl,
        'https://gitee.com/tuuz/firecloud-app/releases/download/v1.0.37/app-release.apk',
      );
      expect(release.targetUrl, release.apkDownloadUrl);
      // Gitee 不返回 html_url，应回退到按标签拼接的详情页。
      expect(
        release.pageUrl,
        'https://gitee.com/tuuz/firecloud-app/releases/tag/v1.0.37',
      );
    });

    test('无 APK 附件时回退到 release 详情页', () {
      final AppRelease release = AppRelease.fromMap(
        <String, dynamic>{
          'tag_name': 'v1.0.36',
          'name': 'Release v1.0.36',
          'body': '',
          'assets': <dynamic>[
            <String, dynamic>{
              'name': 'v1.0.36.tar.gz',
              'browser_download_url':
                  'https://gitee.com/tuuz/firecloud-app/archive/refs/tags/v1.0.36.tar.gz',
            },
          ],
        },
        fallbackPageUrl:
            'https://gitee.com/tuuz/firecloud-app/releases/tag/v1.0.36',
      );
      expect(release.apkDownloadUrl, isNull);
      expect(
        release.targetUrl,
        'https://gitee.com/tuuz/firecloud-app/releases/tag/v1.0.36',
      );
    });
  });
}
