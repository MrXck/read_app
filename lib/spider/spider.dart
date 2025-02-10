import 'dart:convert';

class BookSource {
  late String id;
  late String baseUrl;
  late String name;
  late String searchUrl;
  late Map<String, dynamic> searchInfo;
  late Map<String, dynamic> chapterInfo;
  late Map<String, dynamic> chapterContentInfo;
  late List<String> replaceContentList;
  late int startChapterIndex;

  late int enable;

  late String replaceKeyword = '####keyword####';

  Map<String, dynamic> toMap() {
    var jsonEncoder = const JsonEncoder();
    return {
      'id': id,
      'base_url': baseUrl,
      'name': name,
      'search_url': searchUrl,
      'search_info': jsonEncoder.convert(searchInfo),
      'chapter_info': jsonEncoder.convert(chapterInfo),
      'chapter_content_info': jsonEncoder.convert(chapterContentInfo),
      'start_chapter_index': startChapterIndex,
      'replace_content_list': jsonEncoder.convert(replaceContentList),
      'enable': enable,
    };
  }

  Map<String, dynamic> toExportMap() {
    return {
      'base_url': baseUrl,
      'name': name,
      'search_url': searchUrl,
      'search_info': searchInfo,
      'chapter_info': chapterInfo,
      'chapter_content_info': chapterContentInfo,
      'start_chapter_index': startChapterIndex,
      'replace_content_list': replaceContentList,
      'enable': enable,
    };
  }

  static BookSource fromMap(Map t) {
    var bookSource = BookSource();
    var jsonDecoder = const JsonDecoder();
    bookSource.id = t['id'].toString();
    bookSource.baseUrl = t['base_url'].toString();
    bookSource.name = t['name'].toString();
    bookSource.searchUrl = t['search_url'].toString();
    bookSource.searchInfo = Map<String, dynamic>.from(
        jsonDecoder.convert(t['search_info'].toString()));
    bookSource.chapterInfo = Map<String, dynamic>.from(
        jsonDecoder.convert(t['chapter_info'].toString()));
    bookSource.chapterContentInfo = Map<String, dynamic>.from(
        jsonDecoder.convert(t['chapter_content_info'].toString()));
    bookSource.startChapterIndex =
        int.parse(t['start_chapter_index']?.toString() ?? '0');
    bookSource.enable = int.parse(t['enable']?.toString() ?? '1');
    bookSource.replaceContentList = List<String>.from(
        jsonDecoder.convert(t['replace_content_list'].toString()));
    return bookSource;
  }

  static BookSource fromJson(Map t) {
    var bookSource = BookSource();
    bookSource.id = t['id'].toString();
    bookSource.baseUrl = t['base_url'].toString();
    bookSource.name = t['name'].toString();
    bookSource.searchUrl = t['search_url'].toString();
    bookSource.searchInfo = Map<String, dynamic>.from(t['search_info']);
    bookSource.chapterInfo = Map<String, dynamic>.from(t['chapter_info']);
    bookSource.chapterContentInfo = Map<String, dynamic>.from(t['chapter_content_info']);
    bookSource.startChapterIndex =
        int.parse(t['start_chapter_index']?.toString() ?? '0');
    bookSource.enable = int.parse(t['enable']?.toString() ?? '1');
    bookSource.replaceContentList = List<String>.from(t['replace_content_list']);
    return bookSource;
  }

  @override
  String toString() {
    return name.toString();
  }
}

class OutSideBook {
  late String title;
  late String url;
  late String cover;
  late String bookSourceId;
}

class OutSideChapter {
  late String title;
  late String url;
  late int seqNo;
}
