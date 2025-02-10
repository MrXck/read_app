import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/tab/file.dart';
import 'package:read_app/utils/db.dart';

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
    'read\\media'
  ];

  String path = '';
  ValueNotifier<String> rootPath = ValueNotifier('');

  @override
  void initState() {
    widget.data.delete = () {};
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

    await for (var entity in Directory(path).list(recursive: false)) {
      var filePojo = FilePoJo();
      if (entity is Directory) {
        filePojo.isFile = false;
      } else if (entity is File) {
        filePojo.isFile = true;
      }
      filePojo.path = entity.path.replaceAll('${rootPath.value}\\', '').replaceAll('${rootPath.value}/', '');
      paths.add(entity.path.replaceAll('${rootPath.value}\\', '').replaceAll('${rootPath.value}/', ''));
      filePojo.name = basename(entity.path);
      filePoJos.add(filePojo);
    }

    var value = await DatabaseHelper.db.getBooksByPath(paths);

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
            return ListTile(
                onTap: () {
                  if (files[index].isFile) {
                  } else {
                    // 进入文件夹
                    getFiles(join(rootPath.value, files[index].path));
                  }
                },
                title: Text(files[index].bookName),
                subtitle: Text(files[index].path),
                leading: Checkbox(
                    value: checkedIds.contains(files[index].id),
                    onChanged: (bool? checked) {
                      if (checked != null) {
                        if (checked) {
                          checkedIds.add(files[index].id);
                        } else {
                          checkedIds.remove(files[index].id);
                        }
                      }
                    }));
          }),
    );
  }
}

class FilePoJo {
  late String id;
  late String bookName;
  late String name;
  late bool isFile;
  late String path;
}
