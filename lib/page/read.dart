import 'dart:async';
import 'dart:convert';

import 'package:read_app/pojo/status.dart';
import 'package:read_app/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/listener/window_listener.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/chapter.dart';
import 'package:read_app/pojo/operation_log.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/utils/book_utils.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/platform_utils.dart';
import 'package:read_app/utils/tts_service.dart';
import 'package:read_app/utils/volume_utils.dart';
import 'package:read_app/widget/read/brightness_setting.dart';
import 'package:read_app/widget/read/chapter_list.dart';
import 'package:read_app/widget/read/font_setting.dart';
import 'package:read_app/widget/read/settings.dart';
import 'package:real_page_flip/page_flip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

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
    0xFF555354,
  ];
  Settings settings = Settings();
  ValueNotifier<int> currentSeqNo = ValueNotifier(0);
  late Book book;
  late double height;
  late double width;
  List<Chapter> chapterList = [];
  List<Widget?> widgetList = [];
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
  final PageFlipController _pageFlipController = PageFlipController();
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

  Timer? _timeTimer;
  Timer? _dataTimer;
  late final WindowListener _listener;
  int maxContentPage = 5000;
  late int defaultHasContentPage = (maxContentPage / 2).round();
  int startHasContentPage = 0;
  int nowContentPage = 0;
  String zhanwei = '\u3000\u3000';
  String zhanwei1 = '\u3000\u3000';
  int _contentRevision = 0;
  TtsService tts = TtsService();
  ValueNotifier<String> nowSpeakLine = ValueNotifier('');
  List<List<String>?> pageTextList = [];
  Status status = Status();
  bool openVolumeFlip = false;

  Future<void> init(Book book) async {
    if (settingController.isOpenVolumeFlip.value) {
      openVolumeFlip = true;
      volumeUtils.init((double beforeVolume, double nowVolume) {
        if (beforeVolume < nowVolume) {
          nextPage();
        } else if (beforeVolume > nowVolume) {
          previousPage();
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

    _dataTimer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      updateBook();
    });

    var value = await SharedPreferences.getInstance();
    var config = const JsonDecoder().convert(
      value.getString(Constant.readConfigKey) ?? '{}',
    );
    settings = Settings.fromMap(config);

    switchChapter1(currentSeqNo.value);
  }

  Future<void> updateBook() async {
    book.page = nowChapterPage;
    book.percent =
    (((currentSeqNo.value + 1) / chapterList.length) * 100).isInfinite
        ? 0
        : ((currentSeqNo.value + 1) / chapterList.length) * 100;
    book.chapterTitleExp = chapterTitleExp;
    book.currentChapter = currentSeqNo.value;
    DatabaseHelper.db.updateById(book);
    SharedPreferences.getInstance().then((value) {
      value.setString(
        Constant.readConfigKey,
        const JsonEncoder().convert(settings.toMap()),
      );
    });
  }

  void previousPage() {
    if (settings.isFlip) {
      _pageFlipController.markPageDirty(_currentPage.value - 1);
      _pageFlipController.previousPage();
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
      );
    }
  }

  void nextPage() {
    if (settings.isFlip) {
      _pageFlipController.nextPage();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void jumpToPage(int page) {
    if (settings.isFlip) {
      _pageFlipController.goToPage(page);
    } else {
      _pageController.jumpToPage(page);
    }
  }

  @override
  void initState() {
    super.initState();
    tts.callback = (text) {
      print('text $text');
      nowSpeakLine.value = text;
      var nowPage = pageTextList[_currentPage.value + 1];
      if (text == nowPage?[0]) {
        nextPage();
      }
    };
    if (PlatFormUtils.isDesktop()) {
      _listener = MyWindowListener(() {
        switchChapter1(currentSeqNo.value);
      });

      windowManager.addListener(_listener);
    }
    book = Get.arguments as Book;
    init(book);
  }

  void switchChapter1(int seqNo) async {
    isLoading = true;
    chapterTitlePageNumMap.clear();
    chapterPageNumTitleMap.clear();
    chapterPageNumList.clear();
    var value = await DatabaseHelper.db.getChapterByBookId(book.id);

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

    var hasEnd = false;

    if (end >= chapterList.length) {
      end = chapterList.length - 1;
      hasEnd = true;
    }

    var content = '';

    if (currentSeqNo.value == 0) {
      startHasContentPage = 0;
    } else {
      startHasContentPage = defaultHasContentPage;
    }
    nowContentPage = startHasContentPage;

    List<Widget?> pageList = List.generate(maxContentPage, (index) => null);
    List<List<String>?> textPageList = List.generate(maxContentPage, (index) => null);
    var dataDir = await getApplicationDocumentsDirectory();

    for (var i = start; i <= end; i++) {
      var chapter = chapterList[i];

      var chapterContent = await BookUtils.loadBook(
        join(dataDir.path, chapter.path),
      );
      chapterContent = chapterContent.replaceAll('\r', '');

      chapterContent = chapterContent.replaceAllMapped(
        RegExp(RegExp.escape(chapter.title) + r'(\n){2,}', multiLine: true),
        (Match match) {
          return '${match.group(0)!.replaceAll(match.group(1)!, '')}\n';
        },
      );

      chapterContent = chapterContent.replaceAllMapped(
        RegExp(r'(\n){2,}', multiLine: true),
        (Match match) {
          return '\n';
        },
      );

      var beforeAddLength = nowContentPage;

      chapterTitlePageNumMap[chapter.title] = beforeAddLength;
      chapterPageNumList.add(beforeAddLength);
      chapterPageNumTitleMap[beforeAddLength] = chapter;

      Map pageMap = calcPage(
        chapterContent,
        height,
        width,
        settings.fontSize,
      );

      List<Widget> pages = pageMap['pageList'];
      List<List<String>> textPage = pageMap['textPage'];

      if (nowContentPage + pages.length > maxContentPage) {
        pageList.addAll(List.generate(maxContentPage, (index) => null));
        textPageList.addAll(List.generate(maxContentPage, (index) => null));
      }

      for (int j = 0; j < pages.length; j++) {
        pageList[nowContentPage + j] = pages[j];
        textPageList[nowContentPage + j] = textPage[j];
      }

      nowContentPage += pages.length;

      if (hasEnd && i == chapterList.length) {
        setState(() {
          widgetList = widgetList.sublist(0, nowContentPage);
        });
      }

      if (seqNo == chapter.seqNo) {
        _nowChapter.value = chapter.title;
      }

      content += '\n$chapterContent';
    }

    setState(() {
      data = content;
      widgetList = pageList;
      if (startHasContentPage - 1 >= 0) {
        widgetList[startHasContentPage - 1] = const SizedBox.shrink();
      }
      pageTextList = textPageList;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var pageNum = chapterTitlePageNumMap[_nowChapter.value];
      pageNum ??= startHasContentPage;

      var nextChapterFirstPage =
          chapterPageNumList[(chapterPageNumList.length / 2).ceil()];
      if (nowChapterPage > 0 &&
          startHasContentPage + nowChapterPage > nextChapterFirstPage) {
        nowChapterPage = nextChapterFirstPage - pageNum - 1;
      }

      jumpToPage(pageNum + nowChapterPage);
      _currentPage.value = pageNum + nowChapterPage;
      isLoading = false;
    });
  }

  Future<void> switchChapter(int seqNo, bool isAfter, int currentPage) async {
    if (seqNo == -1 || isLoading) {
      return;
    }
    isLoading = true;

    Chapter currentChapter;

    try {
      currentChapter = chapterList[seqNo];
      if (chapterTitlePageNumMap.containsKey(currentChapter.title)) {
        if (chapterTitlePageNumMap[currentChapter.title] == currentPage) {
          switchChapter(seqNo + 1, true, currentPage);
        } else if (chapterTitlePageNumMap[currentChapter.title] ==
            startHasContentPage) {
          switchChapter(seqNo - 1, true, currentPage);
        }

        isLoading = false;
        return;
      }
    } catch (e) {
      if (isAfter) {
        setState(() {
          widgetList = widgetList.sublist(0, nowContentPage);
        });
      }
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
      setState(() {
        widgetList = widgetList.sublist(0, nowContentPage);
      });
      return;
    }

    var content = '';

    List<Widget> pageList = [];

    var dataDir = await getApplicationDocumentsDirectory();

    var chapter = chapterList[end];
    var chapterContent = await BookUtils.loadBook(
      join(dataDir.path, chapter.path),
    );
    chapterContent = chapterContent.replaceAll('\r', '');

    chapterContent = chapterContent.replaceAllMapped(
      RegExp(RegExp.escape(chapter.title) + r'(\n){2,}', multiLine: true),
      (Match match) {
        return '${match.group(0)!.replaceAll(match.group(1)!, '')}\n';
      },
    );

    chapterContent = chapterContent.replaceAllMapped(
      RegExp(r'(\n){2,}', multiLine: true),
      (Match match) {
        return '\n';
      },
    );

    var beforeAddLength = nowContentPage;

    Map pageMap = calcPage(
      chapterContent,
      height,
      width,
      settings.fontSize,
    );
    List<Widget> pages = pageMap['pageList'];
    List<List<String>> textPage = pageMap['textPage'];
    if (status.isStartSpeak && isAfter) {
      for (var i = 0; i < textPage.length; i++) {
        var textList = textPage[i];
        for (var text in textList) {
          tts.speak(text, settings.sid);
        }
      }
    }
    pageList.addAll(pages);

    setState(() {
      if (isAfter) {
        chapterTitlePageNumMap[chapter.title] = beforeAddLength;
        chapterPageNumList.add(beforeAddLength);
        chapterPageNumTitleMap[beforeAddLength] = chapter;

        if (nowContentPage + pages.length > widgetList.length) {
          widgetList.addAll(List.generate(maxContentPage, (index) => null));
          pageTextList.addAll(List.generate(maxContentPage, (index) => null));
        }

        for (int i = 0; i < pages.length; i++) {
          widgetList[nowContentPage + i] = pages[i];
          pageTextList[nowContentPage + i] = textPage[i];
        }

        content = '$data\n$chapterContent';

        nowContentPage += pages.length;
      } else {
        content = '$chapterContent\n$data';
        chapterTitlePageNumMap[chapter.title] =
            startHasContentPage - pageList.length;
        chapterPageNumList.insert(0, startHasContentPage - pageList.length);
        chapterPageNumTitleMap[startHasContentPage - pageList.length] = chapter;
        for (int i = pageList.length - 1; i >= 0; i--) {
          widgetList[startHasContentPage - (pageList.length - i)] = pageList[i];
          pageTextList[startHasContentPage - (pageList.length - i)] = textPage[i];
        }
        startHasContentPage -= pageList.length;
        if (startHasContentPage - 1 >= 0) {
          widgetList[startHasContentPage - 1] = const SizedBox.shrink();
        }
      }
      data = content;
      _contentRevision += 1;
      isLoading = false;
    });

  }

  Widget addPage(List<Map> textList) {
    List<Widget> widgetList = [];

    for (var i = 0; i < textList.length; i++) {
      var item = textList[i];
      String text = item['text'];
      var isLast = item['isLast'];

      var hasChapterTitle = item['hasChapterTitle'] as bool;

      if (hasChapterTitle) {
        widgetList.add(
          ValueListenableBuilder(valueListenable: nowSpeakLine, builder: (BuildContext context, String value, Widget? child) {
            var isHighLight = false;
            if (value.isNotEmpty && text.trim().replaceFirst(zhanwei, '') == value) {
              isHighLight = true;
            }
            return Container(
              color: isHighLight ? Colors.yellow : Colors.transparent,
              width: double.infinity,
              child: Text(
                text.trim().replaceFirst(zhanwei, ''),
                textAlign: TextAlign.center,
                style: TextStyle(
                  height:
                  settings.lineHeight * settings.chapterTitleMultiFontSize,
                  fontSize:
                  settings.fontSize * settings.chapterTitleMultiFontSize,
                  fontFamily: settings.fontFamily,
                  color: Color(settings.fontColor),
                  fontWeight: fontWeightList[settings.titleFontWeight],
                  letterSpacing: settings.letterSpacing
                ),
              ),
            );
          }),
        );
      } else {
        if (i == textList.length - 1 && text.isEmpty) {
          continue;
        }
        if (text.startsWith(zhanwei)) {
          if (isLast) {
            text = text.replaceFirst(zhanwei, zhanwei1);
            var lastTextList = text.split('');
            widgetList.add(
              ValueListenableBuilder(valueListenable: nowSpeakLine, builder: (BuildContext context, String value, Widget? child) {
                var isHighLight = false;
                if (value.isNotEmpty && text.replaceFirst(zhanwei1, '') == value ) {
                  isHighLight = true;
                }
                return Container(
                  color: isHighLight ? Colors.yellow : Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: lastTextList.map((element) {
                      return Text(
                        element,
                        style: TextStyle(
                          height: settings.lineHeight,
                          fontSize: settings.fontSize,
                          fontFamily: settings.fontFamily,
                          color: Color(settings.fontColor),
                          fontWeight: fontWeightList[settings.contentFontWeight],
                          letterSpacing: settings.letterSpacing
                        ),
                      );
                    }).toList(),
                  ),
                );
              },),
            );
          } else {
            widgetList.add(
              ValueListenableBuilder(valueListenable: nowSpeakLine, builder: (BuildContext context, String value, Widget? child) {
                var isHighLight = false;
                if (value.isNotEmpty && text.replaceFirst(zhanwei1, '') == value) {
                  isHighLight = true;
                }
                return Container(
                  width: double.infinity,
                  color: isHighLight ? Colors.yellow : Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '测试',
                          // text: text,
                          style: TextStyle(
                            height: settings.lineHeight,
                            fontSize: settings.fontSize,
                            fontFamily: settings.fontFamily,
                            color: Colors.transparent,
                            fontWeight:
                            fontWeightList[settings.contentFontWeight],
                            letterSpacing: settings.letterSpacing
                          ),
                        ),
                        TextSpan(
                          text: text.replaceFirst(zhanwei, ''),
                          // text: text,
                          style: TextStyle(
                            height: settings.lineHeight,
                            fontSize: settings.fontSize,
                            fontFamily: settings.fontFamily,
                            color: Color(settings.fontColor),
                            fontWeight:
                            fontWeightList[settings.contentFontWeight],
                            letterSpacing: settings.letterSpacing
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.justify,
                    softWrap: true,
                    textWidthBasis: TextWidthBasis.longestLine,
                  ),
                );
              }),
            );
          }
        } else {
          if (isLast) {
            var lastTextList = text.split('');
            widgetList.add(
              ValueListenableBuilder(valueListenable: nowSpeakLine, builder: (BuildContext context, String value, Widget? child) {
                var isHighLight = false;
                if (value.isNotEmpty && text == value) {
                  isHighLight = true;
                }
                return Container(
                  color: isHighLight ? Colors.yellow : Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: lastTextList.map((element) {
                      return Text(
                        element,
                        style: TextStyle(
                          height: settings.lineHeight,
                          fontSize: settings.fontSize,
                          fontFamily: settings.fontFamily,
                          color: Color(settings.fontColor),
                          fontWeight: fontWeightList[settings.contentFontWeight],
                            letterSpacing: settings.letterSpacing
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            );
          } else {
            widgetList.add(
              ValueListenableBuilder(valueListenable: nowSpeakLine, builder: (BuildContext context, String value, Widget? child) {
                var isHighLight = false;
                if (value.isNotEmpty && text == value) {
                  isHighLight = true;
                }
                return Container(
                  color: isHighLight ? Colors.yellow : Colors.transparent,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    textAlign: TextAlign.justify,
                    softWrap: true,
                    textWidthBasis: TextWidthBasis.longestLine,
                    style: TextStyle(
                      height: settings.lineHeight,
                      fontSize: settings.fontSize,
                      fontFamily: settings.fontFamily,
                      color: Color(settings.fontColor),
                      fontWeight: fontWeightList[settings.contentFontWeight],
                      letterSpacing: settings.letterSpacing
                    ),
                  ),
                );
              }),
            );
          }
        }
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        settings.pageLeftPadding,
        0,
        settings.pageRightPadding,
        settings.showBottom ? 0 : 0,
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgetList,
      ),
    );
  }

  Map calcPage(
    String data,
    double height,
    double width,
    double fontSize,
  ) {
    if (settings.showBottom) {
      height = height - 30;
    }

    height = (height - settings.pageTopPadding - settings.pageBottomPadding)
        .floorToDouble();

    width = (width - settings.pageLeftPadding - settings.pageRightPadding)
        .floorToDouble();

    List<String> tempList = data.split('\n');

    RegExp exp = RegExp(chapterTitleExp);
    List<Map> pageTextList = [];

    for (var i = 0; i < tempList.length; i++) {
      var text = '$zhanwei${tempList[i].trim()}';

      var hasChapterTitle = exp.hasMatch(tempList[i].trim());

      var textInfo = {
        'text': text,
        'lines': [],
        'lineNum': 0,
        'hasChapterTitle': hasChapterTitle,
        'isEmptyLine': false,
        'isLast': false,
      };

      var lines = [];
      var lineNum = 0;

      if (hasChapterTitle) {
        while (text.isNotEmpty) {
          var str = firstLineText(
            text,
            TextStyle(
              height: settings.lineHeight * settings.chapterTitleMultiFontSize,
              fontSize: settings.fontSize * settings.chapterTitleMultiFontSize,
              fontFamily: settings.fontFamily,
              color: Color(settings.fontColor),
              fontWeight: fontWeightList[settings.titleFontWeight],
              letterSpacing: settings.letterSpacing
            ),
            width
          );
          text = text.replaceFirst(str, '');

          lines.add(str);
          lineNum += 1;
        }
        textInfo['lines'] = lines;
        textInfo['lineNum'] = lineNum;
        pageTextList.add(textInfo);
      } else {
        while (text.isNotEmpty) {
          var str = firstLineText(
            text,
            TextStyle(
              height: settings.lineHeight,
              fontSize: settings.fontSize,
              fontFamily: settings.fontFamily,
              color: Color(settings.fontColor),
              fontWeight: fontWeightList[settings.contentFontWeight],
              letterSpacing: settings.letterSpacing
            ),
            width
          );
          text = text.replaceFirst(str, '');
          lines.add(str);
          lineNum += 1;
        }

        textInfo['lines'] = lines;
        textInfo['lineNum'] = lineNum;
        pageTextList.add(textInfo);
        pageTextList.add({
          'text': '',
          'lines': [],
          'lineNum': 1,
          'hasChapterTitle': false,
          'isEmptyLine': true,
          'isLast': false,
        });
      }
    }

    List<Widget> pageList = [];
    List<List<String>> textPage = [];
    List<Map> textListPage = [];
    double nowHeight = 0.0;
    for (var pageText in pageTextList) {
      var hasChapterTitle = pageText['hasChapterTitle'];
      var lineNum = pageText['lineNum'];
      var lines = pageText['lines'];

      if (hasChapterTitle && textListPage.isNotEmpty) {
        pageList.add(addPage(textListPage));
        textPage.add(generateTextPage(textListPage));
        textListPage = [];
      }

      if (pageText['isEmptyLine'] && nowHeight == 0) {
        continue;
      }

      double thisLineHeight = 0.0;

      if (hasChapterTitle) {
        thisLineHeight +=
            ((settings.lineHeight * settings.chapterTitleMultiFontSize) *
                    settings.fontSize *
                    (settings.chapterTitleMultiFontSize))
                .ceil();
      } else {
        thisLineHeight += (settings.lineHeight * settings.fontSize).ceil();
      }

      if (nowHeight + (thisLineHeight * lineNum) < height) {
        textListPage.add(pageText);
        nowHeight += thisLineHeight * lineNum;
      } else {
        var nowText = '';
        List<String> lineList = [];
        int lineNum = 0;

        for (int i = 0; i < lines.length; i++) {
          var line = lines[i];

          if (nowHeight + thisLineHeight > height) {
            if (lineList.isNotEmpty) {
              for (var line1 in lineList) {
                textListPage.add({
                  'text': line1,
                  'hasChapterTitle': hasChapterTitle,
                  'isLast': true,
                });
              }
            }

            pageList.add(addPage(textListPage));
            textPage.add(generateTextPage(textListPage));
            lineList = [line];
            textListPage = [];
            nowText = line;
            nowHeight = thisLineHeight;
            lineNum = 0;
          } else {
            lineNum += 1;
            nowText += line;
            nowHeight += thisLineHeight;
            lineList.add(line);
          }
        }

        if (nowText.isNotEmpty) {
          textListPage.add({
            'text': nowText,
            'hasChapterTitle': hasChapterTitle,
            'isLast': false,
          });
        }
      }
    }

    if (textListPage.isNotEmpty) {
      pageList.add(addPage(textListPage));
      textPage.add(generateTextPage(textListPage));
    }

    return {
      'pageList': pageList,
      'textPage': textPage
    };
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

  String firstLineText(String text, TextStyle style, double maxWidth) {
    if (text.isEmpty) return '';

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
      maxLines: null,
    );

    painter.layout(minWidth: 0, maxWidth: maxWidth);
    final lines = painter.computeLineMetrics();

    if (lines.isEmpty) {
      painter.dispose();
      return '';
    }

    if (lines.length == 1) {
      painter.dispose();
      return text;
    }

    final secondLine = lines[1];

    final safeY = secondLine.baseline;

    final position = painter.getPositionForOffset(Offset(1.0, safeY));
    painter.dispose();

    if (position.offset > text.length) {
      return text;
    }

    return text.substring(0, position.offset);
  }

  void _onPageChanged(int leftPageIndex, int page) async {
    if (page == _currentPage.value) {
      return;
    }

    if (page < startHasContentPage) {
      jumpToPage(startHasContentPage);
      return;
    }

    if (page <= 0) {
      return;
    }

    if (chapterPageNumTitleMap.isEmpty) {
      return;
    }

    if (isLoading) {
      return;
    }

    var beforePage = _currentPage.value;
    _currentPage.value = page.round();

    if (beforePage > _currentPage.value) {
      if (beforePage - startHasContentPage < 4) {
        if (isLoading) {
          return;
        }
        await switchChapter(currentSeqNo.value - 1, false, _currentPage.value);
      }
    }

    if (beforePage < _currentPage.value) {
      if (nowContentPage - _currentPage.value < 4) {
        if (isLoading) {
          return;
        }
        await switchChapter(currentSeqNo.value + 1, true, _currentPage.value);
      }
    }

    if (page < chapterPageNumList[0]) {
      _nowChapter.value = '开始';
    } else {
      var chapterPage = chapterPageNumList[getChapterTitle(page)];
      nowChapterPage = page - chapterPage;

      var chapter = chapterPageNumTitleMap[chapterPage]!;
      currentSeqNo.value = chapter.seqNo;
      var title = chapter.title;
      if (_nowChapter.value != title) {
        _nowChapter.value = title;
      }
    }
  }

  Widget _buildPageWidget() {
    Widget pageWidget;

    if (settings.isFlip) {
      pageWidget = LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: PageFlipWidget(
                controller: _pageFlipController,
                contentRevision: _contentRevision,
                initialIndex: _currentPage.value,
                config: PageFlipConfig(
                  skipTapAnimation: false,
                  enableSinglePageSettleReveal: true,
                  snapshotRefreshPolicy:
                      PageFlipSnapshotRefreshPolicy.whenDirty,
                  backgroundColor: Color(settings.backgroundColor),
                  cutoffForward: 0.35,
                  cutoffPrevious: 0.5,
                  sensitivity: 0.5,
                  maxSnapshotPixelRatio: 2.5,
                ),
                spreadMode: PageFlipSpreadMode.single,
                itemBuilder: (BuildContext context, int index) {
                  if (widgetList[index] == null) {
                    return const SizedBox.shrink();
                  }
                  return RepaintBoundary(
                    key: ValueKey('page_$index'),
                    child: widgetList[index]!,
                  );
                },
                itemCount: widgetList.length,
                onPageFlipped: (page) {
                  _onPageChanged(0, page);
                },
                onPageChanged: (page) {},
                onFlipEnd: () {
                  _pageFlipController.markCurrentPageDirty();
                },
              ),
            ),
          );
        },
      );
    } else {
      pageWidget = PageView.builder(
        controller: _pageController,
        scrollDirection: settings.isVer ? Axis.vertical : Axis.horizontal,
        pageSnapping: settings.isVer ? false : true,
        itemCount: widgetList.length,
        physics: const ClampingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return widgetList[index];
        },
        onPageChanged: (page) {
          _onPageChanged(0, page);
        },
      );
    }

    return GestureDetector(
      onTapUp: (details) {
        if (settings.openFlip) {
          var dx = details.globalPosition.dx;
          var dy = details.globalPosition.dy;

          if (settings.isFlip || !settings.isVer) {
            if (dx < width / 5) {
              previousPage();
            } else if (dx > width / 5 * 4) {
              nextPage();
            } else {
              showOption.value = !(showOption.value);
              showSettings.value = false;
              showChapter.value = false;
              showFont.value = false;
              showBrightness.value = false;
            }
          } else {
            if (dy < height / 5) {
              previousPage();
            } else if (dy > height / 5 * 4) {
              nextPage();
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
        margin: EdgeInsets.fromLTRB(
          0,
          settings.pageTopPadding,
          0,
          settings.showBottom ? settings.pageBottomPadding : 0,
        ),
        height: height,
        width: width,
        child: widgetList.isNotEmpty ? pageWidget : const SizedBox.shrink(),
      ),
    );
  }

  List<String> generateTextPage(List<Map> textPageList) {
    List<String> textPage = [];
    for (var textMap in textPageList) {
      var text = textMap['text'] as String;
      if (text.startsWith(zhanwei)) {
        text = text.replaceFirst(zhanwei, '');
      }
      if (text.isEmpty) {
        continue;
      }
      textPage.add(text);
    }
    return textPage;
  }

  @override
  Widget build(BuildContext context) {
    var conte = MediaQuery.of(context);
    var topTitleHeight = 30.0;
    height = conte.size.height - conte.padding.top - conte.padding.bottom;
    width = conte.size.width - conte.padding.left - conte.padding.right;
    return Scaffold(
      backgroundColor: PlatFormUtils.isDesktop()
          ? Colors.transparent
          : Color(settings.backgroundColor),
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
                child: _buildPageWidget(),
              ),
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
                              color: Color(settings.titleFontColor),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
                                      color: Color(settings.fontColor)
                                    ),
                                  );
                                },
                              ),
                              ValueListenableBuilder(
                                valueListenable: _currentPage,
                                builder: (context, value, child) {
                                  return Text(
                                    '${(((currentSeqNo.value + 1) / chapterList.length) * 100).toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontFamily: settings.fontFamily,
                                        color: Color(settings.fontColor)
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
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
                            },
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
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
                              color: ColorUtils.returnDefaultColor(
                                settings.backgroundColor,
                              ),
                            ),
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
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
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
                              color: ColorUtils.returnDefaultColor(
                                settings.backgroundColor,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        nowChapterPage = 0;
                                        switchChapter1(currentSeqNo.value - 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          '上一章',
                                          style: TextStyle(
                                            fontFamily: settings.fontFamily,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        nowChapterPage = 0;
                                        switchChapter1(currentSeqNo.value + 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          '下一章',
                                          style: TextStyle(
                                            fontFamily: settings.fontFamily,
                                            fontSize: 12,
                                          ),
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
                                                    Icons.book_outlined,
                                                  ),
                                            Text(
                                              '目录',
                                              style: TextStyle(
                                                fontFamily: settings.fontFamily,
                                                fontSize: 10,
                                              ),
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
                                              Icons.font_download_outlined,
                                            ),
                                            Text(
                                              '字体',
                                              style: TextStyle(
                                                fontFamily: settings.fontFamily,
                                                fontSize: 10,
                                              ),
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
                                            const Icon(Icons.lightbulb_outline),
                                            Text(
                                              '亮度',
                                              style: TextStyle(
                                                fontFamily: settings.fontFamily,
                                                fontSize: 10,
                                              ),
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
                                              Icons.nights_stay_outlined,
                                            ),
                                            Text(
                                              '夜间',
                                              style: TextStyle(
                                                fontFamily: settings.fontFamily,
                                                fontSize: 10,
                                              ),
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
                                            Icon(
                                              showSettings.value
                                                  ? Icons.settings
                                                  : Icons.settings_outlined,
                                            ),
                                            Text(
                                              '设置',
                                              style: TextStyle(
                                                fontFamily: settings.fontFamily,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
              ValueListenableBuilder(
                valueListenable: showSettings,
                builder: (context, value, child) {
                  return value
                      ? ReadSettings(
                          chapterTitleExpController: _chapterTitleExpController,
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
                              book,
                              _chapterTitleExpController.text,
                            );

                            nowChapterPage = 0;
                            currentSeqNo.value = 0;
                            _currentPage.value = 1;

                            switchChapter1(0);

                            setState(() {
                              chapterTitleExp = _chapterTitleExpController.text;
                            });
                          },
                          backgroundColorList: backgroundColorList,
                          startSpeak: () {
                            // 3 外国少女   45 中文女  46 中文播音女  47 中文播音伪少女  48 中文少女
                            // tts.speak(tempList[i].trim(), 48);
                            for (var i = _currentPage.value; i < pageTextList.length; i++) {
                              var textList = pageTextList[i];
                              if (textList == null) {
                                return;
                              }
                              for (var text in textList) {
                                tts.speak(text, settings.sid);
                              }
                            }
                          },
                          status: status,
                        )
                      : const SizedBox.shrink();
                },
              ),
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
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
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
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
              ValueListenableBuilder(
                valueListenable: showBrightness,
                builder: (context, value, child) {
                  return value
                      ? BrightnessSetting(settings: settings)
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    tts.stop();
    _timeTimer?.cancel();
    _dataTimer?.cancel();
    updateBook();
    OperationLog operationLog = OperationLog.setOperationLog(
      book,
      book.id,
      Constant.operationUpdateType,
    );
    DatabaseHelper.db.insertOperationLog(operationLog);
    if (openVolumeFlip) {
      volumeUtils.removeListener(needRestore: true);
    }
    _currentPage.dispose();
    _pageController.dispose();
    _bookTitleController.dispose();
    _chapterTitleExpController.dispose();
    if (PlatFormUtils.isDesktop()) {
      windowManager.removeListener(_listener);
    }
    super.dispose();
  }
}
