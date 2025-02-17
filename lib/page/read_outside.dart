import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/chapter.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/spider/spider.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/regex_utils.dart';
import 'package:read_app/utils/spider_utils.dart';
import 'package:read_app/utils/volume_utils.dart';
import 'package:read_app/widget/read/chapter_list.dart';
import 'package:read_app/widget/read/font_setting.dart';
import 'package:read_app/widget/read/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadOutSidePage extends StatefulWidget {
  const ReadOutSidePage({super.key});

  @override
  State<ReadOutSidePage> createState() => _ReadOutSidePageState();
}

class _ReadOutSidePageState extends State<ReadOutSidePage> {
  String data = '';
  String chapterTitleExp = Constant.defaultChapterTitleExp;
  ValueNotifier<bool> showOption = ValueNotifier(false);
  ValueNotifier<bool> showSettings = ValueNotifier(false);
  ValueNotifier<bool> showChapter = ValueNotifier(false);
  ValueNotifier<bool> showFont = ValueNotifier(false);
  List<int> backgroundColorList = [
    0xFFF8F7F3,
    0xFFE6DBC5,
    0xFFE9E2DA,
    0xFFD3DFC7,
    0xFF555354
  ];

  ValueNotifier<int> currentSeqNo = ValueNotifier(0);
  late Book book;
  late OutSideBook outSideBook;
  late double height;
  late double width;
  List<OutSideChapter> chapterList = [];
  List<Widget> widgetList = [];
  final PageController _pageController = PageController();
  final SettingController settingController = Get.find();
  final VolumeUtils volumeUtils = VolumeUtils();
  final _now = ValueNotifier('');
  final _nowChapter = ValueNotifier('开始');
  final _currentPage = ValueNotifier(0);
  final _chapterTitleExpController = TextEditingController();
  final _bookTitleController = TextEditingController();
  Settings settings = Settings();
  int nowChapterPage = 0;
  bool isLoading = false;
  Map<String, int> chapterTitlePageNumMap = {};
  Map<int, OutSideChapter> chapterPageNumTitleMap = {};
  Map<String, String> alreadySpiderChapterMap = {};
  List<int> chapterPageNumList = [];
  int startHasContentPage = 500;

  double pageTopPadding = 0;
  double pageBottomPadding = 30;
  double pageLeftPadding = 10;
  double pageRightPadding = 10;

  Future<void> init(Book? book, OutSideBook? outSideBook1) async {
    String bookSourceId;
    String url;

    if (book == null) {
      nowChapterPage = 0;
      _bookTitleController.text = outSideBook1!.title;
      bookSourceId = outSideBook1.bookSourceId;
      url = outSideBook1.url;
      currentSeqNo.value = 0;
    } else {
      var split = book.path.split('|');
      bookSourceId = split[0];
      url = split[1];
      nowChapterPage = book.page;
      _bookTitleController.text = book.title;
      currentSeqNo.value = book.currentChapter;
    }

    if (outSideBook1 == null) {
      outSideBook = OutSideBook()..bookSourceId = bookSourceId;
    } else {}

    var res = await SpiderUtils.spiderChapterByBook(
        url, _bookTitleController.text, bookSourceId);
    chapterList = res;

    var time = DateTime.now();
    _now.value =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      var time = DateTime.now();
      _now.value =
          '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    });

    var value = await SharedPreferences.getInstance();
    var config = const JsonDecoder().convert(value.getString(Constant.readConfigKey) ?? '{}');
    settings = Settings.fromMap(config);

    _pageController.addListener(() {
      var beforePage = _currentPage.value;
      _currentPage.value = _pageController.page!.round() + 1;

      if (isLoading) {
        return;
      }

      if (beforePage > _currentPage.value) {
        if (beforePage - startHasContentPage < 4) {
          if (isLoading) {
            return;
          }
          switchChapter(currentSeqNo.value - 1, false);
        }
      }

      if (beforePage < _currentPage.value) {
        if (widgetList.length - _currentPage.value < 4) {
          if (isLoading) {
            return;
          }
          switchChapter(currentSeqNo.value + 1, true);
        }
      }
    });

    switchChapter1(currentSeqNo.value);
  }

