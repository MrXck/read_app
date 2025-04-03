import 'package:flutter/material.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/chapter.dart';

typedef ClickFunc = void Function(String chapterTitle, int pageNum);

class ReadChapterList extends StatelessWidget {
  final ClickFunc clickFunc;
  final Book book;
  final int currentSeqNo;
  final List<Chapter> chapterList;

  const ReadChapterList(
      {super.key,
      required this.book,
      required this.currentSeqNo,
      required this.chapterList,
      required this.clickFunc});

  @override
  Widget build(BuildContext context) {
    var scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var offset = (currentSeqNo - 2) * 60.0;
      scrollController.animateTo(offset,
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    });

    return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
                top: 60,
                left: 0,
                right: 0,
                bottom: 0,
                child: ListView.builder(
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
                              bottom: BorderSide(color: Color(0xD6C8C8C8))),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (chapter.seqNo == currentSeqNo) {
                              return;
                            }

                            clickFunc(chapterTitle, chapter.seqNo);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              currentSeqNo == index
                                  ? Text(
                                      chapterTitle,
                                      style:
                                          const TextStyle(color: Colors.blue),
                                    )
                                  : Text(chapterTitle),
                            ],
                          ),
                        ),
                      );
                    }))
          ],
        ));
  }
}
