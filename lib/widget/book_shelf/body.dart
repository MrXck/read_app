import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/operation_log.dart';
import 'package:read_app/tab/book_shelf.dart';
import 'package:read_app/utils/book_utils.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/loading_utils.dart';
import 'package:read_app/utils/random.dart';
import 'package:read_app/utils/sortable_grid_view.dart';
import 'package:read_app/utils/value_notifier_utils.dart';
import 'package:read_app/widget/book_shelf/book.dart';
import 'package:share_plus/share_plus.dart';

class BookShelfBody extends StatefulWidget {
  final Data data;

  const BookShelfBody({super.key, required this.data});

  @override
  State<BookShelfBody> createState() => _BookShelfBodyState();
}

class _BookShelfBodyState extends State<BookShelfBody> {
  List<Book> books = [];
  bool isChange = false;
  ListValueNotifier<String> checkedList = ListValueNotifier<String>([]);
  String parentId = '';
  ValueNotifier<List<Book>> breadList = ValueNotifier<List<Book>>([
    Book.fromMap({'id': '', 'title': '根目录'}),
  ]);
  ValueNotifier<int> count = ValueNotifier<int>(0);
  String sortString = '';
  bool isReady = false;
  double bottomChangeHeight = 100;
  double topChangeHeight = 70;

