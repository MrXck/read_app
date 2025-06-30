import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:read_app/pojo/update_data.dart';
import 'package:read_app/request/request.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/package_utils.dart';
import 'package:path_provider/path_provider.dart';

import 'file_utils.dart';

class UpdateUtils {
  static Future<void> updateApp() async {
    var updateData = await getNewVersion();

    var packageInfo = await PackageUtils.getPackageInfo();
    var nowVersion = packageInfo.version;
    var newVersion = updateData.version;

    if (nowVersion == newVersion) {
      return;
    }

    var storageStatus = await Permission.storage.request();

    if (!storageStatus.isGranted) {
      return;
    }

    var installStatus = await Permission.requestInstallPackages.request();

    if (!installStatus.isGranted) {
      return;
    }

    switch (Platform.operatingSystem) {
      case 'android':
        showUpdateDialog(updateData);
        break;
      case 'windows':
        showUpdateDialog(updateData);
        break;
      default:
        break;
    }

  }

  static Future<UpdateData> getNewVersion() async {
    var response =
        await Request.getInstance().dio.get(Constant.getAppVersionUrl);
    return UpdateData.fromMap(response.data);
  }

  static Future<void> showUpdateDialog(UpdateData updateData) async {
    ValueNotifier<String> progress = ValueNotifier<String>('0%');

    Get.defaultDialog(
        title: "提示",
        content: Column(
          children: [
            const Text("发现新版本，是否更新？"),
            ...updateData.versionDesc.map((toElement) {
              return Text(toElement);
            }),
          ],
        ),
        textConfirm: "更新",
        textCancel: "取消",
        onConfirm: () async {
          Get.back();

          Get.dialog(Dialog(
              child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: ValueListenableBuilder(
                      valueListenable: progress,
                      builder: (BuildContext context, value, Widget? child) {
                        return Text('下载进度：$value');
                      }))));

          switch (Platform.operatingSystem) {
            case 'android':
              downloadNewApk(updateData, (int count, int total) {
                progress.value = '${(count / total * 10000).ceil() / 100}%';
              });
              break;
            case 'windows':
              updateWindows(updateData, (int count, int total) {
                progress.value = '${(count / total * 10000).ceil() / 100}%';
              });
              break;
            default:
              break;
          }
        });
  }

  static Future<void> updateWindows(UpdateData updateData, Function progressCallback) async {
    final tempDir = await getTemporaryDirectory();
    final batFile = File(join(tempDir.path, 'updateReadApp.bat'));
    final zipPath = await downloadNewZip(updateData, progressCallback);
    var unzipPath = join(tempDir.path, 'read_app', 'update');
    await FileUtils.unzipFile(zipPath, unzipPath);
    String appDir = Directory(Platform.resolvedExecutable).parent.path;
    String backupDir = join(tempDir.path, 'readAppBack');
    String batContent = '''
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ====== Configuration ======
set "APPDIR=$appDir"
set "BACKUPDIR=$backupDir"
set "UNZIPDIR=$unzipPath"
set TIMEOUTSECONDS=30

REM ====== Initialize ======
echo Starting update process

REM ====== Terminate application ======
echo Stopping read_app.exe...
taskkill /f /im read_app.exe >nul 2>&1
timeout /t 2 >nul

REM ====== Create backup ======
if not exist "%BACKUPDIR%" mkdir "%BACKUPDIR%"
echo Creating backup at: %BACKUPDIR%
robocopy "%APPDIR%" "%BACKUPDIR%" /mir /mt:8 /r:1 /w:1 /nfl /ndl

if %errorlevel% gtr 3 (
  echo Backup failed! Errorlevel: %errorlevel%
  exit /b 1
)

REM ====== Launch new version ======
robocopy "%UNZIPDIR%" "%APPDIR%" /mir /mt:8 /r:2 /w:2 /nfl /ndl
echo Starting MyApp.exe
start "" "%APPDIR%\\read_app.exe"
exit /b 0

REM ====== Error recovery ======
:RESTORE_BACKUP
echo Restoring from backup...
robocopy "%BACKUPDIR%" "%APPDIR%" /mir /mt:8 /r:2 /w:2 /nfl /ndl
exit /b 1
''';
    await batFile.writeAsString(batContent);

    // 在独立进程中启动更新脚本
    await Process.start('start cmd', ['/c', batFile.path], runInShell: true);

    // 退出应用程序
    exit(0);
  }

  static Future<String> downloadNewZip(
      UpdateData updateData, Function progressCallback) async {
    var url = updateData.windowsUrl;

    var dir = await getTemporaryDirectory();
    var savePath = join(dir.path, 'read', 'app', 'update.zip');

    await Request.getInstance().dio.download(url, savePath,
        onReceiveProgress: (int count, int total) {
          progressCallback(count, total);
        });

    return savePath;
  }

  static Future<void> downloadNewApk(
      UpdateData updateData, Function progressCallback) async {
    var url = updateData.url;

    var dir = await getTemporaryDirectory();
    var savePath = join(dir.path, 'read', 'app', 'update.apk');

    await Request.getInstance().dio.download(url, savePath,
        onReceiveProgress: (int count, int total) {
      progressCallback(count, total);
    });

    OpenFilex.open(savePath);
  }
}
