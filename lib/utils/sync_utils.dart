import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:get/get.dart' as Get;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/operation_log.dart';
import 'package:read_app/pojo/sync_log.dart';
import 'package:read_app/request/request.dart';
import 'package:read_app/utils/book_utils.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:dio/dio.dart';

class SyncUtils {
  static SettingController settingController = Get.Get.find();

  static Future<void> sync() async {
    Future.delayed(const Duration(seconds: 10), () async {
      await DatabaseHelper.db.deleteNotExistsData();
      if (settingController.isOpenSync.value &&
          !settingController.isSyncing.value) {
        settingController.isSyncing.value = true;
        print('同步中 ${DateTime.now()}');
        try {
          await syncUploadFile();
          await uploadOperationLogs();
          await syncRemoteUpdate();
          SyncLog syncLog = SyncLog();
          syncLog.createTime = DateTime.now().millisecondsSinceEpoch;
          DatabaseHelper.db.insertSyncLog(syncLog);
        } catch (e) {
          print(e);
        } finally {
          settingController.isSyncing.value = false;
        }
      }

      Timer.periodic(const Duration(minutes: 1), (timer) async {
        if (settingController.isOpenSync.value &&
            !settingController.isSyncing.value) {
          settingController.isSyncing.value = true;
          print('同步中 ${DateTime.now()}');
          try {
            await syncUploadFile();
            await uploadOperationLogs();
            await syncRemoteUpdate();
            SyncLog syncLog = SyncLog();
            syncLog.createTime = DateTime.now().millisecondsSinceEpoch;
            var logId =
                (await DatabaseHelper.db.insertSyncLog(syncLog)).toString();
            DatabaseHelper.db.deleteSyncLogByNotEqualId(logId);
          } catch (e) {
            print(e);
          } finally {
            settingController.isSyncing.value = false;
          }
        }
      });
    });
  }

  static Future<void> syncUploadFile() async {
    var logs = await DatabaseHelper.db.getAllSyncLog();
    if (logs.isNotEmpty) {
      return;
    }
    var books = await DatabaseHelper.db
        .getAllSyncBook([Constant.bookType, Constant.pdfType]);
    var response = await RequestUtils.postJson(
        Constant.validBookMd5Url,
        {
          "bookLogDTOS": books.map((item) => {'md5': item.md5}).toList()
        },
        Constant.headers);

    var md5s = [];

    if (response.data['code'] == 0) {
      md5s = response.data['data']['md5s'];
    }

    var dir = await getApplicationDocumentsDirectory();
    for (var book in books) {
      if (md5s.contains(book.md5)) {
        continue;
      }

      if (!settingController.needSyncTypeList.contains(book.type)) {
        continue;
      }

      var filePath = join(dir.path, book.path);
      try {
        await RequestUtils.postFileJson(
            Constant.uploadBookUrl,
            FormData.fromMap({
              'file': await MultipartFile.fromFile(
                filePath,
                filename: basename(filePath),
              ),
              'title': book.title,
              'chapterTitleExp': book.chapterTitleExp,
              'md5': book.md5,
              'seqNo': book.seqNo,
              'page': book.page,
              'type': book.type,
              'currentChapter': book.currentChapter,
              'percent': book.percent,
            }),
            {});
      } catch (e) {
        print(e);
      }
    }
  }

  static Future<void> syncRemoteUpdate() async {
    var response = await RequestUtils.postJson(
        Constant.getAllBookUrl, {}, Constant.headers);
    if (response.data['code'] != 0) {
      return;
    }
    var list = response.data['data']['list'];
    var tempDir = await getTemporaryDirectory();
    List<String> md5s = [];
    for (var book in list) {
      var timestamp = DateTime.parse(book['updateTime']).millisecondsSinceEpoch;
      var md5 = book['md5'];
      md5s.add(md5);
      var oldBook = await DatabaseHelper.db.getByMd5(md5);
      if (oldBook == null) {
        var filePath = join(tempDir.path, 'read', book['path']);
        try {
          await RequestUtils.getDownloadFile(
              '${Constant.downloadBookUrl}${book["id"]}', filePath);
          FileUtils.saveSyncBook(filePath, book);
        } catch (e) {
          print(e);
        }
      } else {
        if (timestamp > oldBook.updateTime) {
          oldBook.updateTime = timestamp;
          oldBook.percent = double.parse(book['percent']);
          oldBook.currentChapter = book['currentChapter'];
          oldBook.seqNo = book['seqNo'];
          oldBook.title = book['title'];
          oldBook.page = book['page'];
          oldBook.chapterTitleExp = book['chapterTitleExp'];
          oldBook.isSecret = book['isSecret'];
          await DatabaseHelper.db.updateById(oldBook);
        }
      }
    }
    List<Book> books = await DatabaseHelper.db
        .getBookByNotInMd5AndType(md5s, [Constant.bookType, Constant.pdfType]);
    await BookUtils.deleteBooks(books.map((item) {

      if (!settingController.needSyncTypeList.contains(item.type)) {
        return '';
      }

      return item.id;
    }).toList());
  }

  static Future<void> uploadOperationLogs() async {
    List<OperationLog> addLogs =
        await DatabaseHelper.db.getAllAddOperationLog();

    if (addLogs.isNotEmpty) {
      var dir = await getApplicationDocumentsDirectory();
      for (var log in addLogs) {
        var bookId = log.bookId;
        var book = await DatabaseHelper.db.getById(bookId);

        if (!settingController.needSyncTypeList.contains(book.type)) {
          continue;
        }

        try {
          var filePath = join(dir.path, book.path);
          await RequestUtils.postFileJson(
              Constant.uploadBookUrl,
              FormData.fromMap({
                'file': await MultipartFile.fromFile(
                  filePath,
                  filename: basename(filePath),
                ),
                'title': book.title,
                'chapterTitleExp': book.chapterTitleExp,
                'md5': book.md5,
                'seqNo': book.seqNo,
                'page': book.page,
                'type': book.type,
                'currentChapter': book.currentChapter,
                'percent': book.percent,
                'isSecret': book.isSecret,
              }),
              {});
        } finally {
          await DatabaseHelper.db.deleteOperationLogById(log.id);
        }
      }
    }

    List<OperationLog> logs =
        await DatabaseHelper.db.getAllNotAddOperationLog();
    if (logs.isEmpty) {
      return;
    }
    var response = await RequestUtils.postJson(
        Constant.updateBookUrl,
        {'bookLogDTOS': logs.map((item) => item.toJsonMap()).toList()},
        Constant.headers);

    try {
      if (response.data['code'] == 0) {
        for (var log in logs) {
          DatabaseHelper.db.deleteOperationLogById(log.id);
        }
      }
    } catch (e) {
      var result = const JsonDecoder().convert(response.data);
      if (result['code'] == 0) {
        for (var log in logs) {
          DatabaseHelper.db.deleteOperationLogById(log.id);
        }
      }
    }
  }

  static Future<void> main() async {
    Isolate.spawn((_) {
      sync();
    }, null);
  }
}
