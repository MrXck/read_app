import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:read_app/global/data.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/widget/book_shelf/body.dart';
import 'package:read_app/widget/book_shelf/header.dart';

class BookShelfPage extends StatefulWidget {
  const BookShelfPage({super.key});

  @override
  State<BookShelfPage> createState() => _BookShelfPageState();
}

class _BookShelfPageState extends State<BookShelfPage> {

  @override
  void initState() {
    var args = Get.arguments;
    if (args != null && args is Book) {
      data.parentId = args.id;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
          child: Stack(
            children: [BookShelfHeader(), BookShelfBody()],
          )),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}


