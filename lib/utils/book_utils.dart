import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/chapter.dart';
import 'package:read_app/pojo/operation_log.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/file_utils.dart';

import 'db.dart';

class BookUtils {
  static Future<String> loadBook(String path) async {
    return await File(path).readAsString();
  }

  static String loadBookSync(String path) {
    return File(path).readAsStringSync();
  }

  static List<String> splitChapterContent(String text, String exp) {
    List<String> textList = [];

    RegExp regExp = RegExp(exp, multiLine: true);
    Iterable<Match> matches = regExp.allMatches(text);

    List<int> startList = [];

    for (Match match in matches) {
      startList.add(match.start);
    }

    if (startList.isNotEmpty && startList[0] != 0) {
      startList.insert(0, 0);
    }

    if (startList.isNotEmpty) {
      for (int i = 0; i < startList.length; i++) {
        String content;

        if (i == startList.length - 1) {
          content = text.substring(startList[i], text.length).trim();
        } else {
          content = text.substring(startList[i], startList[i + 1]).trim();
        }

        while (content.length > Constant.defaultChapterContentMaxLength) {
          var text =
              content.substring(0, Constant.defaultChapterContentMaxLength);
          textList.add(text.trim());

          content = content.substring(
              Constant.defaultChapterContentMaxLength, content.length);
        }

        if (content.isNotEmpty) {
          textList.add(content.trim());
        }
      }
    } else {
      while (text.length > Constant.defaultChapterContentMaxLength) {
        var content =
            text.substring(0, Constant.defaultChapterContentMaxLength);
        textList.add(content.trim());

        text = text.substring(
            Constant.defaultChapterContentMaxLength, text.length);
      }

      if (text.isNotEmpty) {
        textList.add(text.trim());
      }
    }

    return textList;
  }

  static List<String> getChapterTitle(List<String> chapterContentList) {
    List<String> textList = [];

    for (var value in chapterContentList) {
      if (value.isNotEmpty) {
        var contentList = value.split('\n');

        for (var i = 0; i < contentList.length; i++) {
          if (contentList[i].trim().isNotEmpty) {
            var title = contentList[i].trim();
            if (title.length > Constant.defaultChapterTitleMaxLength) {
              title = title.substring(0, Constant.defaultChapterTitleMaxLength);
            }
            textList.add(title);
            break;
          }
        }
      } else {
        textList.add('');
      }
    }

    return textList;
  }

  static Future<void> saveChapter(
      String relativeDirPath,
      String absoluteDirPath,
      List<String> chapterContentList,
      String bookId) async {
    List<String> chapterTitleList = getChapterTitle(chapterContentList);

    final directory = Directory(join(absoluteDirPath, 'chapter'));

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    for (int i = 0; i < chapterContentList.length; i++) {
      var chapterTitle = chapterTitleList[i];
      if (chapterTitle.isEmpty) {
        chapterTitle = '开始';
      }
      var chapterPath = join(directory.path, '$i.txt');

      Chapter chapter = Chapter()
        ..path = join(relativeDirPath, 'chapter', '$i.txt')
        ..updateTime = DateTime.now().millisecondsSinceEpoch
        ..createTime = DateTime.now().millisecondsSinceEpoch
        ..title = chapterTitle
        ..seqNo = i
        ..cover = ''
        ..bookId = bookId
        ..type = Constant.chapterType
        ..percent = 0
        ..page = 0;

      await DatabaseHelper.db.insertChapter(chapter);

      await File(chapterPath).writeAsString(chapterContentList[i]);
    }
  }

  static Future<void> changeChapterTitleExp(
      Book book, String chapterTitleExp) async {
    var directory = await getApplicationDocumentsDirectory();

    List<Chapter> chapterList =
        await DatabaseHelper.db.getChapterByBookId(book.id);

    for (var i = 0; i < chapterList.length; i++) {
      var chapter = chapterList[i];
      await FileUtils.deletePath(join(directory.path, chapter.path));
    }

    await DatabaseHelper.db.deleteChapterByBookId(book.id);

    book.page = 0;
    book.percent = 0.0;
    book.chapterTitleExp = chapterTitleExp;
    await DatabaseHelper.db.updateById(book);

    var bookPath = book.path;

    var absoluteBookPath = Directory(join(directory.path, bookPath));

    var relativeDirPath =
        join('read', 'book', basename(absoluteBookPath.parent.path));

    var content = await BookUtils.loadBook(absoluteBookPath.path);
    var chapterContentList =
        BookUtils.splitChapterContent(content, chapterTitleExp);
    await BookUtils.saveChapter(relativeDirPath, absoluteBookPath.parent.path,
        chapterContentList, book.id);
  }

