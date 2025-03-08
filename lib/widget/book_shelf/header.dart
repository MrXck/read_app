import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:read_app/tab/book_shelf.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/loading_utils.dart';
import 'package:read_app/utils/permission_utils.dart';
import 'package:read_app/utils/platform_utils.dart';

class BookShelfHeader extends StatelessWidget {
  final Data data;

  const BookShelfHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '书架',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Row(
            children: [
              IconButton(
                  onPressed: () {
                    Get.toNamed('/search');
                  },
                  icon: const Icon(Icons.search)),
              IconButton(
                  onPressed: () {
                    showMenu(
                        context: context,
                        position: const RelativeRect.fromLTRB(420, 60, 0, 0),
                        items: <PopupMenuEntry<String>>[
                          PopupMenuItem(
                            child: const Text('新增分组'),
                            onTap: () async {
                              data.addDirectory();
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('导入书籍'),
                            onTap: () async {
                              var status = await PermissionUtils.getFilePermission();
                              if (status.isGranted) {
                                try {
                                  LoadingUtils.showLoading();
                                  await FileUtils.selectAndImportFile(
                                      data.parentId);
                                } catch (e) {
                                  Get.snackbar('错误', e.toString());
                                } finally {
                                  LoadingUtils.hideLoading();
                                  data.refresh();
                                }
                              } else {
                                Get.snackbar('提示', '没有权限');
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('导入选中文件夹下的书籍'),
                            onTap: () async {
                              var status = await PermissionUtils.getFilePermission();
                              if (status.isGranted) {
                                LoadingUtils.showLoading();
                                var directoryPath =
                                    await FileUtils.selectDirectory();
                                if (directoryPath.isNotEmpty) {
                                  try {
                                    await FileUtils.saveBookByDirectory(
                                        directoryPath, data.parentId);
                                  } catch (e) {
                                    Get.snackbar('错误', e.toString());
                                  } finally {
                                    LoadingUtils.hideLoading();
                                    data.refresh();
                                  }
                                } else {
                                  Get.snackbar('提示', '没有权限');
                                }
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('导入图片'),
                            onTap: () async {
                              var status = await PermissionUtils.getFilePermission();
                              if (status.isGranted) {
                                LoadingUtils.showLoading();
                                try {
                                  await FileUtils.selectAndImportDirectory(
                                      data.parentId);
                                } catch (e) {
                                  Get.snackbar('错误', e.toString());
                                } finally {
                                  LoadingUtils.hideLoading();
                                  data.refresh();
                                }
                              } else {
                                Get.snackbar('提示', '没有权限');
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('导入选中文件夹下的文件夹(图片)'),
                            onTap: () async {
                              var status = await PermissionUtils.getFilePermission();
                              if (status.isGranted) {
                                LoadingUtils.showLoading();
                                var directoryPath =
                                    await FileUtils.selectDirectory();
                                if (directoryPath.isNotEmpty) {
                                  try {
                                    await FileUtils.saveComicByDirectory(
                                        directoryPath, data.parentId);
                                  } catch (e) {
                                    Get.snackbar('错误', e.toString());
                                  } finally {
                                    LoadingUtils.showLoading();
                                    data.refresh();
                                  }
                                } else {
                                  Get.snackbar('提示', '没有权限');
                                }
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('导入音视频'),
                            onTap: () async {
                              var status = await PermissionUtils.getFilePermission();
                              if (status.isGranted) {
                                LoadingUtils.showLoading();
                                try {
                                  await FileUtils.selectAndImportMedia(
                                      data.parentId);
                                } catch (e) {
                                  Get.snackbar('错误', e.toString());
                                } finally {
                                  LoadingUtils.hideLoading();
                                  data.refresh();
                                }
                              } else {
                                Get.snackbar('提示', '没有权限');
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('导入pdf'),
                            onTap: () async {
                              var status = await PermissionUtils.getFilePermission();
                              if (status.isGranted) {
                                LoadingUtils.showLoading();
                                try {
                                  await FileUtils.selectAndImportPdf(
                                      data.parentId);
                                } catch (e) {
                                  Get.snackbar('错误', e.toString());
                                } finally {
                                  LoadingUtils.hideLoading();
                                  data.refresh();
                                }
                              } else {
                                Get.snackbar('提示', '没有权限');
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('局域网传书'),
                            onTap: () async {
                              await Get.toNamed("/uploadFile");
                              data.refresh();
                            },
                          ),
                        ]);
                  },
                  icon: const Icon(Icons.add))
            ],
          ),
        ],
      ),
    );
  }
}
