import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:read_app/utils/tts_service.dart';
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
    // data.tts = TtsService();
    // data.tts.initTTS();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, result) async {
          var canPop = await data.routeBack();
          if (canPop) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: SafeArea(
              child: Stack(
            children: [BookShelfHeader(data: data), BookShelfBody(data: data)],
          )),
        ));
  }

  @override
  void dispose() {
    // data.tts.dispose();
    super.dispose();
  }
}

class Data {
  String parentId = '';
  late Function refresh;
  late Function addDirectory;
  late Function routeBack;
  late Function updateSort;
  late TtsService tts;
}
