import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../net/auth_token_source.dart';
import '../storage/session_storage.dart';

/// 本地存储实例，在 [ProviderScope] 启动时注入。
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider 必须在 ProviderScope 中通过 override 注入实例',
  );
});

/// 登录态存储。
final Provider<SessionStorage> sessionStorageProvider =
    Provider<SessionStorage>((Ref ref) {
  return SessionStorage(ref.watch(sharedPreferencesProvider));
});

/// 网络层使用的鉴权信息来源。
final Provider<AuthTokenSource> authTokenSourceProvider =
    Provider<AuthTokenSource>((Ref ref) {
  return ref.watch(sessionStorageProvider);
});
