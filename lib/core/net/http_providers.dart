import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_expired_notifier.dart';
import 'dio_client.dart';
import '../storage/storage_providers.dart';

/// 登录失效广播实例。
final Provider<AuthExpiredNotifier> authExpiredNotifierProvider =
    Provider<AuthExpiredNotifier>((Ref ref) => AuthExpiredNotifier());

/// 全局 dio 实例。
final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final Dio dio = DioClient.create(
    auth: ref.watch(authTokenSourceProvider),
    onAuthExpired: () => ref.read(authExpiredNotifierProvider).notify(),
  );
  ref.onDispose(dio.close);
  return dio;
});
