import 'package:flutter/material.dart';
import 'package:read_app/widget/book_shelf/body.dart';
import 'package:read_app/widget/book_shelf/header.dart';

class BookShelfPage extends StatefulWidget {
  const BookShelfPage({super.key});

  @override
  State<BookShelfPage> createState() => _BookShelfPageState();
}

class _BookShelfPageState extends State<BookShelfPage> {
  final Data data = Data();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Stack(
        children: [BookShelfHeader(data: data), BookShelfBody(data: data)],
      )),
    );
  }
}

class Data {
  String parentId = '';
  late Function refresh;
  late Function addDirectory;
}
