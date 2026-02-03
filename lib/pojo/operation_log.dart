import 'package:read_app/pojo/book.dart';
import 'package:read_app/utils/constant.dart';

class OperationLog {
  late String id;
  late String title;
  late int type;
  late String md5;
  late String chapterTitleExp;
  late int currentChapter;
  late int seqNo;
  late int page;
  late int isSecret;
  late double percent;
  late String bookId;
  late int createTime;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'chapter_title_exp': chapterTitleExp,
      'create_time': createTime,
      'seq_no': seqNo,
      'type': type,
      'percent': percent,
      'page': page,
      'md5': md5,
      'current_chapter': currentChapter,
      'book_id': bookId,
      'is_secret': isSecret,
      'id': id
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'title': title,
      'chapterTitleExp': chapterTitleExp,
      'createTime': createTime,
      'seqNo': seqNo,
      'type': type,
      'percent': percent.isInfinite ? 0 : percent,
      'page': page,
      'md5': md5,
      'currentChapter': currentChapter,
      'bookId': bookId,
      'isSecret': isSecret,
      'id': id
    };
  }

  static OperationLog fromMap(Map t) {
    var operationLog = OperationLog();
    operationLog.title = t['title'].toString();
    operationLog.bookId = t['book_id'].toString();
    operationLog.md5 = t['md5'].toString();
    operationLog.createTime = int.parse(t['create_time']?.toString() ?? '0');
    operationLog.id = t['id']?.toString() ?? '0';
    operationLog.seqNo = int.parse(t['seq_no']?.toString() ?? '1');
    operationLog.page = int.parse(t['page']?.toString() ?? '1');
    operationLog.type = int.parse(t['type']?.toString() ?? '1');
    operationLog.percent = double.parse(t['percent']?.toString() ?? '0');
    operationLog.isSecret = int.parse(t['is_secret']?.toString() ?? '0');
    operationLog.currentChapter =
        int.parse(t['current_chapter']?.toString() ?? '0');
    operationLog.chapterTitleExp =
        t['chapter_title_exp']?.toString() ?? Constant.defaultChapterTitleExp;
    return operationLog;
  }

  static OperationLog setOperationLog(Book book, String bookId, int type) {
    OperationLog operationLog = OperationLog();
    operationLog.md5 = book.md5;
    operationLog.type = type;
    operationLog.title = book.title;
    operationLog.currentChapter = book.currentChapter;
    operationLog.bookId = bookId;
    operationLog.createTime = DateTime.now().millisecondsSinceEpoch;
    operationLog.percent = book.percent;
    operationLog.chapterTitleExp = book.chapterTitleExp;
    operationLog.seqNo = book.seqNo;
    operationLog.page = book.page;
    operationLog.isSecret = book.isSecret;
    return operationLog;
  }

  static OperationLog setRegexpOperationLog(type, chapterTitleExp) {
    OperationLog operationLog = OperationLog();
    operationLog.md5 = '';
    operationLog.type = type;
    operationLog.title = '';
    operationLog.currentChapter = 0;
    operationLog.bookId = '';
    operationLog.createTime = DateTime.now().millisecondsSinceEpoch;
    operationLog.percent = 0;
    operationLog.chapterTitleExp = chapterTitleExp;
    operationLog.seqNo = 0;
    operationLog.page = 0;
    operationLog.isSecret = 0;
    return operationLog;
  }

  @override
  String toString() {
    return title.toString();
  }
}