  Future<String> loadChapterContent(OutSideChapter chapter) async {
    String data = '';

    if (alreadySpiderChapterMap[chapter.url] != null) {
      data = alreadySpiderChapterMap[chapter.url]!;
    } else {
      data = await SpiderUtils.spiderChapterContent(
          chapter.url, outSideBook.bookSourceId);
      alreadySpiderChapterMap[chapter.url] = data;
    }
    return data;
  }

  @override
  void initState() {
    super.initState();

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

    if (Get.arguments['outSideBook'] == null) {
      outSideBook = OutSideBook();
    } else {
      outSideBook = Get.arguments['outSideBook'] as OutSideBook;
    }

    if (Get.arguments['book'] != null) {
      book = Get.arguments['book'] as Book;

      if (Get.arguments['outSideBook'] == null) {
        init(book, null);
      } else {
        init(book, Get.arguments['outSideBook'] as OutSideBook);
      }
    } else {
      book = Book();
      book.id = '-1';

      if (Get.arguments['outSideBook'] == null) {
        init(null, null);
      } else {
        init(null, Get.arguments['outSideBook'] as OutSideBook);
      }
    }
  }

  void switchChapter1(int seqNo) async {
    isLoading = true;
    chapterTitlePageNumMap.clear();
    chapterPageNumTitleMap.clear();
    chapterPageNumList.clear();
    OutSideChapter? currentChapter;
    try {
      currentChapter = chapterList[seqNo];
    } catch (e) {
      isLoading = false;
      return;
    }

    currentSeqNo.value = seqNo;

    var currentChapterIndex = chapterList.indexOf(currentChapter);

    if (currentChapterIndex == -1) {
      currentChapterIndex = 0;
    }

    var start = currentChapterIndex - 2;
    var end = currentChapterIndex + 2;

    if (start < 0) {
      start = 0;
      end++;
    }

    if (end >= chapterList.length) {
      end = chapterList.length - 1;
    }

    var content = '';

    List<Widget> pageList =
        List.generate(startHasContentPage, (index) => const SizedBox.shrink());

    for (var i = start; i <= end; i++) {
      var chapter = chapterList[i];

      var chapterContent =
          '${chapter.title}\n\n${await loadChapterContent(chapter)}';

      var beforeAddLength = pageList.length;

      chapterTitlePageNumMap[chapter.title] = beforeAddLength;
      chapterPageNumList.add(beforeAddLength);
      chapterPageNumTitleMap[beforeAddLength] = chapter;

      pageList.addAll(calcPage(chapterContent, height, width, settings.fontSize,
          settings.lineHeight));

      if (seqNo == chapter.seqNo) {
        _nowChapter.value = chapter.title;
      }

      content += '\n$chapterContent';
    }

    setState(() {
      startHasContentPage = 500;
      data = content;
      widgetList = pageList;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var pageNum = chapterTitlePageNumMap[_nowChapter.value];
      pageNum ??= startHasContentPage;

      _pageController.jumpToPage(pageNum + nowChapterPage);
      _currentPage.value = pageNum + nowChapterPage;
      isLoading = false;
    });
  }

  void switchChapter(int seqNo, bool isAfter) async {
    isLoading = true;

    OutSideChapter currentChapter;
    try {
      currentChapter = chapterList[seqNo];
    } catch (e) {
      isLoading = false;
      return;
    }

    currentSeqNo.value = seqNo;

    var currentChapterIndex = chapterList.indexOf(currentChapter);

    if (currentChapterIndex == -1) {
      currentChapterIndex = 0;
    }

    var end = currentChapterIndex;

    if (end >= chapterList.length) {
      return;
    }

    var content = '';

    List<Widget> pageList = [];

    var chapter = chapterList[end];

    var chapterContent =
        '${chapter.title}\n\n${await loadChapterContent(chapter)}';

    var beforeAddLength = widgetList.length;

    pageList.addAll(calcPage(
        chapterContent, height, width, settings.fontSize, settings.lineHeight));

    setState(() {
      if (isAfter) {
        chapterTitlePageNumMap[chapter.title] = beforeAddLength;
        chapterPageNumList.add(beforeAddLength);
        chapterPageNumTitleMap[beforeAddLength] = chapter;
        widgetList.addAll(pageList);
        content = '$data\n$chapterContent';
      } else {
        content = '$chapterContent\n$data';
        chapterTitlePageNumMap[chapter.title] =
            startHasContentPage - pageList.length;
        chapterPageNumList.insert(0, startHasContentPage - pageList.length);
        chapterPageNumTitleMap[startHasContentPage - pageList.length] = chapter;
        for (int i = pageList.length - 1; i >= 0; i--) {
          widgetList[startHasContentPage - (pageList.length - i)] = pageList[i];
        }
      }
      data = content;
      startHasContentPage -= pageList.length;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading = false;
    });
  }

