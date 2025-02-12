import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:read_app/tab/file.dart';

class FileHeader extends StatelessWidget {
  final Data data;

  const FileHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.all(10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text(
          '文件',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Row(
          children: [
            IconButton(
                onPressed: () {
                  showMenu(
                      context: context,
                      position: const RelativeRect.fromLTRB(420, 60, 0, 0),
                      items: <PopupMenuEntry<String>>[
                        PopupMenuItem(
                          child: const Text('删除'),
                          onTap: () async {
                            Get.defaultDialog(
                                title: '提示',
                                textConfirm: '确认',
                                textCancel: '取消',
                                content: const Text('确认要删除吗？'),
                                onConfirm: () async {
                                  Get.back();
                                  data.delete();
                                });
                          },
                        ),
                      ]);
                },
                icon: const Icon(Icons.add))
          ],
        )
      ]),
    );
  }
}
