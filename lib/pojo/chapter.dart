class Chapter {
  late String id;
  late String title;
  late String path;
  late String cover;
  late int seqNo;
  late int page;
  late int type;
  late String bookId;
  late double percent;
  late int createTime;
  late int updateTime;
  late String assetDir;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'path': path,
      'create_time': createTime,
      'update_time': updateTime,
      'seq_no': seqNo,
      'type': type,
      'cover': cover,
      'percent': percent,
      'book_id': bookId,
      'page': page,
      'id': id
    };
  }

  static Chapter fromMap(Map t) {
    var chapter = Chapter();
    chapter.title = t['title'].toString();
    chapter.path = t['path'].toString();
    chapter.cover = t['cover'].toString();
    chapter.bookId = t['book_id'].toString();
    chapter.createTime = int.parse(t['create_time']?.toString() ?? '0');
    chapter.updateTime = int.parse(t['update_time']?.toString() ?? '0');
    chapter.id = t['id']?.toString() ?? '0';
    chapter.seqNo = int.parse(t['seq_no']?.toString() ?? '1');
    chapter.page = int.parse(t['page']?.toString() ?? '1');
    chapter.type = int.parse(t['type']?.toString() ?? '1');
    chapter.percent = double.parse(t['percent']?.toString() ?? '0');
    chapter.assetDir = '';
    return chapter;
  }
  
}