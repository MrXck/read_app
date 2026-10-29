import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/chapter.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/utils/book_utils.dart';
import 'package:read_app/utils/color_utils.dart';

typedef ClickFunc = void Function(String chapterTitle, int pageNum);
typedef ClickSearchResultFunc = void Function(ChapterInfo chapterInfo);

class ChapterInfo {
  late String title;
  late String keyword;
  late String fullLine;
  late String snippet;
  late Widget highlightSnippetWidget;
  late int seqNo;

  ChapterInfo(
    this.title,
    this.keyword,
    this.fullLine,
    this.snippet,
    this.highlightSnippetWidget,
    this.seqNo,
  );
}

class MatchResult {
  final String fullLine;
  final String snippet;
  final int matchIndex; // 第几个命中（可选，展示用）

  MatchResult(this.fullLine, this.snippet, this.matchIndex);
}

Widget highlightSnippet(String snippet, String keyword) {
  final spans = <TextSpan>[];
  var start = 0;

  while (true) {
    final index = snippet.indexOf(keyword, start);
    if (index == -1) {
      spans.add(TextSpan(text: snippet.substring(start)));
      break;
    }
    spans.add(TextSpan(text: snippet.substring(start, index)));
    spans.add(
      TextSpan(
        text: keyword,
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );
    start = index + keyword.length;
  }

  return Text.rich(TextSpan(children: spans), maxLines: 2);
}

List<MatchResult> buildMatchResults({
  required String line,
  required String keyword,
  int context = 20,
}) {
  // 1. 收集所有命中位置
  final hits = <int>[];
  var start = 0;
  while (true) {
    final idx = line.indexOf(keyword, start);
    if (idx == -1) break;
    hits.add(idx);
    start = idx + keyword.length;
  }
  if (hits.isEmpty) return [];

  // 2. 计算每个命中的窗口，并把重叠的合并
  final merged = <List<int>>[]; // 每个元素是 [begin, end)
  for (final idx in hits) {
    final begin = (idx - context).clamp(0, line.length);
    final end = (idx + keyword.length + context).clamp(0, line.length);

    final last = merged.isEmpty ? null : merged.last;
    if (last != null && begin <= last[1]) {
      // 与上一个窗口重叠（或相接）→ 扩展上一个窗口
      last[1] = end > last[1] ? end : last[1];
    } else {
      merged.add([begin, end]);
    }
  }

  // 3. 每个合并后的窗口生成一个片段，并统计包含几个命中
  final results = <MatchResult>[];
  for (final window in merged) {
    final begin = window[0];
    final end = window[1];

    var snippet = line.substring(begin, end);
    if (begin > 0) snippet = '...$snippet';
    if (end < line.length) snippet = '$snippet...';

    // 统计这个窗口里有几个命中（用于显示"含 2 处匹配"）
    final count = hits.where((h) => h >= begin && h < end).length;

    results.add(MatchResult(line, snippet, count));
  }
  return results;
}

class ReadChapterList extends StatefulWidget {
  final ClickFunc clickFunc;
  final ClickSearchResultFunc clickSearchResultFunc;
  final Book book;
  final int currentSeqNo;
  final List<Chapter> chapterList;
  final Settings settings;
  final bool showSearch;

  const ReadChapterList({
    super.key,
    required this.book,
    required this.currentSeqNo,
    required this.chapterList,
    required this.clickFunc,
    required this.settings,
    required this.clickSearchResultFunc,
    this.showSearch = false,
  });

  @override
  State<ReadChapterList> createState() => _ReadChapterListState();
}

class _ReadChapterListState extends State<ReadChapterList> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController textFieldController = TextEditingController();

  final FocusNode _focusNode = FocusNode();
  bool _expanded = false;
  Timer? _debounce;

  List<ChapterInfo> searchResultList = [];

  @override
  void initState() {
    super.initState();
  }

  List<String> regexpKeyword(String keyword, String content) {
    final regExp = RegExp('^.*${RegExp.escape(keyword)}.*\$', multiLine: true);
    return regExp.allMatches(content).map((m) => m.group(0)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var chapterList = widget.chapterList;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorUtils.returnDefaultColor(widget.settings.backgroundColor),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      height: MediaQuery.of(context).size.height,
      child: GestureDetector(
        // 点击列表空白处收起搜索框
        onTap: () => _focusNode.unfocus(),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: _expanded ? -40 : 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _expanded ? 0 : 1,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: Text(
                    widget.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: _expanded ? -40 : 50,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _expanded ? 0 : 1,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '共 ${chapterList.length} 章',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Visibility(
              visible: widget.showSearch,
              child: AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: _expanded ? 10 : 50,
                left: _expanded ? 16 : size.width * 0.5,
                right: _expanded ? 8 : 20,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 30,
                  child: SizedBox(
                    child: _expanded
                        ? Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color:
                                      ColorUtils.returnDefaultColor(
                                        widget.settings.backgroundColor,
                                      ).withValues(
                                        red:
                                            ColorUtils.returnDefaultColor(
                                              widget.settings.backgroundColor,
                                            ).r *
                                            0.9,
                                        green:
                                            ColorUtils.returnDefaultColor(
                                              widget.settings.backgroundColor,
                                            ).g *
                                            0.9,
                                        blue:
                                            ColorUtils.returnDefaultColor(
                                              widget.settings.backgroundColor,
                                            ).b *
                                            0.9,
                                      ),
                                ),
                                width: size.width - 62,
                                child: TextField(
                                  autofocus: _expanded ? true : false,
                                  controller: textFieldController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search, size: 20),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    hintText: "搜全文",
                                    hintStyle: TextStyle(color: Colors.black26),
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _expanded = true;
                                    });
                                  },
                                  onChanged: (text) {
                                    _debounce?.cancel();
                                    _debounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () async {
                                        if (text.isEmpty) {
                                          return;
                                        }
                                        List<ChapterInfo> result = [];
                                        var dataDir =
                                            await getApplicationDocumentsDirectory();
                                        for (var chapter in chapterList) {
                                          var chapterContent =
                                              await BookUtils.loadBook(
                                                join(
                                                  dataDir.path,
                                                  chapter.path,
                                                ),
                                              );

                                          List<String> resultKeywordList =
                                              regexpKeyword(
                                                text,
                                                chapterContent,
                                              );
                                          for (var value in resultKeywordList) {
                                            var matchResults =
                                                buildMatchResults(
                                                  line: value,
                                                  keyword: text,
                                                  context: 7,
                                                );

                                            for (var matchResult
                                                in matchResults) {
                                              result.add(
                                                ChapterInfo(
                                                  chapter.title,
                                                  text,
                                                  matchResult.fullLine,
                                                  matchResult.snippet,
                                                  highlightSnippet(
                                                    matchResult.snippet,
                                                    text,
                                                  ),
                                                  chapter.seqNo,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                        setState(() {
                                          searchResultList = result;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 30,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _expanded = false;
                                    });
                                  },
                                  child: const Text('取消'),
                                ),
                              ),
                            ],
                          )
                        : TextField(
                            controller: textFieldController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search, size: 20),
                              prefixIconConstraints: BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              hintText: "搜全文",
                              hintStyle: TextStyle(color: Colors.black26),
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                            onTap: () {
                              setState(() {
                                _expanded = true;
                              });
                            },
                            onChanged: (text) {
                              _debounce?.cancel();
                              _debounce = Timer(
                                const Duration(milliseconds: 300),
                                () async {
                                  if (text.isEmpty) {
                                    return;
                                  }
                                  List<ChapterInfo> result = [];
                                  var dataDir =
                                      await getApplicationDocumentsDirectory();
                                  for (var chapter in chapterList) {
                                    var chapterContent =
                                        await BookUtils.loadBook(
                                          join(dataDir.path, chapter.path),
                                        );

                                    List<String> resultKeywordList =
                                        regexpKeyword(text, chapterContent);
                                    for (var value in resultKeywordList) {
                                      var matchResults = buildMatchResults(
                                        line: value,
                                        keyword: text,
                                        context: 7,
                                      );

                                      for (var matchResult in matchResults) {
                                        result.add(
                                          ChapterInfo(
                                            chapter.title,
                                            text,
                                            matchResult.snippet,
                                            matchResult.fullLine,
                                            highlightSnippet(
                                              matchResult.snippet,
                                              text,
                                            ),
                                            chapter.seqNo,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                  setState(() {
                                    searchResultList = result;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 90,
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _expanded ? 0 : 1,
                child: _expanded
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: chapterList.length,
                        itemBuilder: (context, index) {
                          var chapter = chapterList[index];
                          var chapterTitle = chapter.title;
                          return Container(
                            width: double.infinity,
                            height: 60,
                            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xD6C8C8C8)),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                if (chapter.seqNo == widget.currentSeqNo) {
                                  return;
                                }
                                widget.clickFunc(chapterTitle, chapter.seqNo);
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  chapter.seqNo == widget.currentSeqNo
                                      ? Text(
                                          chapterTitle,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                          ),
                                        )
                                      : Text(chapterTitle, maxLines: 2),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            Positioned(
              top: 50,
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _expanded ? 1 : 0,
                child: _expanded
                    ? ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: searchResultList.length,
                        itemBuilder: (context, index) {
                          var chapterInfo = searchResultList[index];
                          return Container(
                            height: 60,
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xD6C8C8C8)),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                widget.clickSearchResultFunc(chapterInfo);
                              },
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chapterInfo.title,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  chapterInfo.highlightSnippetWidget,
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    scrollController.dispose();
    textFieldController.dispose();
    super.dispose();
  }
}
