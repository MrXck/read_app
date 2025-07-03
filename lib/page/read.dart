import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/chapter.dart';
import 'package:read_app/pojo/operation_log.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/utils/book_utils.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/regex_utils.dart';
import 'package:read_app/utils/volume_utils.dart';
import 'package:read_app/widget/read/brightness_setting.dart';
import 'package:read_app/widget/read/chapter_list.dart';
import 'package:read_app/widget/read/font_setting.dart';
import 'package:read_app/widget/read/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadPage extends StatefulWidget {
  const ReadPage({super.key});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  String data = '';
  String chapterTitleExp = Constant.defaultChapterTitleExp;
  ValueNotifier<bool> showOption = ValueNotifier(false);
  ValueNotifier<bool> showSettings = ValueNotifier(false);
  ValueNotifier<bool> showChapter = ValueNotifier(false);
  ValueNotifier<bool> showFont = ValueNotifier(false);
  ValueNotifier<bool> showBrightness = ValueNotifier(false);
  ValueNotifier<bool> showMask = ValueNotifier(false);
  List<int> backgroundColorList = [
    0xFFF8F7F3,
    0xFFE6DBC5,
    0xFFE9E2DA,
    0xFFD3DFC7,
    0xFF555354
  ];
  Settings settings = Settings();
  ValueNotifier<int> currentSeqNo = ValueNotifier(0);
  late Book book;
  late double height;
  late double width;
  List<Chapter> chapterList = [];
  List<Widget> widgetList = [];
  List<FontWeight> fontWeightList = [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ];
  final PageController _pageController = PageController();
  final _now = ValueNotifier('');
  final _nowChapter = ValueNotifier('开始');
  final _currentPage = ValueNotifier(0);
  final _chapterTitleExpController = TextEditingController();
  final _bookTitleController = TextEditingController();
  final VolumeUtils volumeUtils = VolumeUtils();
  final SettingController settingController = Get.find();
  int nowChapterPage = 0;
  bool isLoading = false;
  Map<String, int> chapterTitlePageNumMap = {};
  Map<int, Chapter> chapterPageNumTitleMap = {};
  List<int> chapterPageNumList = [];
  int startHasContentPage = 500;

  Timer? _throttleTimer;
  Timer? _timeTimer;
  Timer? _dataTimer;

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
    nowChapterPage = book.page;
    _chapterTitleExpController.text = book.chapterTitleExp;
    _bookTitleController.text = book.title;
    chapterTitleExp = book.chapterTitleExp;
    currentSeqNo.value = book.currentChapter;

    var time = DateTime.now();
    _now.value =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      var time = DateTime.now();
      _now.value =
          '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    });

    _dataTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      DatabaseHelper.db.updateById(book);
    });

    var value = await SharedPreferences.getInstance();
    var config = const JsonDecoder()
        .convert(value.getString(Constant.readConfigKey) ?? '{}');
    settings = Settings.fromMap(config);

    switchChapter1(currentSeqNo.value);
  }

  @override
  void initState() {
    super.initState();
    book = Get.arguments as Book;
    init(book);
  }

  void switchChapter1(int seqNo) async {
    isLoading = true;
    chapterTitlePageNumMap.clear();
    chapterPageNumTitleMap.clear();
    chapterPageNumList.clear();
    var value = await DatabaseHelper.db.getChapterByBookId(book.id);
    var dataDir = await getApplicationDocumentsDirectory();

    chapterList = value;

    Chapter currentChapter;

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

    var start = currentChapterIndex - 1;
    var end = currentChapterIndex + 1;

    if (start < 0) {
      start = 0;
      end++;
    }

    if (end >= chapterList.length) {
      end = chapterList.length - 1;
    }

    var content = '';

    if (book.currentChapter == 0) {
      startHasContentPage = 0;
    } else {
      startHasContentPage = 500;
    }

    List<Widget> pageList =
        List.generate(startHasContentPage, (index) => const SizedBox.shrink());

    for (var i = start; i <= end; i++) {
      var chapter = chapterList[i];
      var chapterContent =
          await BookUtils.loadBook(join(dataDir.path, chapter.path));
      chapterContent = chapterContent.replaceAll('\r', '');

      chapterContent = chapterContent.replaceAllMapped(
          RegExp(RegExp.escape(chapter.title) + r'(\n){2,}',
              multiLine: true), (Match match) {
        return '${chapter.title}\n';
      });

      chapterContent = chapterContent.replaceAllMapped(
          RegExp(r'(\n){2,}', multiLine: true), (Match match) {
        return '\n';
      });

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

  void switchChapter(int seqNo, bool isAfter, int currentPage) async {
    if (seqNo == -1) {
      return;
    }
    isLoading = true;

    var dataDir = await getApplicationDocumentsDirectory();

    Chapter currentChapter;

    try {
      currentChapter = chapterList[seqNo];
      if (chapterTitlePageNumMap.containsKey(currentChapter.title)) {

        if (chapterTitlePageNumMap[currentChapter.title] == currentPage) {
          switchChapter(seqNo + 1, true, currentPage);
        } else if (chapterTitlePageNumMap[currentChapter.title] == startHasContentPage) {
          switchChapter(seqNo - 1, true, currentPage);
        }

        isLoading = false;
        return;
      }
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
      isLoading = false;
      return;
    }

    var content = '';

    List<Widget> pageList = [];

    var chapter = chapterList[end];
    var chapterContent =
        await BookUtils.loadBook(join(dataDir.path, chapter.path));
    chapterContent = chapterContent.replaceAll('\r', '');

    chapterContent = chapterContent.replaceAllMapped(
        RegExp(RegExp.escape(chapter.title) + r'(\n){2,}',
            multiLine: true), (Match match) {
      return '${match.group(0)!.replaceAll(match.group(1)!, '')}\n';
    });

    chapterContent = chapterContent.replaceAllMapped(
        RegExp(r'(\n){2,}', multiLine: true), (Match match) {
      return '\n';
    });

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
        startHasContentPage -= pageList.length;
      }
      data = content;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading = false;
    });
  }

  Widget addPage(List<Map> textList, int totalPageNum, int everyLineFontNum,
      double everyLineHeight) {
    List<Widget> widgetList = [];

    for (var i = 0; i < textList.length; i++) {
      var item = textList[i];
      String text = item['text'];

      var hasChapterTitle = item['hasChapterTitle'] as bool;

      if (hasChapterTitle) {
        widgetList.add(Text(
          text.trim(),
          textAlign: TextAlign.center,
          style: TextStyle(
              height: settings.lineHeight * settings.chapterTitleMultiFontSize,
              fontSize: settings.fontSize * settings.chapterTitleMultiFontSize,
              fontFamily: settings.fontFamily,
              color: Color(settings.fontColor),
              fontWeight: fontWeightList[settings.titleFontWeight]),
        ));
      } else {
        if (text.startsWith('       ')) {
          text = text.replaceFirst('       ', '');
          var textList1 = text.split('');

          if (!item['isLast']) {
            List<Widget> tt = [];
            tt.add(Row(
              children: [
                SizedBox(
                  width: settings.fontSize * 2,
                  height: everyLineHeight,
                )
              ],
            ));
            List<Widget> rowChildren = [];
            for (var j = 0; j < textList1.length; j++) {
              var item = textList1[j];
              rowChildren.add(Text(
                item,
                style: TextStyle(
                    height: settings.lineHeight,
                    fontSize: settings.fontSize,
                    fontFamily: settings.fontFamily,
                    color: Color(settings.fontColor),
                    fontWeight: fontWeightList[settings.contentFontWeight]),
              ));
            }
            tt.add(Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: rowChildren,
            )));

            widgetList.add(Row(
              children: tt,
            ));
          } else {
            widgetList.add(Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: settings.fontSize * 2,
                  height: everyLineHeight,
                ),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      height: settings.lineHeight,
                      fontSize: settings.fontSize,
                      fontFamily: settings.fontFamily,
                      color: Color(settings.fontColor),
                      fontWeight: fontWeightList[settings.contentFontWeight]),
                )
              ],
            ));
          }
        } else {
          List<Widget> tt = [];
          var textList1 = text.trim().split('');

          if (!item['isLast']) {
            for (var j = 0; j < textList1.length; j++) {
              var item = textList1[j];
              tt.add(Text(
                item,
                style: TextStyle(
                    height: settings.lineHeight,
                    fontSize: settings.fontSize,
                    fontFamily: settings.fontFamily,
                    color: Color(settings.fontColor),
                    fontWeight: fontWeightList[settings.contentFontWeight]),
              ));
            }

            widgetList.add(Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: tt,
            ));
          } else {
            widgetList.add(Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  height: settings.lineHeight,
                  fontSize: settings.fontSize,
                  fontFamily: settings.fontFamily,
                  color: Color(settings.fontColor),
                  fontWeight: fontWeightList[settings.contentFontWeight]),
            ));
          }
        }
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(settings.pageLeftPadding, 0,
          settings.pageRightPadding, settings.showBottom ? 0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgetList,
      ),
    );
  }

  TextPainter calculateTextHeight(
      String text, TextStyle style, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: null, // null 表示不限制行数
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter;
  }

  List<Widget> calcPage(String data, double height, double width,
      double fontSize, double lineHeight) {
    if (settings.showBottom) {
      height = height - 30;
    }

    height -= settings.pageTopPadding;
    height -= settings.pageBottomPadding;

    width = width - settings.pageLeftPadding - settings.pageRightPadding;

    var textPainter = calculateTextHeight(
        "测",
        TextStyle(
            height: settings.lineHeight,
            fontSize: settings.fontSize,
            fontFamily: settings.fontFamily,
            color: Color(settings.fontColor),
            fontWeight: fontWeightList[settings.contentFontWeight]),
        width);

    double everyLineHeight = textPainter.size.height.ceilToDouble();

    int lineNum = (height / everyLineHeight).floor();

    int everyLineFontNum = (width / textPainter.size.width).floor();

    // data = data.replaceAll(RegExp(r'\r'), '');
    // data = data.replaceAll(RegExp(r'(?<!\r?\n)\r?\n(?!\r?\n)'), '\n\n');
    List<String> tempList = data.split('\n');
    List<String> textList = [];

    for (var i = 0; i < tempList.length; i++) {
      textList.add(tempList[i]);
      if (i != tempList.length - 1) {
        textList.add('');
      }
    }

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
          end = text.length > Constant.defaultChapterTitleMaxLength ? Constant.defaultChapterTitleMaxLength : text.length;
        } else {
          end = num + everyLineFontNum > text.length
              ? text.length
              : num + everyLineFontNum;
        }

        var newText = text.substring(0, end);

        var emptyStrNum = RegexUtils.matchEmptyStr(newText);

        if (emptyStrNum > 1) {
          end +=
              (emptyStrNum / settings.chapterContentEmptyStrDivisionCoefficient)
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
      String text = item['text'];

      var hasChapterTitle = item['hasChapterTitle'];
      if (hasChapterTitle && xxx.isNotEmpty) {
        pageList.add(
            addPage(xxx, pageList.length, everyLineFontNum, everyLineHeight));
        xxx = [];
        currentLine = 0;
      }

      if (currentLine >= lineNum) {
        pageList.add(
            addPage(xxx, pageList.length, everyLineFontNum, everyLineHeight));
        currentLine = 0;
        xxx = [];
      }
      if (hasChapterTitle) {
        while (text.isNotEmpty) {
          var addMap = {'text': text, 'hasChapterTitle': true, 'isLast': true};

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
        if (xxx.isEmpty && text.trim().isEmpty) {
          continue;
        }
        var addMap = {
          'text': text,
          'hasChapterTitle': hasChapterTitle,
          'isLast': true
        };
        if (n != pageTextList.length - 1 &&
            pageTextList[n + 1]['text'].trim().isNotEmpty) {
          addMap['isLast'] = false;
        }

        xxx.add(addMap);
        currentLine += 1;
      }
    }

    if (xxx.isNotEmpty) {
      pageList.add(
          addPage(xxx, pageList.length, everyLineFontNum, everyLineHeight));
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
    var topTitleHeight = 30.0;
    height = conte.size.height - conte.padding.top - conte.padding.bottom;
    width = conte.size.width - conte.padding.left - conte.padding.right;
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
                  top: topTitleHeight,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTapUp: (details) {
                      if (settings.openFlip) {
                        var dx = details.globalPosition.dx;
                        var dy = details.globalPosition.dy;

                        if (settings.isVer) {
                          if (dy < height / 5) {
                            _pageController.previousPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                          } else if (dy > height / 5 * 4) {
                            _pageController.nextPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                          } else {
                            showOption.value = !(showOption.value);
                            showSettings.value = false;
                            showChapter.value = false;
                            showFont.value = false;
                            showBrightness.value = false;
                          }
                        } else {
                          if (dx < width / 5) {
                            _pageController.previousPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                          } else if (dx > width / 5 * 4) {
                            _pageController.nextPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                          } else {
                            showOption.value = !(showOption.value);
                            showSettings.value = false;
                            showChapter.value = false;
                            showFont.value = false;
                            showBrightness.value = false;
                          }
                        }
                      } else {
                        showOption.value = !(showOption.value);
                        showSettings.value = false;
                        showChapter.value = false;
                        showFont.value = false;
                        showBrightness.value = false;
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.fromLTRB(0, settings.pageTopPadding, 0, settings.showBottom ? settings.pageBottomPadding : 0),
                      height: height,
                      width: width,
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection:
                            settings.isVer ? Axis.vertical : Axis.horizontal,
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

                          var beforePage = _currentPage.value;
                          _currentPage.value =
                              _pageController.page!.round() + 1;

                          if (beforePage > _currentPage.value) {
                            if (beforePage - startHasContentPage < 4) {
                              if (isLoading) {
                                return;
                              }
                              switchChapter(currentSeqNo.value - 1, false, _currentPage.value);
                            }
                          }

                          if (beforePage < _currentPage.value) {
                            if (widgetList.length - _currentPage.value < 4) {
                              if (isLoading) {
                                return;
                              }
                              switchChapter(currentSeqNo.value + 1, true, _currentPage.value);
                            }
                          }

                          _throttleTimer?.cancel();

                          _throttleTimer = Timer(
                              const Duration(milliseconds: 100), () async {
                            book.page = nowChapterPage;
                            book.percent = ((currentSeqNo.value + 1) /
                                    chapterList.length) *
                                100;
                            book.chapterTitleExp = chapterTitleExp;
                            book.currentChapter = currentSeqNo.value;

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
                          });
                        },
                      ),
                    ),
                  )),
              Positioned(
                  top: 0,
                  left: 10,
                  right: 0,
                  height: topTitleHeight,
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
                                    color: Color(settings.titleFontColor)),
                              ),
                            );
                          })
                    ],
                  )),
              settings.showBottom
                  ? Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        color: Color(settings.backgroundColor),
                        width: width,
                        child: Center(
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
                        ),
                      ))
                  : const SizedBox.shrink(),
              ValueListenableBuilder(
                  valueListenable: showMask,
                  builder: (context, value, child) {
                    return value
                        ? Positioned.fill(
                            child: ModalBarrier(
                                color: Colors.black54,
                                dismissible: true,
                                onDismiss: () {
                                  showChapter.value = false;
                                  showFont.value = false;
                                  showBrightness.value = false;
                                  showSettings.value = false;
                                  showMask.value = false;
                                }),
                          )
                        : const SizedBox.shrink();
                  }),
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
                              decoration: BoxDecoration(
                                  color: Color(settings.backgroundColor)),
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
                              decoration: BoxDecoration(
                                  color: Color(settings.backgroundColor)),
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

                                            showSettings.value = false;
                                            showFont.value = false;
                                            showBrightness.value = false;

                                            if (showChapter.value ||
                                                showSettings.value ||
                                                showFont.value ||
                                                showBrightness.value) {
                                              showMask.value = true;
                                            } else {
                                              showMask.value = false;
                                            }
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

                                            showChapter.value = false;
                                            showSettings.value = false;
                                            showBrightness.value = false;

                                            if (showChapter.value ||
                                                showSettings.value ||
                                                showFont.value ||
                                                showBrightness.value) {
                                              showMask.value = true;
                                            } else {
                                              showMask.value = false;
                                            }
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
                                            showChapter.value = false;
                                            showSettings.value = false;
                                            showBrightness.value =
                                                !(showBrightness.value);
                                            showFont.value = false;

                                            if (showChapter.value ||
                                                showSettings.value ||
                                                showFont.value ||
                                                showBrightness.value) {
                                              showMask.value = true;
                                            } else {
                                              showMask.value = false;
                                            }
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

                                            showChapter.value = false;
                                            showFont.value = false;
                                            showBrightness.value = false;

                                            if (showChapter.value ||
                                                showSettings.value ||
                                                showFont.value ||
                                                showBrightness.value) {
                                              showMask.value = true;
                                            } else {
                                              showMask.value = false;
                                            }
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
                            updateExpFunc: (String text) async {
                              showSettings.value = false;

                              await BookUtils.changeChapterTitleExp(
                                  book, _chapterTitleExpController.text);

                              nowChapterPage = 0;
                              currentSeqNo.value = 0;
                              _currentPage.value = 1;

                              switchChapter1(0);

                              setState(() {
                                chapterTitleExp =
                                    _chapterTitleExpController.text;
                              });
                            },
                            backgroundColorList: backgroundColorList)
                        : const SizedBox.shrink();
                  }),
              ValueListenableBuilder(
                  valueListenable: showChapter,
                  builder: (context, value, child) {
                    return value
                        ? Positioned(
                            left: 0,
                            right: 0,
                            bottom: 70,
                            height: height * 0.7,
                            child: ReadChapterList(
                              chapterList: chapterList,
                              book: book,
                              currentSeqNo: currentSeqNo.value,
                              clickFunc: (String chapterTitle, int seqNo) {
                                nowChapterPage = 0;
                                _nowChapter.value = chapterTitle;
                                switchChapter1(seqNo);
                              },
                              settings: settings,
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
              ValueListenableBuilder(
                  valueListenable: showBrightness,
                  builder: (context, value, child) {
                    return value
                        ? BrightnessSetting(settings: settings)
                        : const SizedBox.shrink();
                  }),
            ],
          ),
        )));
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _dataTimer?.cancel();
    book.page = nowChapterPage;
    book.percent = ((currentSeqNo.value + 1) / chapterList.length) * 100;
    book.chapterTitleExp = chapterTitleExp;
    book.currentChapter = currentSeqNo.value;
    DatabaseHelper.db.updateById(book);
    OperationLog operationLog = OperationLog.setOperationLog(book, book.id, Constant.operationUpdateType);
    DatabaseHelper.db.insertOperationLog(operationLog);
    SharedPreferences.getInstance().then((value) {
      value.setString(Constant.readConfigKey,
          const JsonEncoder().convert(settings.toMap()));
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
