import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android APK 安装能力。
///
/// APK 下载到应用私有目录后，必须交给系统安装器完成安装：Android 7+ 要求
/// 通过 FileProvider 以 content:// 形式临时授权，Dart 层无法直接完成，
/// 因此这里用 MethodChannel 调用 MainActivity 中的原生实现。
class AppInstaller {
  const AppInstaller._();

  /// 与 MainActivity.kt 中注册的通道名保持一致。
  static const String channelName =
      'com.flamecloud.inc.flutter_flamecloud/app_update';

  static const MethodChannel _channel = MethodChannel(channelName);

  /// 当前平台是否支持 APP 内直接安装（仅 Android，iOS 不支持侧载）。
  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// 是否已获得「安装未知应用」授权。
  ///
  /// Android 8 以下没有该运行时授权，一律视为已允许；原生实现缺失时返回 false，
  /// 由上层退回浏览器下载。
  static Future<bool> canRequestInstallPackages() async {
    if (!supported) {
      return false;
    }
    return await _invoke<bool>('canRequestInstallPackages') ?? false;
  }

  /// 打开「允许来自此来源的应用」系统设置页。
  ///
  /// 返回是否成功拉起设置页；Android 8 以下无需设置，直接返回 true。
  static Future<bool> openInstallPermissionSettings() async {
    if (!supported) {
      return false;
    }
    return await _invoke<bool>('openInstallPermissionSettings') ?? false;
  }

  /// 拉起系统安装器安装指定路径的 APK。
  static Future<bool> installApk(String path) async {
    if (!supported || path.isEmpty) {
      return false;
    }
    return await _invoke<bool>('installApk', <String, Object?>{'path': path}) ??
        false;
  }

  /// 调用原生方法，通道未实现或报错时返回 null（不抛给上层）。
  static Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
