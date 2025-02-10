import 'package:flutter/material.dart';
import 'package:read_app/widget/file/body.dart';
import 'package:read_app/widget/file/header.dart';

class FileTab extends StatefulWidget {
  const FileTab({super.key});

  @override
  State<FileTab> createState() => _FileTabState();
}

class _FileTabState extends State<FileTab> {

  final Data data = Data();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
          child: Stack(
        children: [FileHeader(data: data), FileBody(data: data)],
      )),
    );
  }
}

class Data {
  late Function delete;
}
