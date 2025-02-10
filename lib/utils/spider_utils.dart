import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:read_app/request/request.dart';
import 'package:read_app/spider/spider.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class SpiderUtils {
  static Future<List<OutSideBook>> request(
      BookSource bookSource, String keyword) async {
    List<OutSideBook> books = [];

    var headers = Map<String, String>.from(bookSource.searchInfo['headers']);

    Response? res;

    keyword = Uri.encodeComponent(keyword);

    for (var element in headers.entries) {
      headers[element.key] = headers[element.key]
          .toString()
          .replaceFirst(bookSource.replaceKeyword, keyword);
    }

    switch (bookSource.searchInfo['method']) {
      case 'get':
        switch (bookSource.searchInfo['return_type']) {
          case 'json':
            res = await RequestUtils.getJson(
                bookSource.searchUrl
                    .replaceFirst(bookSource.replaceKeyword, keyword),
                bookSource.searchInfo['data'],
                headers);
            break;
          case 'html':
            res = await RequestUtils.getForm(
                bookSource.searchUrl
                    .replaceFirst(bookSource.replaceKeyword, keyword),
                bookSource.searchInfo['data'],
                headers);
            break;
        }

        break;
      case 'post':
        var data = bookSource.searchInfo['data'];
        for (var element in data.entries) {
          data[element.key] = data[element.key]
              .toString()
              .replaceFirst(bookSource.replaceKeyword, keyword);
        }

        switch (bookSource.searchInfo['return_type']) {
          case 'json':
            res = await RequestUtils.postJson(
                bookSource.searchUrl, data, headers);
            break;
          case 'html':
            res = await RequestUtils.postForm(
                bookSource.searchUrl, data, headers);
            break;
        }
        break;
    }

    if (res != null) {
      switch (bookSource.searchInfo['return_type']) {
        case 'json':
          List returnDataList = [];
          var data = const JsonDecoder().convert(res.data);

          String? returnDataKey = bookSource.searchInfo['return_data_key'];

          if (returnDataKey != null && returnDataKey != '') {
            var keyList = returnDataKey.split(Constant.dataKeySplitStr);

            if (keyList.length != 1) {
              for (var key in keyList) {
                data = data[key];
              }
              returnDataList = data as List;
            } else {
              returnDataList = data[returnDataKey] as List;
            }
          } else {
            returnDataList = data;
          }

          for (int i = 0; i < returnDataList.length; i++) {
            OutSideBook book = OutSideBook();

            book.bookSourceId = bookSource.id;

            String? coverKey = bookSource.searchInfo['cover'];

            if (coverKey != null && coverKey != '') {
              var data = returnDataList[i];
              List<String> dataKeyList =
                  coverKey.split(Constant.dataKeySplitStr);
              if (dataKeyList.length != 1) {
                for (var key in dataKeyList) {
                  data = data[key];
                }
                book.cover = data as String;
              } else {
                book.cover = data[coverKey];
              }
            } else {
              book.cover = '';
            }

            String? nameKey = bookSource.searchInfo['name'];
            if (nameKey != null && nameKey != '') {
              var data = returnDataList[i];
              List<String> dataKeyList =
                  nameKey.split(Constant.dataKeySplitStr);
              if (dataKeyList.length != 1) {
                for (var key in dataKeyList) {
                  data = data[key];
                }
                book.title = data as String;
              } else {
                book.title = data[nameKey];
              }
            } else {
              book.title = '';
            }

            String? urlKey = bookSource.searchInfo['url'];
            if (urlKey != null && urlKey != '') {
              var data = returnDataList[i];
              List<String> dataKeyList = urlKey.split(Constant.dataKeySplitStr);
              if (dataKeyList.length != 1) {
                for (var key in dataKeyList) {
                  data = data[key];
                }
                book.url = data as String;
              } else {
                book.url = data[urlKey];
              }
            } else {
              book.url = '';
            }

            if (bookSource.searchInfo['url_prefix'] != null &&
                bookSource.searchInfo['url_prefix'] != '') {
              book.url = '${bookSource.searchInfo['url_prefix']}${book.url}';
            }

            books.add(book);
          }
          break;
        case 'html':
          final document = XmlDocument.parse(cleanHtml(res.data));
          for (var tag
              in document.xpath(bookSource.searchInfo['book_list_xpath'])) {
            var url = tag.xpath(bookSource.searchInfo['book_url_xpath']);
            var title = tag.xpath(bookSource.searchInfo['book_url_xpath']);
            var cover = tag.xpath(bookSource.searchInfo['book_url_xpath']);

            OutSideBook outSideBook = OutSideBook();

            if (url.firstOrNull != null) {
              outSideBook.url = url.first.innerText;
            }

            if (title.firstOrNull != null) {
              outSideBook.title = title.first.innerText;
            }

            if (cover.firstOrNull != null) {
              outSideBook.cover = cover.first.innerText;
            }
            books.add(outSideBook);
          }
          break;
      }
    }
    return books;
  }

  static Future<List<OutSideBook>> spider(String keyword) async {
    List<BookSource> bookSources =
        await DatabaseHelper.db.getAllEnableBookSource();

    List<OutSideBook> dataList = [];

    for (int i = 0; i < bookSources.length; i++) {
      dataList.addAll(await request(bookSources[i], keyword));
    }

    return dataList;
  }

  static Future<List<OutSideChapter>> spiderChapterByBook(
      String bookUrl, String keyword, String bookSourceId) async {
    List<OutSideChapter> list = [];

    var bookSource = await DatabaseHelper.db.getBookSourceById(bookSourceId);

    Response? res;

    var headers = Map<String, String>.from(bookSource.chapterInfo['headers']);

    switch (bookSource.chapterInfo['method']) {
      case 'get':
        switch (bookSource.chapterInfo['return_type']) {
          case 'json':
            res = await RequestUtils.getJson(
                bookUrl, bookSource.chapterInfo['data'], headers);
            break;
          case 'html':
            res = await RequestUtils.getForm(
                bookUrl, bookSource.chapterInfo['data'], headers);
            break;
        }

        break;
      case 'post':
        var data = bookSource.chapterInfo['data'];
        for (var element in data.entries) {
          data[element.key] = data[element.key]
              .toString()
              .replaceFirst(bookSource.replaceKeyword, keyword);
        }

        switch (bookSource.chapterInfo['return_type']) {
          case 'json':
            res = await RequestUtils.postJson(bookUrl, data, headers);
            break;
          case 'html':
            res = await RequestUtils.postForm(bookUrl, data, headers);
            break;
        }
        break;
    }

    if (res != null) {
      switch (bookSource.chapterInfo['return_type']) {
        case 'json':
          List returnDataList = [];
          var data = const JsonDecoder().convert(res.data);

          String? returnDataKey = bookSource.searchInfo['return_data_key'];

          if (returnDataKey != null && returnDataKey != '') {
            var keyList = returnDataKey.split(Constant.dataKeySplitStr);

            if (keyList.length != 1) {
              for (var key in keyList) {
                data = data[key];
              }
              returnDataList = data as List;
            } else {
              returnDataList = data[returnDataKey] as List;
            }
          } else {
            returnDataList = data;
          }
          int seqNo = 0;
          for (int i = 0; i < returnDataList.length; i++) {
            OutSideChapter chapter = OutSideChapter();

            String? urlKey = bookSource.chapterInfo['url'];
            if (urlKey != null && urlKey != '') {
              var data = returnDataList[i];
              List<String> dataKeyList = urlKey.split(Constant.dataKeySplitStr);
              if (dataKeyList.length != 1) {
                for (var key in dataKeyList) {
                  data = data[key];
                }
                chapter.url = data as String;
              } else {
                chapter.url = data[urlKey];
              }
            } else {
              chapter.url = '';
            }

            if (chapter.url.contains('javascript')) {
              continue;
            }

            String? nameKey = bookSource.chapterInfo['name'];
            if (nameKey != null && nameKey != '') {
              var data = returnDataList[i];
              List<String> dataKeyList =
                  nameKey.split(Constant.dataKeySplitStr);
              if (dataKeyList.length != 1) {
                for (var key in dataKeyList) {
                  data = data[key];
                }
                chapter.title = data as String;
              } else {
                chapter.title = data[nameKey];
              }
            } else {
              chapter.title = '';
            }

            String? urlPrefixKey = bookSource.chapterInfo['url_prefix'];
            if (urlPrefixKey != null && urlPrefixKey != '') {
              chapter.url = '$urlPrefixKey${chapter.url}';
            }
            chapter.seqNo = seqNo;
            seqNo++;

            list.add(chapter);
          }
          break;
        case 'html':

          final html3 = HtmlXPath.html(res.data);

          List nodes = html3
              .queryXPath(bookSource.chapterInfo['chapter_url_list_xpath'])
              .nodes;

          int seqNo = 0;

          for (var i = 0; i < nodes.length; i++) {
            var tag = nodes[i];
            OutSideChapter chapter = OutSideChapter();

            if (tag.attributes['href'].contains('javascript')) {
              continue;
            }

            if (bookSource.chapterInfo['url_prefix'] != null &&
                bookSource.chapterInfo['url_prefix'] != '') {
              chapter.url =
                  '${bookSource.chapterInfo['url_prefix']}${tag.attributes['href']}';
            } else {
              chapter.url = tag.attributes['href'];
            }

            chapter.title = tag.text!;
            chapter.seqNo = seqNo;
            seqNo++;

            list.add(chapter);
          }
          break;
      }
    }

    if (bookSource.startChapterIndex != 0 && bookSource.startChapterIndex < list.length) {
      list = list.sublist(bookSource.startChapterIndex);
    }

    return list;
  }

  static Future<String> spiderChapterContent(
      String url, String bookSourceId) async {
    String data = '';

    var bookSource = await DatabaseHelper.db.getBookSourceById(bookSourceId);
    Response? res;

    var headers = Map<String, String>.from(bookSource.chapterContentInfo['headers']);

    switch (bookSource.chapterContentInfo['method']) {
      case 'get':
        switch (bookSource.chapterContentInfo['return_type']) {
          case 'json':
            res = await RequestUtils.getJson(
                url, bookSource.chapterContentInfo['data'], headers);
            break;
          case 'html':
            res = await RequestUtils.getForm(
                url, bookSource.chapterContentInfo['data'], headers);
            break;
        }

        break;
      case 'post':
        var data = bookSource.chapterContentInfo['data'];

        switch (bookSource.chapterContentInfo['return_type']) {
          case 'json':
            res = await RequestUtils.postJson(url, data, headers);
            break;
          case 'html':
            res = await RequestUtils.postForm(url, data, headers);
            break;
        }
        break;
    }

    if (res != null) {
      switch (bookSource.chapterContentInfo['return_type']) {
        case 'json':
          var dataMap = const JsonDecoder().convert(res.data);

          String? returnDataKey = bookSource.searchInfo['return_data_key'];

          if (returnDataKey != null && returnDataKey != '') {
            var keyList = returnDataKey.split(Constant.dataKeySplitStr);

            if (keyList.length != 1) {
              for (var key in keyList) {
                dataMap = dataMap[key];
              }
            } else {
              data = dataMap[returnDataKey];
            }
          } else {
            data = dataMap;
          }
          break;
        case 'html':
          final document = XmlDocument.parse(cleanHtml(res.data));
          for (var tag in document
              .xpath(bookSource.chapterContentInfo['chapter_content_xpath'])) {
            data = '$data\n$tag';
          }
          // final html3 = HtmlXPath.html(res.data);
          // for (var tag in html3.queryXPath(bookSource.chapterContentXpath).nodes) {
          //   data = '$data${tag.text}';
          // }
          break;
      }

      for (var replace in bookSource.replaceContentList) {
        data = data.replaceAll(replace, '');
      }
    }

    return data;
  }

  static String cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<meta.*?>'), '')
        .replaceAll(RegExp(r'<hr.*?>'), '');
  }
}
