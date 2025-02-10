import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/sortable_grid_view.dart';

class Book implements HasId {
  @override
  late String id;
  late String title;
  late String path;
  late String chapterTitleExp;
  late String cover;
  late int seqNo;
  late int page;
  late int type;
  late int currentChapter;
  late String parentId;
  late double percent;
  late int createTime;
  late int updateTime;
  late String assetDir;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'path': path,
      'chapter_title_exp': chapterTitleExp,
      'create_time': createTime,
      'update_time': updateTime,
      'seq_no': seqNo,
      'type': type,
      'cover': cover,
      'percent': percent,
      'parent_id': parentId,
      'page': page,
      'current_chapter': currentChapter,
      'id': id
    };
  }

  static Book fromMap(Map t) {
    var book = Book();
    book.title = t['title'].toString();
    book.path = t['path'].toString();
    book.cover = t['cover'].toString();
    book.parentId = t['parent_id'].toString();
    book.createTime = int.parse(t['create_time']?.toString() ?? '0');
    book.updateTime = int.parse(t['update_time']?.toString() ?? '0');
    book.id = t['id']?.toString() ?? '0';
    book.seqNo = int.parse(t['seq_no']?.toString() ?? '1');
    book.page = int.parse(t['page']?.toString() ?? '1');
    book.type = int.parse(t['type']?.toString() ?? '1');
    book.currentChapter = int.parse(t['current_chapter']?.toString() ?? '0');
    book.percent = double.parse(t['percent']?.toString() ?? '0');
    book.chapterTitleExp = t['chapter_title_exp']?.toString() ?? Constant.defaultChapterTitleExp;
    book.assetDir = '';
    return book;
  }

  @override
  String toString() {
    return seqNo.toString();
  }
  
}