  static Future<void> changeChapter(
      Book book, String chapterTitleExp) async {
    var directory = await getApplicationDocumentsDirectory();

    List<Chapter> chapterList =
    await DatabaseHelper.db.getChapterByBookId(book.id);

    for (var i = 0; i < chapterList.length; i++) {
      var chapter = chapterList[i];
      await FileUtils.deletePath(join(directory.path, chapter.path));
    }

    await DatabaseHelper.db.deleteChapterByBookId(book.id);

    book.page = book.page;
    book.percent = book.percent;
    book.chapterTitleExp = chapterTitleExp;
    await DatabaseHelper.db.updateById(book);

    var bookPath = book.path;

    var absoluteBookPath = Directory(join(directory.path, bookPath));

    var relativeDirPath =
    join('read', 'book', basename(absoluteBookPath.parent.path));

    var content = await BookUtils.loadBook(absoluteBookPath.path);
    var chapterContentList =
    BookUtils.splitChapterContent(content, chapterTitleExp);
    await BookUtils.saveChapter(relativeDirPath, absoluteBookPath.parent.path,
        chapterContentList, book.id);
  }

  static Future<void> deleteBooks(List<String> checkedList) async {
    var dataDir = await getApplicationDocumentsDirectory();

    var books = await DatabaseHelper.db.getBooksByIds(checkedList);

    for (var i = 0; i < books.length; i++) {
      var book = books[i];
      if (book.type == Constant.bookType) {
        var bookPath = join(dataDir.path, Directory(book.path).parent.path);
        if (bookPath != dataDir.path) {
          await FileUtils.deletePath(bookPath);
          await DatabaseHelper.db.deleteChapterByBookId(book.id);
          await DatabaseHelper.db.deleteById(book.id);

          await DatabaseHelper.db.deleteOperationLogByBookId(book.id);

          OperationLog operationLog = OperationLog.setOperationLog(book, book.id, Constant.operationDeleteType);
          DatabaseHelper.db.insertOperationLog(operationLog);
        }
      } else if (book.type == Constant.directoryType) {
        await DatabaseHelper.db.deleteDirectory(book.id, dataDir.path);
      } else if (book.type == Constant.outSideType) {
        await DatabaseHelper.db.deleteById(book.id);
      } else {
        var bookPath = join(dataDir.path, book.path);
        await FileUtils.deletePath(bookPath);
        await DatabaseHelper.db.deleteById(book.id);

        if (book.type == Constant.pdfType) {
          await DatabaseHelper.db.deleteOperationLogByBookId(book.id);
          OperationLog operationLog = OperationLog.setOperationLog(book, book.id, Constant.operationDeleteType);
          DatabaseHelper.db.insertOperationLog(operationLog);
        }
      }
    }
  }

  static Future<void> updateBooksSecret(List<String> checkedList, int isSecret) async {
    var books = await DatabaseHelper.db.getBooksByIds(checkedList);
    List<Book> bookList = [];
    for (var i = 0; i < books.length; i++) {
      var book = books[i];
      bookList.add(book);
      if (book.type == Constant.directoryType) {
        await DatabaseHelper.db.getBooksByDirectoryId(bookList, book.id);
      }
    }

    for (var i = 0; i <bookList.length; i++) {
      var book = bookList[i];
      book.isSecret = isSecret;
      await DatabaseHelper.db.updateById(book);
      if (book.type == Constant.bookType || book.type == Constant.pdfType) {
        OperationLog operationLog = OperationLog.setOperationLog(book, book.id, Constant.operationUpdateType);
        await DatabaseHelper.db.insertOperationLog(operationLog);
      }
    }
  }
}
