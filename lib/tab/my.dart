import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/loading_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final SettingController settingController = Get.find();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: ListView(
        children: [
          TextButton(
              onPressed: () async {
                final dir = await getApplicationDocumentsDirectory();
                try {
                  LoadingUtils.showLoading(tip: '导出中');
                  await FileUtils.compressSpecifiedDirectory(
                      join(dir.path, 'read'),
                      join(dir.path, 'read.zip'),
                      [
                        Constant.bookType,
                        Constant.directoryType,
                        Constant.comicType,
                        Constant.mediaType,
                        Constant.outSideType,
                        Constant.pdfType,
                      ],
                  );
                } catch (e) {
                  Get.snackbar('错误', e.toString());
                } finally {
                  LoadingUtils.hideLoading();
                }
              },
              child: const Text('导出')),
          TextButton(
              onPressed: () async {
                final dir = await getApplicationDocumentsDirectory();
                try {
                  LoadingUtils.showLoading(tip: '导出中');
                  await FileUtils.compressSpecifiedDirectory(
                      join(dir.path, 'read'),
                      join(dir.path, 'read_book.zip'),
                      [
                        Constant.bookType,
                        Constant.directoryType
                      ],
                  );
                } catch (e) {
                  Get.snackbar('错误', e.toString());
                } finally {
                  LoadingUtils.hideLoading();
                }
              },
              child: const Text('导出书籍')),
          TextButton(
              onPressed: () async {
                final dir = await getApplicationDocumentsDirectory();
                try {
                  LoadingUtils.showLoading(tip: '导出中');
                  await FileUtils.compressSpecifiedDirectory(
                      join(dir.path, 'read'),
                      join(dir.path, 'read_comic.zip'),
                      [
                        Constant.comicType,
                        Constant.directoryType
                      ],
                  );
                } catch (e) {
                  Get.snackbar('错误', e.toString());
                } finally {
                  LoadingUtils.hideLoading();
                }
              },
              child: const Text('导出图片')),
          TextButton(
              onPressed: () async {
                final zipPath = await FileUtils.selectZipFile();
                if (zipPath.isEmpty) {
                  return;
                }

                try {
                  var tipText = LoadingUtils.showLoading(tip: '导入中');
                  final dir = await getApplicationDocumentsDirectory();
                  final fromPath = join(dir.path, 'read_import');
                  await FileUtils.unzipFile(zipPath, fromPath);

                  await FileUtils.copyDirectory(
                      fromPath, join(dir.path, 'read'), tipText);

                  FileUtils.deleteDirectoryRecursively(Directory(fromPath));
                } catch (e) {
                  Get.snackbar('错误', e.toString());
                } finally {
                  LoadingUtils.hideLoading();
                }
              },
              child: const Text('导入')),
          Obx(() {
            return TextButton(
                onPressed: () async {
                  settingController.isOpenHidden.value =
                      !settingController.isOpenHidden.value;
                },
                child: settingController.isOpenHidden.value
                    ? const Text('关闭隐藏')
                    : const Text('开启隐藏'));
          }),
          Obx(() {
            return TextButton(
                onPressed: () async {
                  var value = await SharedPreferences.getInstance();
                  var token = value.getString(Constant.tokenKey) ?? '';
                  if (token.isEmpty) {
                    Get.offNamed('/login');
                    return;
                  }

                  settingController.updateSync();
                },
                child: settingController.isOpenSync.value
                    ? const Text('关闭同步')
                    : const Text('开启同步'));
          }),
          Obx(() {
            return TextButton(
                onPressed: () async {
                  settingController.isOpenVolumeFlip.value =
                      !settingController.isOpenVolumeFlip.value;
                },
                child: settingController.isOpenVolumeFlip.value
                    ? const Text('关闭音量翻页')
                    : const Text('开启音量翻页'));
          }),
          TextButton(
              onPressed: () async {
                var value = await SharedPreferences.getInstance();
                value.setString(Constant.tokenKey, '');
                value.setBool(Constant.syncConfigKey, false);
                settingController.isOpenSync.value = false;
              },
              child: const Text('退出登录')),
          TextButton(
              onPressed: () {
                Get.toNamed('/settings');
              },
              child: const Text('更多设置')),
        ],
      )),
    );
  }
}
