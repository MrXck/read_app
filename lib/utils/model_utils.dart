import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/request/request.dart';
import 'package:read_app/utils/download_speed_tracker.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/update_utils.dart' show UpdateUtils;

class ModelManager {

  // 获取模型在手机上的最终本地路径
  static Future<String> get modelLocalPath async {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = join(dir.path, 'read', 'model', 'kokoro-multi-lang-v1_1');
    return modelPath;
  }

  // 执行复制逻辑
  static Future<String> copyModelsIfNeeded() async {
    final String localPath = await modelLocalPath;
    final Directory modelDir = Directory(localPath);

    // 如果已经存在，就不重复复制了（也可以做版本检查）
    if (await modelDir.exists()) {
      print("模型已存在，无需复制");
      return await modelLocalPath;
    }

    var updateData = await UpdateUtils.getNewVersion();
    showDownloadDialog(updateData.modelUrl);

    return await modelLocalPath;
  }

  static Future<void> showDownloadDialog(String modelUrl) async {
    DownloadSpeedTracker downloadSpeedTracker = DownloadSpeedTracker();
    ValueNotifier<String> progress = ValueNotifier<String>('0%|0|0|0');

    Get.defaultDialog(
        title: "提示",
        content: const Column(
          children: [
            Text("开启有声需要下载模型,是否下载？"),
          ],
        ),
        textConfirm: "下载",
        textCancel: "取消",
        onConfirm: () async {
          Get.back();

          Get.dialog(Dialog(
              child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: ValueListenableBuilder(
                      valueListenable: progress,
                      builder: (BuildContext context, value, Widget? child) {
                        var list = value.split('|');
                        return SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: Column(
                            children: [
                              Text('${list[2]} / ${list[1]}'),
                              Text('下载速度：${list[3]}'),
                              Text('下载进度：${list[0]}'),
                            ],
                          ),
                        );
                      }))));

          await downloadModelZip(modelUrl, (int count, int total) {
            final speed = downloadSpeedTracker.formatBytes(downloadSpeedTracker.onProgress(count).toInt());
            var percent = '${(count / total * 10000).ceil() / 100}%';
            var size = downloadSpeedTracker.formatBytes(total);
            var downloadSize = downloadSpeedTracker.formatBytes(count);

            progress.value = '$percent|$size|$downloadSize|$speed';
          });
          Get.back();
        });
  }

  static Future<void> downloadModelZip(String modelUrl, Function progressCallback) async {
    var dir = await getTemporaryDirectory();
    var savePath = join(dir.path, 'read', 'app', 'model.zip');

    await Request.getInstance().dio.download(modelUrl, savePath,
        onReceiveProgress: (int count, int total) {
          progressCallback(count, total);
        });

    var documentDir = await getApplicationDocumentsDirectory();
    var unzipPath = join(documentDir.path, 'read', 'model', 'kokoro-multi-lang-v1_1');
    await FileUtils.unzipFile(savePath, unzipPath);
  }
}
