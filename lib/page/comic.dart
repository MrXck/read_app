import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/volume_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComicPage extends StatefulWidget {
  const ComicPage({super.key});

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> {
  late Book book;
  late PageController _pageController;
  late List<File> imageList = [];
  bool showOption = false;
  final ValueNotifier<int> _currentIndex = ValueNotifier<int>(0);
  final _bookTitleController = TextEditingController();
  final VolumeUtils volumeUtils = VolumeUtils();
  final SettingController settingController = Get.find();
  Settings settings = Settings();

  double pageTopPadding = 0;
  double pageBottomPadding = 30;
  double pageLeftPadding = 10;
  double pageRightPadding = 10;

  Future<void> init(Book book) async {
    if (settingController.isOpenVolumeFlip.value) {
      volumeUtils.init((double beforeVolume, double nowVolume) {
        if (beforeVolume < nowVolume) {
          _pageController.nextPage(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut);
        } else if (beforeVolume > nowVolume) {
          _pageController.previousPage(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeIn);
        }
        volumeUtils.setVolume(0.1);
      });
    }

    book = await DatabaseHelper.db.getById(book.id);
    var dataDir = await getApplicationDocumentsDirectory();
    book.assetDir = dataDir.path;
    var path = join(book.assetDir, book.path);
    _bookTitleController.text = book.title;
    _currentIndex.value = book.page + 1;

    var dir = Directory(path);
    if (dir.existsSync()) {
      var files = dir.listSync();
      setState(() {
        imageList = initPage(files);
      });
      _pageController.jumpToPage(book.page);
    }

    var value = await SharedPreferences.getInstance();
    var config = const JsonDecoder()
        .convert(value.getString(Constant.readConfigKey) ?? '{}');
    settings = Settings.fromMap(config);
  }

  @override
  void initState() {
    book = Get.arguments as Book;

    _pageController = PageController();

    init(book);

    super.initState();
  }

  List<File> initPage(List<FileSystemEntity> files) {
    List<File> imageList = [];

    for (var file in files) {
      if (file is File) {
        imageList.add(file);
      }
    }

    return imageList;
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: null,
        body: SafeArea(
          child: Stack(children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  showOption = !showOption;
                });
              },
              child: PhotoViewGallery.builder(
                scrollDirection:
                    settings.isVer ? Axis.vertical : Axis.horizontal,
                itemCount: imageList.length,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: FileImage(imageList[index]),
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black,
                ),
                pageController: _pageController,
                onPageChanged: (index) {
                  book.page =
                      _currentIndex.value - 1 < 0 ? 0 : _currentIndex.value - 1;
                  book.percent = (_currentIndex.value - 1 < 0
                          ? 0
                          : _currentIndex.value - 1) /
                      (imageList.length - 1) *
                      100;
                  DatabaseHelper.db.updateById(book);
                  _currentIndex.value = index + 1;
                },
              ),
            ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: ValueListenableBuilder(
                    valueListenable: _currentIndex,
                    builder: (context, value, child) {
                      return Text(
                        '$value / ${imageList.length}',
                        style: const TextStyle(color: Colors.white),
                      );
                    }),
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
                  height: 100,
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: Column(children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              settings.isVer = !settings.isVer;
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Color(0xFFEAEAEA),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(40))),
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            child: settings.isVer
                                ? const Text('上下翻页')
                                : const Text('左右翻页'),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('书籍标题：'),
                        SizedBox(
                          width: width - 180,
                          child: TextField(
                            controller: _bookTitleController,
                            decoration: const InputDecoration(
                              hintText: "输入书籍标题名",
                              hintStyle: TextStyle(color: Colors.black26),
                              contentPadding: EdgeInsets.all(0),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        TextButton(
                            onPressed: () {
                              setState(() {
                                book.title = _bookTitleController.text;
                                showOption = false;
                              });
                            },
                            child: const Text('确定'))
                      ],
                    )
                  ]),
                ),
              ),
            ),
          ]),
        ));
  }

  @override
  void dispose() {
    book.page = _currentIndex.value - 1 < 0 ? 0 : _currentIndex.value - 1;
    book.percent =
        ((_currentIndex.value - 1 < 0 ? 0 : _currentIndex.value - 1) /
                    (imageList.length - 1) *
                    100)
                .isInfinite
            ? 0
            : (_currentIndex.value - 1 < 0 ? 0 : _currentIndex.value - 1) /
                (imageList.length - 1) *
                100;
    DatabaseHelper.db.updateById(book);
    SharedPreferences.getInstance().then((value) {
      value.setString(Constant.readConfigKey,
          const JsonEncoder().convert(settings.toMap()));
    });
    if (settingController.isOpenVolumeFlip.value) {
      volumeUtils.removeListener(needRestore: true);
    }
    _currentIndex.dispose();
    _pageController.dispose();
    _bookTitleController.dispose();
    super.dispose();
  }
}
