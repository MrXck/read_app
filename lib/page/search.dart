import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/file_utils.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _textEditingController = TextEditingController();
  List<Book> _books = [];
  ValueNotifier<bool> isSearchContent = ValueNotifier(false);
  final StreamController<List<Book>> _searchController = StreamController();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: null,
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Get.back();
            },
            child: const Icon(Icons.arrow_back_ios_new)),
        body: SafeArea(
            child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Column(children: [
            SizedBox(
              height: 72,
              width: double.infinity,
              child: Row(
                children: [
                  Container(
                    width: size.width - 60,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius:
                        const BorderRadius.all(Radius.circular(10))),
                    margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "输入书名搜索",
                        hintStyle: TextStyle(color: Colors.black26),
                        contentPadding: EdgeInsets.all(0),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      controller: _textEditingController,
                      onChanged: (value) async {
                        var books = await DatabaseHelper.db.getByTitle(value);
                        var dataDir = await getApplicationDocumentsDirectory();
                        _searchController.sink.add([]);

                        if (isSearchContent.value) {
                          List<Book> bookList = [];

                          for (var book in books) {
                            if (book.type == Constant.bookType) {
                              var bookPath = join(dataDir.path, book.path);
                              RegExp regExp = RegExp(value);
                              var content = await FileUtils.loadFile(bookPath);
                              Iterable<Match> matches = regExp.allMatches(content);
                              if (matches.isNotEmpty) {
                                bookList.add(book);
                              }
                            } else {
                              bookList.add(book);
                            }

                            _searchController.sink.add(bookList);
                          }

                        } else {
                          _searchController.sink.add(books);
                        }
                      },
                    ),
                  ),
                  ValueListenableBuilder(
                      valueListenable: isSearchContent,
                      builder: (context, value, child) {
                        return Checkbox(
                            value: value,
                            onChanged: (value) {
                              isSearchContent.value = value!;
                            });
                      })
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height - 72,
              child: StreamBuilder(stream: _searchController.stream, builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final results = snapshot.data;
                return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: results!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        onTap: () {
                          var book = results[index];
                          if (book.type == Constant.bookType) {
                            Get.toNamed('/read', arguments: book);
                          } else if (book.type == Constant.comicType) {
                            Get.toNamed('/comic', arguments: book);
                          } else if (book.type == Constant.mediaType) {
                            Get.toNamed('/video', arguments: book);
                          } else if (book.type == Constant.outSideType) {
                            Get.toNamed('/read_outside',
                                arguments: {'book': book, 'outSideBook': null});
                          } else if (book.type == Constant.pdfType) {
                            Get.toNamed('/pdf', arguments: book);
                          }
                        },
                        title: Text(results[index].title),
                      );
                    });
              }),
            )
          ]),
        )));
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.close();
    _textEditingController.dispose();
  }
}
