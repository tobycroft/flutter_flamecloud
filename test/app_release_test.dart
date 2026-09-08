import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flamecloud/data/models/app_release.dart';

void main() {
  group('AppRelease 版本比较', () {
    test('远端 tag 带前缀 v 时可正确解析并比较', () {
      final AppRelease release = AppRelease(
        tagName: 'v1.0.5',
        name: 'Release v1.0.5',
        changelog: '',
        pageUrl: 'https://github.com/tobycroft/flutter_flamecloud/releases/tag/v1.0.5',
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
        pageUrl: 'https://github.com/tobycroft/flutter_flamecloud/releases/tag/v1.1.0',
      );
      expect(release.isNewerThan('1.0.0+1'), isTrue);
      expect(release.isNewerThan('1.1.0+7'), isFalse);
    });

    test('位数不齐时按 0 补齐比较', () {
      final AppRelease release = AppRelease(
        tagName: 'v2.0',
        name: 'Release v2.0',
        changelog: '',
        pageUrl: 'https://github.com/tobycroft/flutter_flamecloud/releases/tag/v2.0',
      );
      expect(release.isNewerThan('1.9.9'), isTrue);
      expect(release.isNewerThan('2.0.0'), isFalse);
    });

    test('非法版本号时视为无更新', () {
      final AppRelease release = AppRelease(
        tagName: 'not-a-version',
        name: 'Release',
        changelog: '',
        pageUrl: 'https://github.com/tobycroft/flutter_flamecloud/releases',
      );
      expect(release.isNewerThan('1.0.0'), isFalse);
    });

    test('从 GitHub release JSON 构造时提取 APK 直链', () {
      final AppRelease release = AppRelease.fromMap(<String, dynamic>{
        'tag_name': 'v1.0.5',
        'name': 'Release v1.0.5',
        'body': '**Full Changelog**: v1.0.4...v1.0.5',
        'html_url':
            'https://github.com/tobycroft/flutter_flamecloud/releases/tag/v1.0.5',
        'assets': <dynamic>[
          <String, dynamic>{
            'name': 'app-release.apk',
            'browser_download_url':
                'https://github.com/tobycroft/flutter_flamecloud/releases/download/v1.0.5/app-release.apk',
          },
        ],
      });
      expect(release.tagName, 'v1.0.5');
      expect(
        release.apkDownloadUrl,
        'https://github.com/tobycroft/flutter_flamecloud/releases/download/v1.0.5/app-release.apk',
      );
      expect(release.targetUrl, release.apkDownloadUrl);
    });
  });
}
