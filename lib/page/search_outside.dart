import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:read_app/spider/spider.dart';
import 'package:read_app/utils/spider_utils.dart';

class SearchOutsidePage extends StatefulWidget {
  const SearchOutsidePage({super.key});

  @override
  State<SearchOutsidePage> createState() => _SearchOutsidePageState();
}

class _SearchOutsidePageState extends State<SearchOutsidePage> {
  final TextEditingController _textEditingController = TextEditingController();
  List<OutSideBook> _books = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "输入书名搜索书源",
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
                      var res = await SpiderUtils.spider(value);
                      setState(() {
                        _books = res;
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 72,
                  child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _books.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          onTap: () async {
                            var book = _books[index];
                            Get.toNamed('/read_outside',
                                arguments: {'book': null, 'outSideBook': book});
                          },
                          title: Text(_books[index].title),
                        );
                      }),
                )
              ]))),
    );
  }
}
