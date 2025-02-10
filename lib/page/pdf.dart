import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/volumn_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPage extends StatefulWidget {
  const PdfPage({super.key});

  @override
  State<PdfPage> createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> {
  late Book book;

  final PdfViewerController _pdfViewerController = PdfViewerController();

  bool showOption = false;

  bool isVer = false;
  final VolumeUtils volumeUtils = VolumeUtils();

  String fontFamily = 'pingfang';
  int fontColor = 0xff000000;
  double pageTopPadding = 0;
  double pageBottomPadding = 30;
  double pageLeftPadding = 10;
  double pageRightPadding = 10;

  int needDecreaseWidth = 0;
  int needDecreaseHeight = 0;
  double needIncreaseLineHeight = 0.3;
  double needMultiFontSize = 1.1;
  double chapterTitleMultiFontSize = 1.4;
  double chapterTitleNotChinaStrDivisionCoefficient = 1.4;
  double chapterContentNotChinaStrDivisionCoefficient = 1.4;
  double chapterContentEnglishUpperStrDivisionCoefficient = 1.4;
  double chapterContentEnglishLowerStrDivisionCoefficient = 1.4;
  double chapterContentEmptyStrDivisionCoefficient = 1.3;
  double chapterContentNumStrDivisionCoefficient = 1.4;
  double chapterTitleStrDivisionCoefficient = 1.5;
  int titleFontWeight = 7;
  int contentFontWeight = 4;
  int backgroundColor = 0xFFF8F7F3;
  double fontSize = 16;
  double lineHeight = 1.6;

  @override
  void initState() {
    book = Get.arguments as Book;
    init(book);
    super.initState();
  }

  Future<void> init(Book book) async {
    volumeUtils.init((double beforeVolume, double nowVolume) {
      if (beforeVolume < nowVolume) {
        _pdfViewerController.nextPage();
      } else if (beforeVolume > nowVolume) {
        _pdfViewerController.previousPage();
      }
      volumeUtils.setVolume(0.1);
    });
    book = await DatabaseHelper.db.getById(book.id);
    var dataDir = await getApplicationDocumentsDirectory();
    book.assetDir = dataDir.path;

    var value = await SharedPreferences.getInstance();
    var config = const JsonDecoder().convert(value.getString('config') ?? '{}');
    backgroundColor = config['backgroundColor'] ?? 0xFFE6DBC5;
    isVer = config['isVer'] ?? false;
    fontSize = config['fontSize'] ?? 16;
    lineHeight = config['lineHeight'] ?? 1.6;
    needDecreaseWidth = config['needDecreaseWidth'] ?? 0;
    needDecreaseHeight = config['needDecreaseHeight'] ?? 0;
    needIncreaseLineHeight = config['needIncreaseLineHeight'] ?? 0.3;
    needMultiFontSize = config['needMultiFontSize'] ?? 1.14;
    chapterTitleMultiFontSize = config['chapterTitleMultiFontSize'] ?? 1.4;
    chapterTitleNotChinaStrDivisionCoefficient =
        config['chapterTitleNotChinaStrDivisionCoefficient'] ?? 1.4;
    chapterContentNotChinaStrDivisionCoefficient =
        config['chapterContentNotChinaStrDivisionCoefficient'] ?? 1.4;
    chapterContentEnglishUpperStrDivisionCoefficient =
        config['chapterContentEnglishUpperStrDivisionCoefficient'] ?? 1.4;
    chapterContentEnglishLowerStrDivisionCoefficient =
        config['chapterContentEnglishLowerStrDivisionCoefficient'] ?? 1.4;
    chapterContentEmptyStrDivisionCoefficient =
        config['chapterContentEmptyStrDivisionCoefficient'] ?? 1.3;
    chapterContentNumStrDivisionCoefficient =
        config['chapterContentNumStrDivisionCoefficient'] ?? 1.4;
    chapterTitleStrDivisionCoefficient =
        config['chapterTitleStrDivisionCoefficient'] ?? 1.5;
    fontFamily = config['fontFamily'] ?? 'pingfang';
    fontColor = config['fontColor'] ?? 0xff000000;
    titleFontWeight = config['titleFontWeight'] ?? 7;
    contentFontWeight = config['contentFontWeight'] ?? 4;
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: null,
      body: SafeArea(
          child: Stack(
        children: [
          SizedBox(
            width: width,
            height: height,
            child: SfPdfViewer.file(
              File(join(book.assetDir, book.path)),
              controller: _pdfViewerController,
              pageLayoutMode: PdfPageLayoutMode.single,
              scrollDirection: isVer
                  ? PdfScrollDirection.vertical
                  : PdfScrollDirection.horizontal,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                _pdfViewerController.jumpToPage(book.page);
              },
              onPageChanged: (PdfPageChangedDetails details) {
                book.page = _pdfViewerController.pageNumber;
                book.percent = _pdfViewerController.pageNumber /
                    _pdfViewerController.pageCount *
                    100;
                DatabaseHelper.db.updateById(book);
              },
              onTap: (PdfGestureDetails details) {
                setState(() {
                  showOption = !showOption;
                });
              },

            ),
          ),
          Visibility(
            visible: showOption,
            child: Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                decoration: const BoxDecoration(color: Colors.white),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.arrow_back_ios),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: showOption,
            child: Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 42,
                color: Colors.white,
                padding: const EdgeInsets.all(6),
                child: Column(children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            isVer = !isVer;
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40))),
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child:
                              isVer ? const Text('上下翻页') : const Text('左右翻页'),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          )
        ],
      )),
    );
  }

  @override
  void dispose() {
    book.page = _pdfViewerController.pageNumber;
    book.percent =
        _pdfViewerController.pageNumber / _pdfViewerController.pageCount * 100;
    DatabaseHelper.db.updateById(book);
    SharedPreferences.getInstance().then((value) {
      value.setString(
          'config',
          const JsonEncoder().convert({
            'backgroundColor': backgroundColor,
            'isVer': isVer,
            'fontSize': fontSize,
            'lineHeight': lineHeight,
            'needDecreaseWidth': needDecreaseWidth,
            'needDecreaseHeight': needDecreaseHeight,
            'needIncreaseLineHeight': needIncreaseLineHeight,
            'needMultiFontSize': needMultiFontSize,
            'chapterTitleMultiFontSize': chapterTitleMultiFontSize,
            'chapterTitleNotChinaStrDivisionCoefficient':
                chapterTitleNotChinaStrDivisionCoefficient,
            'chapterContentNotChinaStrDivisionCoefficient':
                chapterContentNotChinaStrDivisionCoefficient,
            'chapterContentEnglishUpperStrDivisionCoefficient':
                chapterContentEnglishUpperStrDivisionCoefficient,
            'chapterContentEnglishLowerStrDivisionCoefficient':
                chapterContentEnglishLowerStrDivisionCoefficient,
            'chapterContentEmptyStrDivisionCoefficient':
                chapterContentEmptyStrDivisionCoefficient,
            'chapterContentNumStrDivisionCoefficient':
                chapterContentNumStrDivisionCoefficient,
            'chapterTitleStrDivisionCoefficient':
                chapterTitleStrDivisionCoefficient,
            'fontFamily': fontFamily,
            'fontColor': fontColor,
            'titleFontWeight': titleFontWeight,
            'contentFontWeight': contentFontWeight,
          }));
    });
    volumeUtils.removeListener(needRestore: true);
    _pdfViewerController.dispose();
    super.dispose();
  }
}