  Widget addPage(List<Map> textList, int totalPageNum, int everyLineFontNum) {
    List<Widget> widgetList = [];

    for (var i = 0; i < textList.length; i++) {
      var item = textList[i];
      String text = item['text'];
      var hasChapterTitle = item['hasChapterTitle'] as bool;

      if (hasChapterTitle) {
        widgetList.add(Text(
          text.trim(),
          maxLines: 3,
          textAlign: TextAlign.center,
          style: TextStyle(
              height: settings.lineHeight * settings.chapterTitleMultiFontSize,
              fontSize: settings.fontSize * settings.chapterTitleMultiFontSize,
              fontFamily: settings.fontFamily,
              color: Color(settings.fontColor),
              fontWeight: FontWeight.bold),
        ));
      } else {
        if (text.startsWith('      ')) {
          text = text.replaceFirst('       ', '      ');
          var textList1 = text.split('');

          if (textList1.length - 5 < everyLineFontNum) {
            widgetList.add(Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                height: settings.lineHeight,
                fontSize: settings.fontSize,
                fontFamily: settings.fontFamily,
                color: Color(settings.fontColor),
              ),
            ));
          } else {
            List<Widget> tt = [];
            for (var j = 0; j < textList1.length; j++) {
              var item = textList1[j];
              tt.add(Text(
                item,
                style: TextStyle(
                  height: settings.lineHeight,
                  fontSize: settings.fontSize,
                  fontFamily: settings.fontFamily,
                  color: Color(settings.fontColor),
                ),
              ));
            }

            widgetList.add(Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: tt,
            ));
          }
        } else {
          List<Widget> tt = [];
          var textList1 = text.trim().split('');

          if (textList1.length < everyLineFontNum) {
            widgetList.add(Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                height: settings.lineHeight,
                fontSize: settings.fontSize,
                fontFamily: settings.fontFamily,
                color: Color(settings.fontColor),
              ),
            ));
          } else {
            for (var j = 0; j < textList1.length; j++) {
              var item = textList1[j];
              tt.add(Text(
                item,
                style: TextStyle(
                  height: settings.lineHeight,
                  fontSize: settings.fontSize,
                  fontFamily: settings.fontFamily,
                  color: Color(settings.fontColor),
                ),
              ));
            }

            widgetList.add(Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: tt,
            ));
          }
        }
      }
    }

    return Container(
      width: 200,
      padding: EdgeInsets.fromLTRB(
          pageLeftPadding, pageTopPadding, pageRightPadding, pageBottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgetList,
      ),
    );
  }

  List<Widget> calcPage(String data, double height, double width,
      double fontSize, double lineHeight) {
    double everyLineHeight =
        (fontSize * (lineHeight + settings.needIncreaseLineHeight))
            .ceilToDouble();
    int lineNum =
        ((height - settings.needDecreaseHeight) / everyLineHeight).floor();

    int everyLineFontNum = ((width - settings.needDecreaseWidth) /
            (fontSize * settings.needMultiFontSize))
        .floor();

    data = data.replaceAll(RegExp(r'(?<!\n)\n(?!\n)'), '\n\n');
    List<String> textList = data.split('\n');

    int index = 0;

    List<Map> pageTextList = [];

    List<Widget> pageList = [];

    RegExp exp = RegExp(chapterTitleExp);

    while (index < textList.length) {
      var text = '       ${textList[index].trim()}';

      index++;

      var num = 0;
      var hasChapterTitle = exp.hasMatch(text);

      while (text.isNotEmpty) {
        int end;

        if (hasChapterTitle) {
          end = text.length;
        } else {
          end = num + everyLineFontNum > text.length
              ? text.length
              : num + everyLineFontNum;
        }

        var newText = text.substring(0, end);

        var notChinaStrNum = RegexUtils.matchNotChinaStr(newText);

        if (notChinaStrNum > 1) {
          end += (notChinaStrNum /
                  settings.chapterContentNotChinaStrDivisionCoefficient)
              .floor();

          end = end > text.length ? text.length : end;

          newText = text.substring(num, end);
        }

        var englishUpperStrNum = RegexUtils.matchEnglishUpperStr(newText);

        if (englishUpperStrNum > 1) {
          end += (englishUpperStrNum /
                  settings.chapterContentEnglishUpperStrDivisionCoefficient)
              .floor();

          end = end > text.length ? text.length : end;

          newText = text.substring(num, end);
        }

        var englishLowerStrNum = RegexUtils.matchEnglishLowerStr(newText);

        if (englishLowerStrNum > 1) {
          end += (englishLowerStrNum /
                  settings.chapterContentEnglishLowerStrDivisionCoefficient)
              .floor();

          end = end > text.length ? text.length : end;

          newText = text.substring(num, end);
        }

        var emptyStrNum = RegexUtils.matchEmptyStr(newText);

        if (emptyStrNum > 1) {
          end +=
              (emptyStrNum / settings.chapterContentEmptyStrDivisionCoefficient)
                  .floor();

          end = end > text.length ? text.length : end;

          newText = text.substring(num, end);
        }

        var numStrNum = RegexUtils.matchNumStr(newText);

        if (numStrNum > 1) {
          end += (numStrNum / settings.chapterContentNumStrDivisionCoefficient)
              .floor();

          end = end > text.length ? text.length : end;

          newText = text.substring(num, end);
        }

        pageTextList.add({'text': newText, 'hasChapterTitle': hasChapterTitle});

        text = text.substring(end);
      }
    }

    List<Map> xxx = [];
    int currentLine = 0;
    for (var n = 0; n < pageTextList.length; n++) {
      var item = pageTextList[n];
      var text = item['text'];

      var hasChapterTitle = item['hasChapterTitle'];
      if (hasChapterTitle && xxx.isNotEmpty) {
        pageList.add(addPage(xxx, pageList.length, everyLineFontNum));
        xxx = [];
        currentLine = 0;
      }

      if (currentLine >= lineNum) {
        pageList.add(addPage(xxx, pageList.length, everyLineFontNum));
        currentLine = 0;
        xxx = [];
      }
      if (hasChapterTitle) {
        while (text.isNotEmpty) {
          var addMap = {'text': text, 'hasChapterTitle': true};

          xxx.add(addMap);
          int num1 = (text.length /
                      everyLineFontNum *
                      settings.chapterTitleStrDivisionCoefficient *
                      settings.chapterTitleMultiFontSize)
                  .ceil() +
              1;
          currentLine += num1;
          text = '';
        }
      } else {
        var addMap = {'text': text, 'hasChapterTitle': hasChapterTitle};
        xxx.add(addMap);
        currentLine += 1;
      }
    }

    if (xxx.isNotEmpty) {
      pageList.add(addPage(xxx, pageList.length, everyLineFontNum));
    }

    return pageList;
  }

  int getChapterTitle(int pageNum) {
    int left = 0;
    int right = chapterPageNumList.length - 1;

    if (pageNum <= chapterPageNumList[0]) {
      return 0;
    }

    while (left <= right) {
      int mid = (left + right) ~/ 2;

      if (chapterPageNumList[mid] == pageNum) {
        return mid;
      }

      if (chapterPageNumList[mid] >= pageNum) {
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }

    return right;
  }

  @override
  Widget build(BuildContext context) {
    var conte = MediaQuery.of(context);
    height = conte.size.height - conte.padding.top - conte.padding.bottom;
    width = conte.size.width;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: null,
        body: SafeArea(
            child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(color: Color(settings.backgroundColor)),
          child: Stack(
            children: [
              Positioned(
                  left: 0,
                  top: 30,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      showOption.value = !(showOption.value);
                      showSettings.value = false;
                      showChapter.value = false;
                      showFont.value = false;
                    },
                    child: SizedBox(
                      height: height,
                      width: width,
                      child: Center(
                        child: Container(
                          width: width,
                          height: height,
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: PageView.builder(
                            controller: _pageController,
                            scrollDirection: settings.isVer
                                ? Axis.vertical
                                : Axis.horizontal,
                            pageSnapping: settings.isVer ? false : true,
                            itemCount: widgetList.length,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              return widgetList[index];
                            },
                            onPageChanged: (page) {
                              if (chapterPageNumTitleMap.isEmpty) {
                                return;
                              }

                              if (isLoading) {
                                return;
                              }

                              if (book.id != '-1') {
                                book.page = nowChapterPage;
                                book.percent = ((currentSeqNo.value + 1) /
                                        chapterList.length) *
                                    100;
                                book.chapterTitleExp = chapterTitleExp;
                                book.currentChapter = currentSeqNo.value;
                                DatabaseHelper.db.updateById(book);
                              }

                              if (page < chapterPageNumList[0]) {
                                _nowChapter.value = '开始';
                              } else {
                                var chapterPage =
                                    chapterPageNumList[getChapterTitle(page)];
                                nowChapterPage = page - chapterPage;

                                var chapter =
                                    chapterPageNumTitleMap[chapterPage]!;
                                currentSeqNo.value = chapter.seqNo;
                                var title = chapter.title;
                                if (_nowChapter.value != title) {
                                  _nowChapter.value = title;
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  )),
              Positioned(
                  top: 0,
                  left: 10,
                  right: 0,
                  height: 30,
                  child: Row(
                    children: [
                      ValueListenableBuilder(
                          valueListenable: _nowChapter,
                          builder: (context, value, child) {
                            return SizedBox(
                              width: width - 10,
                              child: Text(
                                value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: settings.fontFamily,
                                    color: const Color(0xCFCACACA)),
                              ),
                            );
                          })
                    ],
                  )),
              Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    width: width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder(
                            valueListenable: _now,
                            builder: (context, value, child) {
                              return Text(
                                value,
                                style: TextStyle(
                                  fontFamily: settings.fontFamily,
                                ),
                              );
                            }),
                        ValueListenableBuilder(
                            valueListenable: _currentPage,
                            builder: (context, value, child) {
                              return Text(
                                '${(((currentSeqNo.value + 1) / chapterList.length) * 100).toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontFamily: settings.fontFamily,
                                ),
                              );
                            })
                      ],
                    ),
                  )),
              ValueListenableBuilder(
                  valueListenable: showOption,
                  builder: (context, value, child) {
                    return value
                        ? Positioned(
                            left: 0,
                            top: 0,
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
                                    onTap: () async {
                                      Get.back();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: const Icon(Icons.arrow_back_ios),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      try {
                                        if (book.id == '-1') {
                                          book.title = outSideBook.title;
                                          book.page = nowChapterPage;
                                          book.percent =
                                              ((currentSeqNo.value + 1) /
                                                      chapterList.length) *
                                                  100;
                                          book.chapterTitleExp =
                                              chapterTitleExp;
                                          book.currentChapter =
                                              currentSeqNo.value;
                                          book.type = Constant.outSideType;
                                          book.seqNo = 1;
                                          book.cover = "";
                                          book.parentId = "";
                                          book.path =
                                              '${outSideBook.bookSourceId}|${outSideBook.url}';
                                          book.updateTime = DateTime.now()
                                              .millisecondsSinceEpoch;
                                          book.createTime = DateTime.now()
                                              .millisecondsSinceEpoch;
                                          book.id = (await DatabaseHelper.db
                                                  .insert(book))
                                              .toString();
                                          setState(() {
                                            book.id = book.id;
                                          });
                                        }
                                      } catch (e) {
                                        Get.snackbar('错误', e.toString());
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: book.id == '-1'
                                          ? const Text('收藏')
                                          : const Text('已收藏'),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        : const SizedBox.shrink();
                  }),
              ValueListenableBuilder(
                  valueListenable: showOption,
                  builder: (context, value, child) {
                    return value
                        ? Positioned(
                            left: 0,
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 110,
                              decoration:
                                  const BoxDecoration(color: Colors.white),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          nowChapterPage = 0;
                                          switchChapter1(
                                              currentSeqNo.value - 1);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            '上一章',
                                            style: TextStyle(
                                                fontFamily: settings.fontFamily,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          nowChapterPage = 0;
                                          switchChapter1(
                                              currentSeqNo.value + 1);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            '下一章',
                                            style: TextStyle(
                                                fontFamily: settings.fontFamily,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: width,
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            showChapter.value =
                                                !(showChapter.value);
                                          },
                                          child: Wrap(
                                            direction: Axis.vertical,
                                            children: [
                                              showChapter.value
                                                  ? const Icon(Icons.book)
                                                  : const Icon(
                                                      Icons.book_outlined),
                                              Text(
                                                '目录',
                                                style: TextStyle(
                                                    fontFamily:
                                                        settings.fontFamily,
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            showFont.value = !(showFont.value);
                                          },
                                          child: Wrap(
                                            direction: Axis.vertical,
                                            children: [
                                              const Icon(
                                                  Icons.font_download_outlined),
                                              Text(
                                                '字体',
                                                style: TextStyle(
                                                    fontFamily:
                                                        settings.fontFamily,
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            SystemChrome
                                                .setSystemUIOverlayStyle(
                                                    SystemUiOverlayStyle
                                                        .dark // 设置为暗色模式
                                                    );
                                          },
                                          child: Wrap(
                                            direction: Axis.vertical,
                                            children: [
                                              const Icon(
                                                  Icons.lightbulb_outline),
                                              Text(
                                                '亮度',
                                                style: TextStyle(
                                                    fontFamily:
                                                        settings.fontFamily,
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {},
                                          child: Wrap(
                                            direction: Axis.vertical,
                                            children: [
                                              const Icon(
                                                  Icons.nights_stay_outlined),
                                              Text(
                                                '夜间',
                                                style: TextStyle(
                                                    fontFamily:
                                                        settings.fontFamily,
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            showSettings.value =
                                                !(showSettings.value);
                                          },
                                          child: Wrap(
                                            direction: Axis.vertical,
                                            children: [
                                              Icon(showSettings.value
                                                  ? Icons.settings
                                                  : Icons.settings_outlined),
                                              Text(
                                                '设置',
                                                style: TextStyle(
                                                    fontFamily:
                                                        settings.fontFamily,
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ))
                        : const SizedBox.shrink();
                  }),
              ValueListenableBuilder(
                  valueListenable: showSettings,
                  builder: (context, value, child) {
                    return value
                        ? ReadSettings(
                            chapterTitleExpController:
                                _chapterTitleExpController,
                            settings: settings,
                            updateFunc: (Settings setting) {
                              setState(() {
                                settings = setting;
                                switchChapter1(currentSeqNo.value);
                              });
                            },
                            updateExpFunc: (String text) async {},
                            backgroundColorList: backgroundColorList)
                        : const SizedBox.shrink();
                  }),
              ValueListenableBuilder(
                  valueListenable: showChapter,
                  builder: (context, value, child) {
                    List<Chapter> chapters = [];

                    var newBook = Book();

                    try {
                      newBook.title = outSideBook.title;
                    } catch (e) {
                      newBook.title = book.title;
                    }

                    for (var outSideChapter in chapterList) {
                      chapters.add(Chapter()
                        ..title = outSideChapter.title
                        ..seqNo = outSideChapter.seqNo);
                    }
                    return value
                        ? Positioned(
                            left: 0,
                            right: 0,
                            bottom: 70,
                            height: 400,
                            child: ReadChapterList(
                              chapterList: chapters,
                              book: newBook,
                              currentSeqNo: currentSeqNo.value,
                              clickFunc: (String chapterTitle, int seqNo) {
                                nowChapterPage = 0;
                                _nowChapter.value = chapterTitle;
                                switchChapter1(seqNo);
                              },
                            ))
                        : const SizedBox.shrink();
                  }),
              ValueListenableBuilder(
                  valueListenable: showFont,
                  builder: (context, value, child) {
                    return value
                        ? Positioned(
                            left: 0,
                            right: 0,
                            bottom: 70,
                            height: 300,
                            child: ReadFontSetting(
                              settings: settings,
                              updateFunc: (Settings setting) {
                                setState(() {
                                  settings = setting;
                                  switchChapter1(currentSeqNo.value);
                                });
                              },
                            ))
                        : const SizedBox.shrink();
                  }),
            ],
          ),
        )));
  }

  @override
  void dispose() {
    book.page = nowChapterPage;
    book.percent = ((currentSeqNo.value + 1) / chapterList.length) * 100;
    book.chapterTitleExp = chapterTitleExp;
    book.currentChapter = currentSeqNo.value;
    if (book.id != '-1') {
      DatabaseHelper.db.updateById(book);
    }
    SharedPreferences.getInstance().then((value) {
      value.setString(Constant.readConfigKey, const JsonEncoder().convert(settings.toMap()));
    });
    if (settingController.isOpenVolumeFlip.value) {
      volumeUtils.removeListener(needRestore: true);
    }
    _currentPage.dispose();
    _pageController.dispose();
    _bookTitleController.dispose();
    _chapterTitleExpController.dispose();
    super.dispose();
  }
}
