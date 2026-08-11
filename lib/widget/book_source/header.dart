import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:read_app/spider/spider.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/file_utils.dart';

class BookSourceHeader extends StatelessWidget {
  final Function updateList;

  const BookSourceHeader({super.key, required this.updateList});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 50,
        child: Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '书源',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Row(
            children: [
              IconButton(
                  onPressed: () {
                    Get.toNamed('/search_outside');
                  },
                  style: IconButton.styleFrom(overlayColor: Colors.transparent),
                  icon: const Icon(Icons.search)),
              IconButton(
                  style: IconButton.styleFrom(overlayColor: Colors.transparent),
                  onPressed: () {
                    showMenu(
                        context: context,
                        position: const RelativeRect.fromLTRB(420, 60, 0, 0),
                        items: <PopupMenuEntry<String>>[
                          PopupMenuItem(
                            child: const Text('新增书源'),
                            onTap: () async {
                              await updateList();
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('导入书源'),
                            onTap: () async {
                              var status = await Permission
                                  .manageExternalStorage
                                  .request();
                              if (status.isGranted) {
                                var data = await FileUtils.selectJsonFile();
                                var json = const JsonDecoder().convert(data);

                                if (json is Map) {
                                  await DatabaseHelper.db.insertBookSource(
                                      BookSource.fromJson(json));
                                } else if (json is List) {
                                  for (var item in json) {
                                    await DatabaseHelper.db.insertBookSource(
                                        BookSource.fromJson(item));
                                  }
                                }

                                await updateList();
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: const Text('导出书源'),
                            onTap: () async {
                              List<BookSource> bookSources =
                              await DatabaseHelper.db.getAllBookSource();
                              List<Map> bookSourceMaps = bookSources
                                  .map((e) => e.toExportMap())
                                  .toList();
                              FileUtils.saveJsonFile('书源.json',
                                  const JsonEncoder().convert(bookSourceMaps));
                            },
                          ),
                        ]);
                  },
                  icon: const Icon(Icons.add))
            ],
          ),
        ],
      ),
    )
    );
  }
}
