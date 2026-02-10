import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/utils/constant.dart';

typedef Click = void Function(Book book, bool isChecked);
typedef Update = void Function();
typedef UpdateParentId = void Function(String parentId);

class BookShelfBook extends StatefulWidget {
  final Book book;
  final List checkedList;
  final bool isChange;
  final double itemHeight;
  final Click click;
  final Update update;
  final UpdateParentId updateParentId;

  const BookShelfBook(
    this.book,
    this.isChange,
    this.checkedList,
    this.click,
    this.update,
    this.updateParentId,
    this.itemHeight, {
    super.key,
  });

  @override
  State<BookShelfBook> createState() => _BookShelfBookState();
}

class _BookShelfBookState extends State<BookShelfBook>
    with SingleTickerProviderStateMixin {
  late bool isSelect = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isSelect = widget.checkedList.contains(widget.book.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
              width: double.infinity,
              height: widget.itemHeight,
              decoration: BoxDecoration(
                  color: widget.book.isSecret == Constant.secretType ? const Color(0xCBB3B3FF) : Colors.white,
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(8)),
              child: GestureDetector(
                onTap: () async {
                  if (widget.isChange) {
                    setState(() {
                      isSelect = !isSelect;
                      widget.click(widget.book, isSelect);
                    });
                  } else {
                    if (widget.book.type == Constant.bookType) {
                      await Get.toNamed('/read', arguments: widget.book);
                      widget.update();
                    } else if (widget.book.type == Constant.comicType) {
                      await Get.toNamed('/comic', arguments: widget.book);
                      widget.update();
                    } else if (widget.book.type == Constant.mediaType) {
                      await Get.toNamed('/video', arguments: widget.book);
                      widget.update();
                    } else if (widget.book.type == Constant.outSideType) {
                      await Get.toNamed('/read_outside',
                          arguments: {'book': widget.book, 'outSideBook': null});
                      widget.update();
                    } else if (widget.book.type == Constant.directoryType) {
                      widget.updateParentId(widget.book.id);
                    } else if (widget.book.type == Constant.pdfType) {
                      await Get.toNamed('/pdf', arguments: widget.book);
                      widget.update();
                    }
                  }
                },
                child: widget.book.cover.isEmpty
                    ? Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12, width: 1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(widget.book.title),
                      )
                    : Image(
                        fit: BoxFit.fill,
                        image: FileImage(File(
                            join(widget.book.assetDir, widget.book.cover)))),
              ),
            ),
            Visibility(
                visible: widget.isChange,
                child: Positioned(
                    right: 10,
                    bottom: 10,
                    width: 10,
                    height: 10,
                    child: Checkbox(value: isSelect, onChanged: (value) {
                      setState(() {
                        isSelect = !isSelect;
                        widget.click(widget.book, isSelect);
                      });
                    }))),
          ],
        ),
        const SizedBox(
          height: 6,
        ),
        Text(
          widget.book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 6,
        ),
        widget.book.type == Constant.directoryType
            ? const Text(
                '文件夹',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black45, fontSize: 14),
              )
            : Text(
                '已看${widget.book.percent.toStringAsFixed(2)}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black45, fontSize: 14),
              )
      ],
    );
  }
}
