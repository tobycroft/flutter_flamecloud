package com.flamecloud.inc.flutter_flamecloud

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 宿主 Activity。
 *
 * 额外承载 APP 内自更新的 MethodChannel：Dart 侧负责下载 APK，下载完成后
 * 由这里通过 FileProvider 把文件临时授权给系统安装器并拉起安装界面。
 * Android 7+ 禁止把 file:// URI 暴露给其他应用，必须走 content://。
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    METHOD_CAN_INSTALL -> result.success(canRequestInstallPackages())

                    METHOD_OPEN_SETTINGS -> result.success(openInstallPermissionSettings())

                    METHOD_INSTALL_APK -> {
                        val path = call.argument<String>(ARG_PATH)
                        if (path.isNullOrEmpty()) {
                            result.success(false)
                        } else {
                            result.success(installApk(path))
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 是否已允许安装未知来源应用。
     *
     * Android 8（API 26）起该权限按来源逐个授权，之前版本是全局开关，
     * 这里对旧版本一律视为已允许。
     */
    private fun canRequestInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    /**
     * 打开本应用的「安装未知应用」设置页。
     */
    private fun openInstallPermissionSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return true
        }
        return try {
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName"),
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 拉起系统安装器安装 [path] 指向的 APK。
     *
     * 文件由 Dart 侧下载到应用私有目录（files/update 或 cache/update），
     * 已在 file_paths.xml 中登记，安装器才能通过 content:// 读取。
     */
    private fun installApk(path: String): Boolean {
        val file = File(path)
        if (!file.exists()) {
            return false
        }
        return try {
            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(this, "$packageName.fileProvider", file)
            } else {
                Uri.fromFile(file)
            }
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, APK_MIME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private companion object {
        const val CHANNEL = "com.flamecloud.inc.flutter_flamecloud/app_update"
        const val METHOD_CAN_INSTALL = "canRequestInstallPackages"
        const val METHOD_OPEN_SETTINGS = "openInstallPermissionSettings"
        const val METHOD_INSTALL_APK = "installApk"
        const val ARG_PATH = "path"
        const val APK_MIME = "application/vnd.android.package-archive"
    }
}