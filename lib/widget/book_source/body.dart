import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:read_app/spider/spider.dart';
import 'package:read_app/tab/book_source.dart';
import 'package:read_app/utils/db.dart';

class BookSourceBody extends StatefulWidget {
  final BookSourceData bookSourceData;

  const BookSourceBody({super.key, required this.bookSourceData});

  @override
  State<BookSourceBody> createState() => _BookSourceBodyState();
}

class _BookSourceBodyState extends State<BookSourceBody> {
  List<BookSource> bookSources = [];
  List<String> ids = [];

  Future<void> init() async {
    var res = await DatabaseHelper.db.getAllBookSource();
    setState(() {
      bookSources = res;
    });
  }

  @override
  void initState() {
    init();
    widget.bookSourceData.init = () {
      init();
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: 50,
        bottom: 0,
        left: 0,
        right: 0,
        child: SizedBox(
          height: double.infinity,
          child: ListView.builder(
              itemCount: bookSources.length,
              itemBuilder: (BuildContext context, int index) {
                var bookSource = bookSources[index];
                return ListTile(
                  leading: Checkbox(
                      value: ids.contains(bookSource.id),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        if (value) {
                          setState(() {
                            ids.add(bookSource.id);
                          });
                        } else {
                          setState(() {
                            ids.remove(bookSource.id);
                          });
                        }
                      }),
                  title: Text(bookSource.name),
                  trailing: Switch(
                      value: bookSource.enable == 1,
                      onChanged: (value) {
                        setState(() {
                          bookSource.enable = value ? 1 : 0;
                          DatabaseHelper.db.updateBookSourceById(bookSource);
                        });
                      }),
                  onTap: () {
                    Get.defaultDialog(
                        title: '提示',
                        textConfirm: '确认',
                        textCancel: '取消',
                        content: const Text('确认要删除吗？'),
                        onConfirm: () async {
                          await DatabaseHelper.db
                              .deleteBookSourceById(bookSource.id);
                          setState(() {
                            bookSources.removeAt(index);
                          });
                          Get.back();
                        });
                  },
                );
              }),
        ));
  }
}
