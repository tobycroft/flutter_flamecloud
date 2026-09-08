import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_flamecloud/app.dart';
import 'package:flutter_flamecloud/core/storage/storage_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 构建带本地存储桩的 App。
  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> values = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(values);
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FlameCloudApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('未登录时进入登录页', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('账号密码登录'), findsOneWidget);
    expect(find.text('欢迎回来，请登录您的账户'), findsOneWidget);
    expect(find.text('立即登录'), findsOneWidget);
    expect(find.text('火焰云控制台'), findsNothing);
  });

  testWidgets('登录表单缺少必填项时给出提示', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('立即登录'));
    await tester.pumpAndSettle();

    expect(find.text('请输入用户名'), findsOneWidget);
  });
}
