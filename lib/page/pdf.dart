import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/operation_log.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/volume_utils.dart';
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

  final VolumeUtils volumeUtils = VolumeUtils();
  final SettingController settingController = Get.find();
  Settings settings = Settings();

  double pageTopPadding = 0;
  double pageBottomPadding = 30;
  double pageLeftPadding = 10;
  double pageRightPadding = 10;
  ValueNotifier<bool> showOption = ValueNotifier(false);
  Timer? _dataTimer;

  Future<void> updateBook() async {
    book.page = _pdfViewerController.pageNumber;
    book.percent =
    (_pdfViewerController.pageNumber / _pdfViewerController.pageCount * 100)
        .isInfinite
        ? 0
        : _pdfViewerController.pageNumber /
        _pdfViewerController.pageCount *
        100;
    DatabaseHelper.db.updateById(book);
  }

  @override
  void initState() {
    book = Get.arguments as Book;
    init(book);
    super.initState();
  }

  Future<void> init(Book book) async {
    if (settingController.isOpenVolumeFlip.value) {
      volumeUtils.init((double beforeVolume, double nowVolume) {
        if (beforeVolume < nowVolume) {
          _pdfViewerController.nextPage();
        } else if (beforeVolume > nowVolume) {
          _pdfViewerController.previousPage();
        }
        volumeUtils.setVolume(0.1);
      });
    }

    book = await DatabaseHelper.db.getById(book.id);
    var dataDir = await getApplicationDocumentsDirectory();
    book.assetDir = dataDir.path;

    var value = await SharedPreferences.getInstance();
    var config = const JsonDecoder()
        .convert(value.getString(Constant.readConfigKey) ?? '{}');
    settings = Settings.fromMap(config);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: null,
        body: FutureBuilder(
            future: init(book),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return const Text("未连接");
                case ConnectionState.waiting:
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                case ConnectionState.active:
                  return const Text("");
                case ConnectionState.done:
                  if (snapshot.hasError) {
                    return Text(
                      "请求失败 , 报错信息 : ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    );
                  } else {
                    return Stack(
                      children: [
                        SizedBox(
                          width: width,
                          height: height,
                          child: SfPdfViewer.file(
                            File(join(book.assetDir, book.path)),
                            controller: _pdfViewerController,
                            pageLayoutMode: PdfPageLayoutMode.continuous,
                            scrollDirection: settings.isVer
                                ? PdfScrollDirection.vertical
                                : PdfScrollDirection.horizontal,
                            onDocumentLoaded:
                                (PdfDocumentLoadedDetails details) {
                              _pdfViewerController.jumpToPage(book.page);
                              _dataTimer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
                                updateBook();
                              });
                            },
                            onTap: (PdfGestureDetails details) {
                              showOption.value = !showOption.value;
                            },
                          ),
                        ),

                        ValueListenableBuilder(
                            valueListenable: showOption,
                            builder: (context, value, child) {
                              if (!value) {
                                return const SizedBox.shrink();
                              }
                              return Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  decoration:
                                  const BoxDecoration(color: Colors.white),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              );
                            }),
                        ValueListenableBuilder(
                            valueListenable: showOption,
                            builder: (context, value, child) {
                              if (!value) {
                                return const SizedBox.shrink();
                              }
                              return Positioned(
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
                                            settings.isVer = !settings.isVer;
                                            SharedPreferences.getInstance().then((value) {
                                              value.setString(Constant.readConfigKey,
                                                  const JsonEncoder().convert(settings.toMap()));
                                            });
                                            setState(() {

                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                                color: Color(0xFFEAEAEA),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(40))),
                                            padding: const EdgeInsets.fromLTRB(
                                                10, 5, 10, 5),
                                            child: settings.isVer
                                                ? const Text('上下翻页')
                                                : const Text('左右翻页'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]),
                                ),
                              );
                            })
                      ],
                    );
                  }
              }
            }));
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    updateBook();
    OperationLog operationLog = OperationLog.setOperationLog(
        book, book.id, Constant.operationUpdateType);
    DatabaseHelper.db.insertOperationLog(operationLog);
    SharedPreferences.getInstance().then((value) {
      value.setString(Constant.readConfigKey,
          const JsonEncoder().convert(settings.toMap()));
    });
    if (settingController.isOpenVolumeFlip.value) {
      volumeUtils.removeListener(needRestore: true);
    }
    _pdfViewerController.dispose();
    super.dispose();
  }
}
