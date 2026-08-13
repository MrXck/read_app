import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/loading_utils.dart';
import 'package:read_app/utils/model_utils.dart';
import 'package:share_plus/share_plus.dart';
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
            ListTile(
              onTap: () async {
                final dir = await getApplicationDocumentsDirectory();
                try {
                  var tip = LoadingUtils.showLoading(tip: '导出中');
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
                    onProgress: (progress) {
                      tip.value =
                          '导出中: ${(progress * 100).toStringAsFixed(2)}%';
                    },
                    onDone: (outputPath) async {
                      final file = File(outputPath);
                      if (await file.exists()) {
                        await Share.shareXFiles([
                          XFile(outputPath),
                        ], text: '导出.zip');
                        // 延迟清理
                        // Future.delayed(const Duration(seconds: 5), () {
                        //   if (File(outputPath).existsSync()) {
                        //     File(outputPath).deleteSync();
                        //   }
                        // });
                      }
                    },
                    onError: (String error) {},
                  );
                } catch (e) {
                  Get.snackbar('错误', e.toString());
                } finally {
                  LoadingUtils.hideLoading();
                }
              },
              title: const Text('导出'),
            ),
            ListTile(
              onTap: () async {
                final dir = await getApplicationDocumentsDirectory();
                try {
                  var tip = LoadingUtils.showLoading(tip: '导出中');
                  await FileUtils.compressSpecifiedDirectory(
                    join(dir.path, 'read'),
                    join(dir.path, 'read_book.zip'),
                    [Constant.bookType, Constant.directoryType],
                    onProgress: (progress) {
                      tip.value =
                          '导出中: ${(progress * 100).toStringAsFixed(2)}%';
                    },
                    onDone: (outputPath) async {
                      final file = File(outputPath);
                      if (await file.exists()) {
                        await Share.shareXFiles([
                          XFile(outputPath),
                        ], text: '导出.zip');
                        // 延迟清理
                        // Future.delayed(const Duration(seconds: 5), () {
                        //   if (File(outputPath).existsSync()) {
                        //     File(outputPath).deleteSync();
                        //   }
                        // });
                      }
                    },
                    onError: (String error) {},
                  );
                } catch (e) {
                  Get.snackbar('错误', e.toString());
                } finally {
                  LoadingUtils.hideLoading();
                }
              },
              title: const Text('导出书籍'),
            ),
            ListTile(
              onTap: () async {
                final dir = await getApplicationDocumentsDirectory();
                try {
                  var tip = LoadingUtils.showLoading(tip: '导出中');
                  await FileUtils.compressSpecifiedDirectory(
                    join(dir.path, 'read'),
                    join(dir.path, 'read_comic.zip'),
                    [Constant.comicType, Constant.directoryType],
                    onProgress: (progress) {
                      tip.value =
                          '导出中: ${(progress * 100).toStringAsFixed(2)}%';
                    },
                    onDone: (outputPath) async {
                      final file = File(outputPath);
                      if (await file.exists()) {
                        await Share.shareXFiles([
                          XFile(outputPath),
                        ], text: '导出.zip');
                        // 延迟清理
                        // Future.delayed(const Duration(seconds: 5), () {
                        //   if (File(outputPath).existsSync()) {
                        //     File(outputPath).deleteSync();
                        //   }
                        // });
                      }
                    },
                    onError: (String error) {},
                  );
                } catch (e) {
                  Get.snackbar('错误', e.toString());
                } finally {
                  LoadingUtils.hideLoading();
                }
              },
              title: const Text('导出图片'),
            ),
            ListTile(
              onTap: () async {
                final zipPath = await FileUtils.selectZipFile();
                if (zipPath.isEmpty) {
                  return;
                }

                try {
                  if (settingController.isSyncing.value) {
                    Get.snackbar('提示', '正在同步文件中 请稍后进行导入操作...');
                    return;
                  }

                  settingController.isSyncing.value = true;
                  var tipText = LoadingUtils.showLoading(tip: '导入中');
                  final dir = await getApplicationDocumentsDirectory();
                  final fromPath = join(dir.path, 'read_import');
                  await FileUtils.unzipFile(zipPath, fromPath);

                  await FileUtils.copyDirectory(
                    fromPath,
                    join(dir.path, 'read'),
                    tipText,
                  );

                  FileUtils.deleteDirectoryRecursively(Directory(fromPath));
                } catch (e) {
                  Get.snackbar('错误', e.toString());
                } finally {
                  settingController.isSyncing.value = false;
                  LoadingUtils.hideLoading();
                }
              },
              title: const Text('导入'),
            ),
            Obx(() {
              return ListTile(
                onTap: () async {
                  settingController.isOpenHidden.value =
                      !settingController.isOpenHidden.value;
                },
                title: settingController.isOpenHidden.value
                    ? const Text('关闭隐藏')
                    : const Text('开启隐藏'),
              );
            }),
            Obx(() {
              return ListTile(
                onTap: () async {
                  var value = await SharedPreferences.getInstance();
                  var token = value.getString(Constant.tokenKey) ?? '';
                  if (token.isEmpty) {
                    Get.offNamed('/login');
                    return;
                  }

                  settingController.updateSync();
                },
                title: settingController.isOpenSync.value
                    ? const Text('关闭同步')
                    : const Text('开启同步'),
              );
            }),
            Obx(() {
              return ListTile(
                onTap: () async {
                  settingController.isOpenVolumeFlip.value =
                      !settingController.isOpenVolumeFlip.value;
                },
                title: settingController.isOpenVolumeFlip.value
                    ? const Text('关闭音量翻页')
                    : const Text('开启音量翻页'),
              );
            }),
            Obx(() {
              return ListTile(
                onTap: () async {
                  TextEditingController controller = TextEditingController();
                  TextEditingController repeatController =
                      TextEditingController();
                  ValueNotifier<String> tips = ValueNotifier<String>('');
                  if (!settingController.isSecretMode.value) {
                    var value = await SharedPreferences.getInstance();
                    var secret = value.getString(Constant.secretKey) ?? '';
                    if (secret.isEmpty) {
                      await Get.dialog(
                        AlertDialog(
                          title: const Text('设置私密密码'),
                          content: SizedBox(
                            height: 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: controller,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: '请输入密码',
                                  ),
                                ),
                                TextField(
                                  controller: repeatController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: '请再次输入密码',
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: tips,
                                  builder:
                                      (
                                        BuildContext context,
                                        value,
                                        Widget? child,
                                      ) {
                                        return Text(
                                          value,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        );
                                      },
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                if (controller.text.isEmpty ||
                                    repeatController.text.isEmpty) {
                                  tips.value = '请输入密码';
                                  return;
                                }
                                if (controller.text != repeatController.text) {
                                  tips.value = "两次密码不一致";
                                  return;
                                }

                                value.setString(
                                  Constant.secretKey,
                                  controller.text,
                                );

                                Get.back(); // 关闭对话框
                              },
                              child: const Text('确定'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(), // 关闭对话框
                              child: const Text('取消'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      await Get.dialog(
                        AlertDialog(
                          title: const Text('输入私密密码'),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('请输入密码'),
                              TextField(
                                controller: controller,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  hintText: '请输入密码',
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: tips,
                                builder:
                                    (
                                      BuildContext context,
                                      value,
                                      Widget? child,
                                    ) {
                                      return Text(
                                        value,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      );
                                    },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                if (controller.text.isEmpty) {
                                  tips.value = "密码不能为空";
                                  return;
                                }
                                if (controller.text != secret) {
                                  tips.value = "密码错误";
                                  return;
                                }
                                settingController.isSecretMode.value = true;
                                Get.back(); // 关闭对话框
                              },
                              child: const Text('确定'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(), // 关闭对话框
                              child: const Text('取消'),
                            ),
                          ],
                        ),
                      );
                      tips.dispose();
                      controller.dispose();
                      repeatController.dispose();
                    }
                  } else {
                    settingController.isSecretMode.value =
                        !settingController.isSecretMode.value;
                  }
                },
                title: settingController.isSecretMode.value
                    ? const Text('退出私密模式')
                    : const Text('进入私密模式'),
              );
            }),
            Obx(() {
              if (!settingController.isSecretMode.value) {
                return const SizedBox.shrink();
              }

              return ListTile(
                onTap: () async {
                  TextEditingController controller = TextEditingController();
                  TextEditingController repeatController =
                      TextEditingController();
                  TextEditingController newController = TextEditingController();
                  ValueNotifier<String> tips = ValueNotifier<String>('');
                  var value = await SharedPreferences.getInstance();
                  var secret = value.getString(Constant.secretKey) ?? '';
                  await Get.dialog(
                    AlertDialog(
                      title: const Text('修改私密密码'),
                      content: SizedBox(
                        height: 164,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: controller,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: '请输入当前密码',
                              ),
                            ),
                            TextField(
                              controller: newController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: '请输入新密码',
                              ),
                            ),
                            TextField(
                              controller: repeatController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: '请再次输入新密码',
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: tips,
                              builder:
                                  (BuildContext context, value, Widget? child) {
                                    return Text(
                                      value,
                                      style: const TextStyle(color: Colors.red),
                                    );
                                  },
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            if (controller.text.isEmpty ||
                                newController.text.isEmpty ||
                                repeatController.text.isEmpty) {
                              tips.value = "密码不能为空";
                              return;
                            }
                            if (controller.text != secret) {
                              tips.value = "当前密码错误";
                              return;
                            }
                            if (newController.text != repeatController.text) {
                              tips.value = "新密码两次输入不一致";
                              return;
                            }
                            value.setString(
                              Constant.secretKey,
                              newController.text,
                            );
                            Get.back(); // 关闭对话框
                          },
                          child: const Text('确定'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(), // 关闭对话框
                          child: const Text('取消'),
                        ),
                      ],
                    ),
                  );
                  tips.dispose();
                  controller.dispose();
                  newController.dispose();
                  repeatController.dispose();
                },
                title: const Text('修改私密密码'),
              );
            }),
            ListTile(
              onTap: () async {
                var value = await SharedPreferences.getInstance();
                value.setString(Constant.tokenKey, '');
                value.setBool(Constant.syncConfigKey, false);
                settingController.isOpenSync.value = false;
              },
              title: const Text('退出登录'),
            ),
            ListTile(
              onTap: () {
                Get.toNamed('/sync');
              },
              title: const Text('同步相关'),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              onTap: () {
                Get.toNamed('/settings');
              },
              title: const Text('更多设置'),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              onTap: () {
                Get.toNamed('/model_settings');
              },
              title: const Text('有声设置'),
              trailing: const Icon(Icons.chevron_right),
            )
          ],
        ),
      ),
    );
  }
}
