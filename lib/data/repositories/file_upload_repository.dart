import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/net/api_envelope.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/http_providers.dart';
import '../../core/utils/json_value.dart';
import '../../data/models/ticket_attachment_draft.dart';

/// 文件上传仓库。
///
/// 与 vue_flamecloud 的附件上传流程一致，采用三段式：
/// 1. `GET /v1/user/avatar/token` 换取预签名 `upload_url`；
/// 2. 把文件 POST 到 `upload_url`（表单字段 `file`），拿回 `hash`；
/// 3. `POST /v1/user/file/upload`（表单 `hash`）换回可访问的 `url`。
///
/// 第 1、3 步走全局 dio（带鉴权头 + 统一拆包），第 2 步直连外部
/// 上传服务，用独立 dio 不带拦截器、手动解析 `{ code, data, echo }`。
class FileUploadRepository {
  FileUploadRepository(this._dio) : _external = _createExternalDio;

  final Dio _dio;

  /// 直连外部上传服务的 dio（不带信封拦截器）。
  final Dio _external;

  /// 创建外部上传 dio，超时与全局保持一致。
  static Dio get _createExternalDio => Dio(
        BaseOptions(
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          sendTimeout: ApiConfig.sendTimeout,
          responseType: ResponseType.json,
        ),
      );

  /// 上传单个文件，返回可提交的附件草稿。
  Future<TicketAttachmentDraft> upload(String name, List<int> bytes) async {
    // 1. 换取预签名上传地址。
    final Response<dynamic> tokenResp =
        await _dio.get<dynamic>(ApiEndpoints.user.avatarUploadToken);
    final String uploadUrl =
        JsonValue.string(_unwrap(tokenResp).asMap?['upload_url']) ?? '';
    if (uploadUrl.isEmpty) {
      throw const ApiException(-1, '获取上传地址失败');
    }

    // 2. 直连上传服务，拿回 hash。
    final Response<dynamic> uploadResp = await _external.post<dynamic>(
      uploadUrl,
      data: FormData.fromMap(<String, Object?>{
        'file': MultipartFile.fromBytes(bytes, filename: name),
      }),
    );
    final Map<String, dynamic>? uploadBody = _asMap(uploadResp.data);
    if (uploadBody == null || JsonValue.integer(uploadBody['code']) != 0) {
      throw ApiException(
        JsonValue.integer(uploadBody?['code']) ?? -1,
        JsonValue.string(uploadBody?['echo']) ?? '文件上传失败',
      );
    }
    final Object? rawHash = uploadBody['data'];
    final String hash = rawHash is Map
        ? JsonValue.string(rawHash['hash']) ?? ''
        : (rawHash?.toString() ?? '');
    if (hash.isEmpty) {
      throw const ApiException(-1, '文件上传失败');
    }

    // 3. 用 hash 换取可访问 url。
    final Response<dynamic> resolveResp = await _dio.post<dynamic>(
      ApiEndpoints.user.fileUpload,
      data: <String, Object?>{'hash': hash},
    );
    final String url =
        JsonValue.string(_unwrap(resolveResp).asMap?['url']) ?? '';
    if (url.isEmpty) {
      throw const ApiException(-1, '获取文件地址失败');
    }

    return TicketAttachmentDraft(name: name, url: url, hash: hash);
  }

  /// 拆包全局 dio 的统一响应；非 Map 视作格式错误。
  static ApiEnvelope _unwrap(Response<dynamic> response) {
    final Object? data = response.data;
    if (data is ApiEnvelope) {
      return data;
    }
    if (data is Map) {
      return ApiEnvelope.fromMap(data);
    }
    throw const ApiFormatException();
  }

  /// 把动态响应体转成 Map，类型不符返回 null。
  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}

/// 文件上传仓库实例。
final Provider<FileUploadRepository> fileUploadRepositoryProvider =
    Provider<FileUploadRepository>((Ref ref) {
  return FileUploadRepository(ref.watch(dioProvider));
});