  void refresh() async {
    var value = await DatabaseHelper.db.getBookByParentIdAndSort(
      parentId,
      sortString,
    );

    final dir = await getApplicationDocumentsDirectory();
    for (var i = 0; i < value.length; i++) {
      var book = value[i];
      book.assetDir = dir.path;
    }

    setState(() {
      books = [];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        books.addAll(value);
      });
    });
  }

  @override
  void initState() {
    widget.data.refresh = refresh;
    widget.data.updateSort = () {
      if (Constant.sortList.contains(sortString)) {
        var index = Constant.sortList.indexOf(sortString) + 1;
        sortString = Constant
            .sortList[index + 1 >= Constant.sortList.length ? 0 : index + 1];
      } else {
        sortString = Constant.sortList[0];
      }
      refresh();
    };
    widget.data.addDirectory = () async {
      newDialog();
    };
    widget.data.routeBack = () async {
      if (breadList.value.length == 1) {
        Get.back();
        return true;
      }

      breadList.value.removeLast();

      updateParentId(breadList.value.last.id);
      return false;
    };
    DatabaseHelper.db.getBookByParentIdAndSort(parentId, sortString).then((
      value,
    ) async {
      final dir = await getApplicationDocumentsDirectory();
      for (var i = 0; i < value.length; i++) {
        var book = value[i];
        book.assetDir = dir.path;
      }

      setState(() {
        books = value;
      });
    });
    Timer(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => isReady = true);
    });
    super.initState();
  }

  Future<void> moveDialog(width, height) async {
    var directories = await DatabaseHelper.db.getDirectoryByPatentId('');
    var li = ValueNotifier<List<Book>>(
      directories.where((item) => !checkedList.contains(item.id)).toList(),
    );
    var breadList = ValueNotifier<List<Book>>([
      Book.fromMap({'id': '', 'title': '根目录'}),
    ]);

    var nowClick = '';
    Get.dialog(
      AlertDialog(
        title: const Text('移动到'),
        content: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: breadList,
              builder: (context, value, child) {
                List<Widget> widgetList = [];
                for (var i = 0; i < value.length; i++) {
                  if (i != 0) {
                    widgetList.add(const Text(' / '));
                  }
                  widgetList.add(
                    InkWell(
                      onTap: () async {
                        nowClick = value[i].id;

                        var directories = await DatabaseHelper.db
                            .getDirectoryByPatentId(value[i].id);

                        var checkedBreadList = <Book>[
                          Book.fromMap({'id': '', 'title': '根目录'}),
                        ];
                        for (var i = 0; i < breadList.value.length; i++) {
                          if (breadList.value[i].id == value[i].id) {
                            break;
                          }
                          checkedBreadList.add(breadList.value[i]);
                        }
                        breadList.value = checkedBreadList;
                        li.value = directories;
                      },
                      child: Text(value[i].title),
                    ),
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: widgetList,
                );
              },
            ),
            SizedBox(
              width: width,
              height: height - 220,
              child: ValueListenableBuilder(
                valueListenable: li,
                builder: (context, value, child) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, int index) {
                      return ListTile(
                        title: Text(value[index].title),
                        onTap: () async {
                          nowClick = value[index].id;
                          var directories = await DatabaseHelper.db
                              .getDirectoryByPatentId(value[index].id);

                          directories
                              .where((item) => !checkedList.contains(item.id))
                              .toList();

                          var checkedBreadList = <Book>[];
                          for (var i = 0; i < breadList.value.length; i++) {
                            checkedBreadList.add(breadList.value[i]);
                          }
                          checkedBreadList.add(value[index]);

                          breadList.value = checkedBreadList;
                          li.value = directories;
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              for (var i = 0; i < checkedList.value.length; i++) {
                await DatabaseHelper.db.updateParentIdById(
                  checkedList.value[i],
                  nowClick,
                );
              }

              var value = await DatabaseHelper.db.getBookByParentIdAndSort(
                parentId,
                sortString,
              );
              final dir = await getApplicationDocumentsDirectory();
              for (var i = 0; i < value.length; i++) {
                var book = value[i];
                book.assetDir = dir.path;
              }
              count.value = 0;
              setState(() {
                checkedList.clear();
                books.clear();
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  books.addAll(value);
                });
              });

              Get.back(); // 关闭对话框
            },
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            // 关闭对话框
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> newDialog() async {
    final TextEditingController controller = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('新增分组'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '请输入分组名称'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 处理输入内容
              String inputValue = controller.text;

              var li = await DatabaseHelper.db.getDirectoryByTitle(inputValue);
              if (li.isNotEmpty) {
                Get.snackbar('提示', '分组名称已存在');
                return;
              }

              Book book = Book();
              book.percent = 0;
              book.page = 0;
              book.chapterTitleExp = '';
              book.title = inputValue;
              book.updateTime = DateTime.now().millisecondsSinceEpoch;
              book.createTime = DateTime.now().millisecondsSinceEpoch;
              book.seqNo = 1;
              book.parentId = parentId;
              book.path = '';
              book.type = Constant.directoryType;
              book.cover = "";
              book.md5 = "";
              book.currentChapter = 0;
              book.isSecret = Constant.publicType;
              await DatabaseHelper.db.insert(book);
              var value = await DatabaseHelper.db.getBookByParentIdAndSort(
                parentId,
                sortString,
              );
              final dir = await getApplicationDocumentsDirectory();
              for (var i = 0; i < value.length; i++) {
                var book = value[i];
                book.assetDir = dir.path;
              }
              setState(() {
                books.clear();
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  books.addAll(value);
                });
              });
              Get.back(); // 关闭对话框
            },
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () => Get.back(), // 关闭对话框
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> updateDialog() async {
    var id = checkedList.value[0];
    var book = await DatabaseHelper.db.getById(id);
    final TextEditingController controller = TextEditingController();
    controller.text = book.title;
    Get.dialog(
      AlertDialog(
        title: const Text('修改名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '请输入名称'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 处理输入内容
              String inputValue = controller.text;

              var li = await DatabaseHelper.db.getDirectoryByTitleAndNotMe(
                inputValue,
                id,
              );
              if (li.isNotEmpty) {
                Get.snackbar('提示', '分组名称已存在');
                return;
              }

              book.title = inputValue;
              await DatabaseHelper.db.updateById(book);

              OperationLog operationLog = OperationLog.setOperationLog(
                book,
                book.id,
                Constant.operationUpdateType,
              );
              DatabaseHelper.db.insertOperationLog(operationLog);

              var value = await DatabaseHelper.db.getBookByParentIdAndSort(
                parentId,
                sortString,
              );
              final dir = await getApplicationDocumentsDirectory();
              for (var i = 0; i < value.length; i++) {
                var book = value[i];
                book.assetDir = dir.path;
              }
              setState(() {
                books.clear();
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  books.addAll(value);
                });
              });
              Get.back(); // 关闭对话框
            },
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () => Get.back(), // 关闭对话框
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> updateParentId(String id) async {
    setState(() {
      parentId = id;
      widget.data.parentId = parentId;
    });

    var li = await DatabaseHelper.db.getBookByParentIdAndSort(
      parentId,
      sortString,
    );
    final dir = await getApplicationDocumentsDirectory();
    for (var i = 0; i < li.length; i++) {
      var book = li[i];
      book.assetDir = dir.path;
    }
    setState(() {
      books.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        books.addAll(li);
      });
    });
    var checkedBreadList = <Book>[];
    for (var i = 0; i < breadList.value.length; i++) {
      checkedBreadList.add(breadList.value[i]);
      if (breadList.value[i].id == parentId) {
        break;
      }
    }
    breadList.value = checkedBreadList;
  }

  Future<void> updateCover() async {
    String id = checkedList.value.first;
    var book = await DatabaseHelper.db.getById(id);

    var image = await FilePicker.pickFiles(
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );

    if (image == null) {
      return;
    }

    var file = File(image.files.single.path!);

    final dir = await getApplicationDocumentsDirectory();

    var path = join(
      File(book.path).parent.path,
      '${generateRandomString(32)}.${FileUtils.getFileExtension(image.files.single.path!)}',
    );

    await file.copy(join(dir.path, path));
    book.cover = path;
    await DatabaseHelper.db.updateById(book);
    updateParentId(parentId);
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var defaultItemWidth = 110.0;
    var defaultItemHeight = 230.0;
    var defaultItemLeftRightPadding = 10.0;
    var defaultItemTopBottomPadding = 3.5;

    var calcWidth = (width - 6 * defaultItemLeftRightPadding) / 3 - (20 / 3);

    var itemWidth = calcWidth > defaultItemWidth ? defaultItemWidth : calcWidth;
    var itemHeight = itemWidth * (defaultItemHeight / defaultItemWidth);
    if (!isReady) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: height - 60,
      width: double.infinity,
      child: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: breadList,
            builder: (context, value, child) {
              List<Widget> widgetList = [];
              for (var i = 0; i < value.length; i++) {
                if (i != 0) {
                  widgetList.add(const Text(' / '));
                }
                widgetList.add(
                  InkWell(
                    onTap: () async {
                      updateParentId(value[i].id);
                    },
                    child: Text(value[i].title),
                  ),
                );
              }
              return Positioned(
                top: 50,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: widgetList,
                  ),
                ),
              );
            },
          ),
          books.isEmpty
              ? Container()
              : Positioned(
                  top: topChangeHeight,
                  left: 10,
                  right: 10,
                  bottom: isChange ? bottomChangeHeight : 0,
                  child: SortableGridView<Book>(
                    books,
                    itemBuilder: (context, data) {
                      return BookShelfBook(
                        data,
                        isChange,
                        checkedList,
                        (Book book, bool isChecked) {
                          if (isChecked) {
                            if (!checkedList.contains(book.id)) {
                              checkedList.add(book.id);
                            }
                          } else {
                            checkedList.remove(book.id);
                          }
                          count.value = checkedList.value.length;
                        },
                        () async {
                          Timer(const Duration(milliseconds: 100), () async {
                            var value = await DatabaseHelper.db
                                .getBookByParentIdAndSort(parentId, sortString);

                            final dir =
                                await getApplicationDocumentsDirectory();
                            for (var i = 0; i < value.length; i++) {
                              var book = value[i];
                              book.assetDir = dir.path;
                            }

                            setState(() {
                              books = [];
                            });

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                books.addAll(value);
                              });
                            });
                          });
                        },
                        (String id) async {
                          var book = await DatabaseHelper.db.getById(id);
                          setState(() {
                            parentId = id;
                            widget.data.parentId = parentId;
                          });
                          var value = await DatabaseHelper.db
                              .getBookByParentIdAndSort(parentId, sortString);

                          final dir = await getApplicationDocumentsDirectory();
                          for (var i = 0; i < value.length; i++) {
                            var book = value[i];
                            book.assetDir = dir.path;
                          }

                          setState(() {
                            books = [];
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              books.addAll(value);
                            });
                          });

                          var checkedBreadList = <Book>[];
                          for (var i = 0; i < breadList.value.length; i++) {
                            checkedBreadList.add(breadList.value[i]);
                          }
                          checkedBreadList.add(book);
                          breadList.value = checkedBreadList;
                        },
                        itemHeight - 74,
                      );
                    },
                    canAccept: (oldIndex, newIndex) {
                      var accept = oldIndex != newIndex;
                      return accept;
                    },
                    itemWidth: itemWidth,
                    itemHeight: itemHeight + 4,
                    itemMargin: const [0, 0, 0, 0],
                    itemPadding: [
                      defaultItemLeftRightPadding,
                      defaultItemTopBottomPadding,
                      defaultItemLeftRightPadding,
                      defaultItemTopBottomPadding,
                    ],
                    dragEnd: (List dataList) async {
                      var bookList = dataList.cast<Book>();
                      var updateTime = DateTime.now().millisecondsSinceEpoch;
                      for (var i = 0; i < bookList.length; i++) {
                        bookList[i].seqNo = i;
                        bookList[i].updateTime = updateTime - i;
                      }
                      DatabaseHelper.db.updateAll(bookList);
                      bookList.sort((Book a, Book b) {
                        return a.seqNo.compareTo(b.seqNo);
                      });
                    },
                    dragStart: () {
                      setState(() {
                        isChange = true;
                      });
                    },
                    scrollPaddingBottom: bottomChangeHeight,
                    checkWidget: (id) {
                      if (!checkedList.contains(id)) {
                        checkedList.add(id);
                      } else {
                        checkedList.remove(id);
                      }
                      count.value = checkedList.value.length;
                    },
                    isChange: isChange,
                    widgetMarginTop: topChangeHeight,
                  ),
                ),
          Visibility(
            visible: isChange,
            child: Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 50,
              child: Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () {
                        var checked = books.map((item) {
                          return item.id;
                        }).toList();
                        setState(() {
                          checkedList.value = checked;
                          count.value = checkedList.value.length;
                        });
                      },
                      child: const Text('全选'),
                    ),
                    ValueListenableBuilder(
                      valueListenable: count,
                      builder: (context, value, child) {
                        return Text('已选择 $value 本');
                      },
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          isChange = false;
                        });
                        checkedList.clear();
                        count.value = 0;
                      },
                      child: const Text('完成'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Visibility(
            visible: isChange,
            child: Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomChangeHeight,
              child: Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () async {
                            await newDialog();
                          },
                          child: const Text('新增分组'),
                        ),
                        ValueListenableBuilder(
                          valueListenable: count,
                          builder: (context, value, child) {
                            if (value == 0) {
                              return const Text(
                                '删除',
                                style: TextStyle(color: Color(0xB2C4C4C4)),
                              );
                            } else {
                              return InkWell(
                                onTap: () async {
                                  Get.defaultDialog(
                                    title: '提示',
                                    textConfirm: '确认',
                                    textCancel: '取消',
                                    content: const Text('确认要删除吗？'),
                                    onConfirm: () async {
                                      Get.back();
                                      LoadingUtils.showLoading(tip: '删除中');
                                      var dataDir =
                                          await getApplicationDocumentsDirectory();
                                      try {
                                        await BookUtils.deleteBooks(
                                          checkedList.value,
                                        );
                                      } catch (e) {
                                        Get.snackbar('错误', e.toString());
                                      } finally {
                                        LoadingUtils.hideLoading();
                                      }

                                      var value = await DatabaseHelper.db
                                          .getBookByParentIdAndSort(
                                            parentId,
                                            sortString,
                                          );

                                      for (var i = 0; i < value.length; i++) {
                                        var book = value[i];
                                        book.assetDir = dataDir.path;
                                      }

                                      setState(() {
                                        books = [];
                                      });

                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            setState(() {
                                              isChange = false;
                                              checkedList.clear();
                                              count.value = 0;
                                              books.addAll(value);
                                            });
                                          });
                                    },
                                  );
                                },
                                child: const Text(
                                  '删除',
                                  style: TextStyle(color: Colors.red),
                                ),
                              );
                            }
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: count,
                          builder: (context, value, child) {
                            if (value == 0) {
                              return const Text(
                                '移动至',
                                style: TextStyle(color: Color(0xB2C4C4C4)),
                              );
                            } else {
                              return InkWell(
                                onTap: () async {
                                  await moveDialog(width, height);
                                },
                                child: const Text('移动至'),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: count,
                            builder: (context, value, child) {
                              if (value != 1) {
                                return const Text(
                                  '编辑名称',
                                  style: TextStyle(color: Color(0xB2C4C4C4)),
                                );
                              } else {
                                return InkWell(
                                  onTap: () async {
                                    await updateDialog();
                                  },
                                  child: const Text('编辑名称'),
                                );
                              }
                            },
                          ),
                          ValueListenableBuilder(
                            valueListenable: count,
                            builder: (context, value, child) {
                              if (value != 1) {
                                return const Text(
                                  '编辑封面',
                                  style: TextStyle(color: Color(0xB2C4C4C4)),
                                );
                              } else {
                                return InkWell(
                                  onTap: () async {
                                    await updateCover();
                                  },
                                  child: const Text('编辑封面'),
                                );
                              }
                            },
                          ),
                          ValueListenableBuilder(
                            valueListenable: count,
                            builder: (context, value, child) {
                              if (value != 1) {
                                return const Text(
                                  '分享',
                                  style: TextStyle(color: Color(0xB2C4C4C4)),
                                );
                              } else {
                                return InkWell(
                                  onTap: () async {
                                    String id = checkedList.value.first;
                                    var book = await DatabaseHelper.db.getById(
                                      id,
                                    );
                                    if (book.type != Constant.bookType) {
                                      Get.snackbar('提示', '只有文本才可以分享');
                                      return;
                                    }
                                    var dir =
                                        await getApplicationDocumentsDirectory();

                                    await FileUtils.shareFile(
                                      book.title,
                                      await File(
                                        join(dir.path, book.path),
                                      ).readAsBytes(),
                                      FileUtils.getFileExtension(book.path),
                                    );
                                  },
                                  child: const Text('分享'),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: count,
                            builder: (context, value, child) {
                              if (value != 1) {
                                return const Text(
                                  '导出',
                                  style: TextStyle(color: Color(0xB2C4C4C4)),
                                );
                              } else {
                                return InkWell(
                                  onTap: () async {
                                    String id = checkedList.value.first;
                                    var dir =
                                        await getApplicationDocumentsDirectory();

                                    try {
                                      var tip = LoadingUtils.showLoading(
                                        tip: '导出中',
                                      );
                                      await FileUtils.compressSpecifiedDirectoryByParentId(
                                        id,
                                        join(dir.path, 'read'),
                                        join(dir.path, 'read_book.zip'),
                                        [
                                          Constant.bookType,
                                          Constant.directoryType,
                                          Constant.comicType,
                                          Constant.mediaType,
                                          Constant.outSideType,
                                          Constant.pdfType,
                                        ],
                                        onProgress: (progress) {
                                          tip.value =
                                              '导出中: ${(progress * 100).toStringAsFixed(2)}%';
                                        },
                                        onDone: (outputPath) async {
                                          // ✅ 分享
                                          final file = File(outputPath);
                                          if (await file.exists()) {
                                            await Share.shareXFiles([
                                              XFile(outputPath),
                                            ], text: '导出.zip');
                                            // 延迟清理
                                            // Future.delayed(const Duration(seconds: 5), () {
                                            //   if (File(outputPath).existsSync()) {
                                            //     File(outputPath).deleteSync();
                                            //   }
                                            // });
                                          }
                                        },
                                        onError: (String error) {},
                                      );
                                    } catch (e) {
                                      Get.snackbar('错误', e.toString());
                                    } finally {
                                      LoadingUtils.hideLoading();
                                    }
                                  },
                                  child: const Text('导出'),
                                );
                              }
                            },
                          ),
                          ValueListenableBuilder(
                            valueListenable: count,
                            builder: (context, value, child) {
                              if (value == 0) {
                                return const Text(
                                  '设为私密',
                                  style: TextStyle(color: Color(0xB2C4C4C4)),
                                );
                              } else {
                                return InkWell(
                                  onTap: () async {
                                    await BookUtils.updateBooksSecret(
                                      checkedList.value,
                                      Constant.secretType,
                                    );
                                    var value = await DatabaseHelper.db
                                        .getBookByParentIdAndSort(
                                          parentId,
                                          sortString,
                                        );
                                    final dir =
                                        await getApplicationDocumentsDirectory();
                                    for (var i = 0; i < value.length; i++) {
                                      var book = value[i];
                                      book.assetDir = dir.path;
                                    }
                                    count.value = 0;
                                    setState(() {
                                      checkedList.clear();
                                      books.clear();
                                    });

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          setState(() {
                                            books.addAll(value);
                                          });
                                        });
                                  },
                                  child: const Text('设为私密'),
                                );
                              }
                            },
                          ),
                          ValueListenableBuilder(
                            valueListenable: count,
                            builder: (context, value, child) {
                              if (value == 0) {
                                return const Text(
                                  '设为公开',
                                  style: TextStyle(color: Color(0xB2C4C4C4)),
                                );
                              } else {
                                return InkWell(
                                  onTap: () async {
                                    await BookUtils.updateBooksSecret(
                                      checkedList.value,
                                      Constant.publicType,
                                    );
                                    var value = await DatabaseHelper.db
                                        .getBookByParentIdAndSort(
                                          parentId,
                                          sortString,
                                        );
                                    final dir =
                                        await getApplicationDocumentsDirectory();
                                    for (var i = 0; i < value.length; i++) {
                                      var book = value[i];
                                      book.assetDir = dir.path;
                                    }
                                    count.value = 0;
                                    setState(() {
                                      checkedList.clear();
                                      books.clear();
                                    });

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          setState(() {
                                            books.addAll(value);
                                          });
                                        });
                                  },
                                  child: const Text('设为公开'),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
