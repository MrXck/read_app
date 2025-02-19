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
        content: const Text("发现新版本，是否更新？"),
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
              break;
            default:
              break;
          }
        });
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
