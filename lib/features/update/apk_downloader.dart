import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// APK 下载器。
///
/// 把 release 附件直链下载到应用私有目录（Android 为 getExternalFilesDir，
/// 属于应用专属目录，无需申请存储权限），再由 [AppInstaller] 拉起安装。
class ApkDownloader {
  ApkDownloader() : _dio = _createDio();

  /// APK 存放子目录。
  ///
  /// 需要与 android/app/src/main/res/xml/file_paths.xml 中声明的
  /// FileProvider 路径保持一致，否则安装器拿不到授权。
  static const String subDirectory = 'update';

  final Dio _dio;

  /// Gitee 附件直链与后端接口不同源，沿用独立 dio 实例。
  static Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        // 单块数据间隔超时，下载大文件时不会整体超时
        receiveTimeout: const Duration(seconds: 60),
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
  }

  /// 下载 APK 并返回本地文件路径。
  ///
  /// [onProgress] 回调已接收字节数与总字节数，服务端未返回长度时 total 为 -1。
  Future<String> download(
    String url, {
    required String fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    final Directory directory = await _prepareDirectory();
    final String path =
        <String>[directory.path, fileName].join(Platform.pathSeparator);
    await _dio.download(url, path, onReceiveProgress: onProgress);
    return path;
  }

  /// 准备下载目录并清理历史安装包，避免多次更新后残留文件堆积。
  Future<Directory> _prepareDirectory() async {
    Directory? base;
    if (!kIsWeb && Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getTemporaryDirectory();
    final Directory directory = Directory(
      <String>[base.path, subDirectory].join(Platform.pathSeparator),
    );
    if (await directory.exists()) {
      final List<FileSystemEntity> entities =
          await directory.list().toList();
      for (final FileSystemEntity entity in entities) {
        if (entity is File) {
          await entity.delete();
        }
      }
    } else {
      await directory.create(recursive: true);
    }
    return directory;
  }

  void dispose() {
    _dio.close();
  }
}

/// APK 下载器实例。
final Provider<ApkDownloader> apkDownloaderProvider =
    Provider<ApkDownloader>((Ref ref) {
  final ApkDownloader downloader = ApkDownloader();
  ref.onDispose(downloader.dispose);
  return downloader;
});
