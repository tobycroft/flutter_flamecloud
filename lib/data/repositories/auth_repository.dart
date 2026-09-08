import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/dio_client.dart';
import '../../core/net/http_providers.dart';
import '../models/auth_user.dart';
import '../models/captcha.dart';
import '../models/user_info.dart';

/// 认证相关接口。
///
/// 全部以 `application/x-www-form-urlencoded` 提交，与 Vue 端一致。
class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  /// 生成图形验证码。
  Future<Captcha> createCaptcha() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.captcha.create,
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiFormatException();
      }
      return Captcha.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 账号密码登录。
  ///
  /// [ident] 由 [createCaptcha] 返回，[code] 为用户输入的验证码。
  /// [deviceType] 上报设备类型（web/android/ios），后端据此支持多端同时在线，
  /// 同设备类型重复登录会替换该设备的旧 token；缺省自动按运行平台推断。
  Future<AuthUser> login({
    required String username,
    required String password,
    required String ident,
    required String code,
    String? deviceType,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        ApiEndpoints.user.login,
        data: <String, Object?>{
          'username': username,
          'password': password,
          'ident': ident,
          'code': code,
          'device_type': deviceType ?? defaultDeviceType(),
        },
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiFormatException();
      }
      return AuthUser.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  /// 获取当前登录用户资料，同时用于校验登录态是否有效。
  Future<UserInfo> fetchUserInfo() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        ApiEndpoints.user.info,
      );
      final Map<String, dynamic>? data = _unwrap(response).asMap;
      if (data == null) {
        throw const ApiFormatException();
      }
      return UserInfo.fromMap(data);
    } on DioException catch (error) {
      throw error.toAppException();
    }
  }

  ApiEnvelope _unwrap(Response<dynamic> response) {
    final Object? data = response.data;
    if (data is ApiEnvelope) {
      return data;
    }
    throw const ApiFormatException();
  }
}

/// 当前运行平台的设备类型标识，与后端约定的 device_type 一致。
String defaultDeviceType() {
  if (kIsWeb) {
    return 'web';
  }
  return Platform.operatingSystem; // android / ios
}

/// 认证仓库实例。
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
  return AuthRepository(ref.watch(dioProvider));
});
