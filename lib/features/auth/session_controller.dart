import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_exception.dart';
import '../../core/net/auth_expired_notifier.dart';
import '../../core/net/http_providers.dart';
import '../../core/storage/session_storage.dart';
import '../../core/storage/storage_providers.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/user_info.dart';
import '../../data/repositories/auth_repository.dart';

/// 当前登录态快照，为 null 表示未登录。
class SessionSnapshot {
  const SessionSnapshot({
    required this.uid,
    required this.token,
    this.user,
  });

  /// 用户 id。
  final String uid;

  /// 登录 token。
  final String token;

  /// 用户资料，网络异常时可能为 null。
  final UserInfo? user;

  /// 复制并替换用户资料。
  SessionSnapshot copyWith({UserInfo? user}) {
    return SessionSnapshot(uid: uid, token: token, user: user ?? this.user);
  }
}

/// 全局会话控制器。
///
/// 负责启动时恢复登录态、登录后写入、退出登录，以及响应服务端登录失效。
class SessionController extends AsyncNotifier<SessionSnapshot?> {
  @override
  Future<SessionSnapshot?> build() async {
    final AuthExpiredNotifier notifier = ref.watch(authExpiredNotifierProvider);
    notifier.register(handleAuthExpired);
    ref.onDispose(notifier.unregister);

    final SessionStorage storage = ref.watch(sessionStorageProvider);
    if (!storage.hasSession) {
      return null;
    }

    final String uid = storage.uid!;
    final String token = storage.token!;
    try {
      final UserInfo info = await ref.read(authRepositoryProvider).fetchUserInfo();
      return SessionSnapshot(uid: uid, token: token, user: info);
    } on ApiException catch (error) {
      // 仅登录失效清理本地态，网络异常时保留登录态以便下次启动继续使用。
      if (error.isAuthExpired) {
        await storage.clearSession();
        return null;
      }
      return SessionSnapshot(uid: uid, token: token);
    } on NetworkException {
      return SessionSnapshot(uid: uid, token: token);
    }
  }

  /// 登录成功后写入会话。
  Future<void> applyLogin(AuthUser user) async {
    final SessionStorage storage = ref.read(sessionStorageProvider);
    await storage.saveSession(uid: user.id, token: user.token);

    UserInfo? info;
    try {
      info = await ref.read(authRepositoryProvider).fetchUserInfo();
    } on Exception {
      info = null;
    }
    info ??= UserInfo(
      uid: user.id,
      username: user.username,
      phone: user.phone,
      email: user.email,
    );

    if (!ref.mounted) {
      return;
    }
    state = AsyncData(
      SessionSnapshot(uid: user.id, token: user.token, user: info),
    );
  }

  /// 退出登录。
  Future<void> logout() async {
    await ref.read(sessionStorageProvider).clearSession();
    if (!ref.mounted) {
      return;
    }
    state = const AsyncData<SessionSnapshot?>(null);
  }

  /// 刷新当前用户资料。
  Future<void> refreshUser() async {
    final SessionSnapshot? current = state.asData?.value;
    if (current == null) {
      return;
    }
    try {
      final UserInfo info = await ref.read(authRepositoryProvider).fetchUserInfo();
      if (!ref.mounted) {
        return;
      }
      state = AsyncData(current.copyWith(user: info));
    } on Exception {
      // 刷新失败保持原有资料。
    }
  }

  /// 服务端返回登录失效时清理会话。
  void handleAuthExpired() {
    Future<void>.microtask(() async {
      final SessionStorage storage = ref.read(sessionStorageProvider);
      await storage.clearSession();
      if (!ref.mounted) {
        return;
      }
      state = const AsyncData<SessionSnapshot?>(null);
    });
  }
}

/// 全局会话状态。
final AsyncNotifierProvider<SessionController, SessionSnapshot?>
    sessionControllerProvider =
    AsyncNotifierProvider<SessionController, SessionSnapshot?>(
  SessionController.new,
);
