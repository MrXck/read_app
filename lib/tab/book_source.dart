import 'package:flutter/material.dart';
import 'package:read_app/widget/book_source/body.dart';
import 'package:read_app/widget/book_source/header.dart';

class BookSourceTab extends StatefulWidget {
  const BookSourceTab({super.key});

  @override
  State<BookSourceTab> createState() => _BookSourceTabState();
}

class _BookSourceTabState extends State<BookSourceTab> {
  BookSourceData bookSourceData = BookSourceData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
          child: Stack(
        children: [
          BookSourceHeader(
              updateList: () {
                bookSourceData.init();
              }),
          BookSourceBody(bookSourceData: bookSourceData)
        ],
      )),
    );
  }
}

class BookSourceData {
  late Function init;
}
