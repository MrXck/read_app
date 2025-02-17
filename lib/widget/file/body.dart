import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/tab/file.dart';
import 'package:read_app/utils/book_utils.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/loading_utils.dart';
import 'package:read_app/utils/random.dart';

class FileBody extends StatefulWidget {
  final Data data;

  const FileBody({super.key, required this.data});

  @override
  State<FileBody> createState() => _FileBodyState();
}

class _FileBodyState extends State<FileBody> {
  final List<String> checkedIds = [];
  List<Book> books = [];
  List<FilePoJo> files = [];
  List<String> rootTypePath = [
    'read\\book',
    'read\\comic',
    'read\\data',
    'read\\pdf',
    'read\\media',
    'read\\font',
    'read/book',
    'read/comic',
    'read/data',
    'read/pdf',
    'read/media'
    'read/font'
  ];
  List<String> pathList = [];

  String path = '';
  ValueNotifier<String> rootPath = ValueNotifier('');

  @override
  void initState() {
    widget.data.delete = () async {
      LoadingUtils.showLoading(tip: '删除中');
      try {
        for (var path in pathList) {
          await FileUtils.deletePath(join(rootPath.value, path));
        }

        await BookUtils.deleteBooks(checkedIds);
        await getFiles(path);
      } catch (e) {
        Get.snackbar('错误', e.toString());
      } finally {
        LoadingUtils.hideLoading();
      }
    };
    init();
    super.initState();
  }

  Future<void> init() async {
    var dataDir = await getApplicationDocumentsDirectory();
    path = join(dataDir.path, 'read');
    rootPath.value = dataDir.path;

    getFiles(path);
  }

  Future<void> getFiles(String path) async {
    List<String> paths = [];

    List<FilePoJo> filePoJos = [];

    if (path != join(rootPath.value, 'read')) {
      var filePojo = FilePoJo();
      filePojo.isFile = false;
      filePojo.path = path;
      filePojo.name = '返回上一级';
      filePojo.id = '0';
      filePojo.bookName = '返回上一级';
      filePoJos.add(filePojo);
    }

    await for (var entity in Directory(path).list(recursive: false)) {
      var filePojo = FilePoJo();
      if (entity is Directory) {
        filePojo.isFile = false;
      } else if (entity is File) {
        filePojo.isFile = true;
      }
      filePojo.path = entity.path
          .replaceAll('${rootPath.value}\\', '')
          .replaceAll('${rootPath.value}/', '');
      paths.add(entity.path
          .replaceAll('${rootPath.value}\\', '')
          .replaceAll('${rootPath.value}/', ''));
      filePojo.name = basename(entity.path);
      filePoJos.add(filePojo);
    }
    List<Book> value = [];

    if (paths.isNotEmpty) {
      value = await DatabaseHelper.db.getBooksByPath(paths);
    }

    for (var file in filePoJos) {
      if (rootTypePath.contains(file.path)) {
        file.id = '0';
        file.bookName = file.path;
        continue;
      }

      for (var book in value) {
        if (book.path.contains(file.path)) {
          file.id = book.id;
          file.bookName = book.title;
          break;
        }
      }
    }

    setState(() {
      files = filePoJos;
      checkedIds.clear();
      pathList.clear();
      this.path = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Container(
      height: height - 50,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(0, 60, 0, 0),
      child: ListView.builder(
          itemCount: files.length,
          itemBuilder: (BuildContext context, int index) {
            var file = files[index];

            if (file.id == null) {
              file.bookName ??= '暂无id';
              file.id ??= generateRandomString(8);
              file.isFile = true;
            }

            return ListTile(
                onTap: () {
                  if (files[index].name == '返回上一级') {
                    getFiles(File(files[index].path).parent.path);
                  } else {
                    if (!files[index].isFile && files[index].id == '0') {
                      getFiles(join(rootPath.value, files[index].path));
                    }
                  }
                },
                title: file.bookName == '暂无id' ? Text(files[index].bookName!, style: const TextStyle(color: Colors.red),) : Text(files[index].bookName!),
                subtitle: Text(files[index].path),
                leading: rootTypePath.contains(files[index].path) || file.bookName == '返回上一级'
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                      )
                    : Checkbox(
                        value: checkedIds.contains(files[index].id) || pathList.contains(file.path),
                        onChanged: (bool? checked) {
                          if (checked != null) {
                            if (checked) {
                              if (file.bookName == '暂无id') {
                                setState(() {
                                  pathList.add(file.path);
                                });
                              } else {
                                setState(() {
                                  checkedIds.add(files[index].id!);
                                });
                              }

                            } else {
                              if (file.bookName == '暂无id') {
                                setState(() {
                                  pathList.remove(file.path);
                                });
                              } else {
                                setState(() {
                                  checkedIds.remove(files[index].id);
                                });
                              }
                            }
                          }
                        }));
          }),
    );
  }
}

class FilePoJo {
  String? id;
  String? bookName;
  late String name;
  late bool isFile;
  late String path;
  late Book book;
}
