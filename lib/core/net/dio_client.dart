import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/api_config.dart';
import 'api_envelope.dart';
import 'api_exception.dart';
import 'auth_token_source.dart';

/// dio 实例工厂。
class DioClient {
  const DioClient._();

  /// 创建已装配好拦截器的 dio 实例。
  static Dio create({
    required AuthTokenSource auth,
    VoidCallback? onAuthExpired,
  }) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        responseType: ResponseType.json,
        contentType: Headers.formUrlEncodedContentType,
        headers: <String, Object?>{Headers.acceptHeader: Headers.jsonContentType},
      ),
    );

    dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(auth),
      EnvelopeInterceptor(onAuthExpired: onAuthExpired),
      const ErrorMappingInterceptor(),
      if (ApiConfig.enableHttpLog)
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseBody: true,
        ),
    ]);

    return dio;
  }
}

/// 注入鉴权请求头。
///
/// 后端 `HeaderAuthMode = true`，需要平级的 `uid` / `token` 请求头，
/// 与 Vue 端 `getAuthHeaders()` 行为一致。
class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._auth);

  final AuthTokenSource _auth;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? uid = _auth.uid;
    final String? token = _auth.token;
    if (uid != null && uid.isNotEmpty && token != null && token.isNotEmpty) {
      options.headers[ApiConfig.headerUid] = uid;
      options.headers[ApiConfig.headerToken] = token;
    }
    handler.next(options);
  }
}

/// 拆包后端统一响应。
///
/// 成功时把 `response.data` 替换为 [ApiEnvelope]；
/// 失败时转成 [ApiException] 抛出。
class EnvelopeInterceptor extends Interceptor {
  const EnvelopeInterceptor({this.onAuthExpired});

  /// 登录失效回调（后端 code = -1）。
  final VoidCallback? onAuthExpired;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final Object? raw = response.data;
    if (raw is! Map) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: const ApiFormatException(),
        ),
        true,
      );
      return;
    }

    final ApiEnvelope envelope = ApiEnvelope.fromMap(raw);
    if (!envelope.isSuccess) {
      if (envelope.isAuthExpired) {
        onAuthExpired?.call();
      }
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: ApiException(envelope.code, envelope.echo),
        ),
        true,
      );
      return;
    }

    response.data = envelope;
    handler.next(response);
  }
}

/// 把 dio 异常映射为中文可读的业务异常。
class ErrorMappingInterceptor extends Interceptor {
  const ErrorMappingInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException ||
        err.error is NetworkException ||
        err.error is ApiFormatException) {
      handler.next(err);
      return;
    }

    final String message = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '网络连接超时，请稍后重试',
      DioExceptionType.connectionError => '无法连接服务器，请检查网络设置',
      DioExceptionType.badResponse => '服务异常(${err.response?.statusCode})',
      DioExceptionType.cancel => '请求已取消',
      _ => '网络异常，请稍后重试',
    };

    handler.next(err.copyWith(error: NetworkException(message)));
  }
}

/// dio 异常转业务异常。
extension DioExceptionX on DioException {
  /// 转换成可直接展示的异常。
  Exception toAppException() {
    final Object? inner = error;
    if (inner is Exception) {
      return inner;
    }
    return const NetworkException('网络异常，请稍后重试');
  }
}
