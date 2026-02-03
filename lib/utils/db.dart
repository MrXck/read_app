import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/chapter.dart';
import 'package:read_app/pojo/operation_log.dart';
import 'package:read_app/pojo/regexp_history.dart';
import 'package:read_app/pojo/sync_log.dart';
import 'package:read_app/spider/spider.dart';
import 'package:read_app/utils/book_utils.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/hash_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper db = DatabaseHelper._();

  static Database? _database;

  Future<Database?> get database async {
    _database ??= await initDb();
    return _database;
  }

  Future<Database> initDb() async {
    Directory directory = await getApplicationDocumentsDirectory();

    Directory dataDir = Directory(join(directory.path, 'read', 'data'));

    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    String path = join(dataDir.path, 'data.db');

    Database db = await openDatabase(path, version: 4, onOpen: (db) async {
      await db.execute(
          // 'DROP TABLE book;'

          'CREATE TABLE IF NOT EXISTS book ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          ' title TEXT,'
          ' path TEXT,'
          ' cover TEXT,'
          ' type INTEGER,'
          ' seq_no INTEGER,'
          ' page INTEGER,'
          ' percent INTEGER,'
          ' chapter_title_exp TEXT,'
          ' parent_id TEXT,'
          ' md5 TEXT,'
          ' is_secret INTEGER,'
          ' current_chapter INTEGER,'
          ' create_time INTEGER,'
          ' update_time INTEGER);');

      await db.execute(
          // 'DROP TABLE chapter;'

          'CREATE TABLE IF NOT EXISTS chapter ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          ' title TEXT,'
          ' path TEXT,'
          ' cover TEXT,'
          ' type INTEGER,'
          ' seq_no INTEGER,'
          ' page INTEGER,'
          ' percent INTEGER,'
          ' book_id TEXT,'
          ' create_time INTEGER,'
          ' update_time INTEGER);');

      // await db.execute('DROP TABLE book_source;');

      await db.execute('CREATE TABLE IF NOT EXISTS book_source ('
          ' id INTEGER PRIMARY KEY AUTOINCREMENT,'
          ' base_url TEXT,'
          ' name TEXT,'
          ' search_url TEXT,'
          ' search_info TEXT,'
          ' chapter_info TEXT,'
          ' chapter_content_info TEXT,'
          ' start_chapter_index INTEGER,'
          ' replace_content_list TEXT,'
          ' enable INTEGER);');

      // await db.execute('DROP TABLE operation_log;');

      await db.execute('CREATE TABLE IF NOT EXISTS operation_log ('
          ' id INTEGER PRIMARY KEY AUTOINCREMENT,'
          ' title TEXT,'
          ' type INTEGER,'
          ' md5 TEXT,'
          ' chapter_title_exp TEXT,'
          ' current_chapter INTEGER,'
          ' seq_no INTEGER,'
          ' page INTEGER,'
          ' percent INTEGER,'
          ' book_id INTEGER,'
          ' is_secret INTEGER,'
          ' create_time INTEGER);');

      await db.execute('CREATE TABLE IF NOT EXISTS sync_log ('
          ' id INTEGER PRIMARY KEY AUTOINCREMENT,'
          ' create_time INTEGER);');


      await db.execute('CREATE TABLE IF NOT EXISTS regexp_history ('
          ' id INTEGER PRIMARY KEY AUTOINCREMENT,'
          ' regexp TEXT,'
          ' source TEXT,'
          ' example TEXT,'
          ' create_time INTEGER);');
    });

    var flag = await isExistTableColumn('book', 'md5', db);

    if (!flag) {
      await db.execute('ALTER TABLE book ADD COLUMN md5 TEXT;');
    }

    flag = await isExistTableColumn('book', 'is_secret', db);

    if (!flag) {
      await db.execute('ALTER TABLE book ADD COLUMN is_secret INTEGER;');
    }

    flag = await isExistTableColumn('operation_log', 'is_secret', db);

    if (!flag) {
      await db.execute('ALTER TABLE operation_log ADD COLUMN is_secret INTEGER;');
    }

    updateBookMd5(db);
    updateBookIsSecret(db);
    return db;
  }

  Future<bool> isExistTableColumn(String table, String column, Database db) async {
    var columns = await getTableColumns(table, db);
    var flag = false;
    for (var column in columns) {
      if (column['name'] == column) {
        flag = true;
      }
    }
    return flag;
  }

  Future<List<Map<String, Object?>>> getTableColumns(
      String tableName, Database db) async {
    var query = await db.rawQuery('PRAGMA table_info($tableName)');
    return query;
  }

  Future<void> updateBookMd5(Database db) async {
    var query = await db.rawQuery(
        'select * from book where type in (${Constant.bookType}, ${Constant.pdfType}) and md5 is NULL');

    List<Book> books =
        query.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    var dir = await getApplicationDocumentsDirectory();
    for (Book book in books) {
      var path = join(dir.path, book.path);
      book.md5 = HASH.md5Byte(await File(path).readAsBytes());
      updateById(book);
    }
  }

  Future<void> updateBookIsSecret(Database db) async {
    var query = await db.rawQuery(
        'select * from book where is_secret is NULL');

    List<Book> books =
    query.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    for (Book book in books) {
      book.isSecret = 0;
      updateById(book);
    }
  }

  Future<int?> insert(Book book) async {
    final db = await database;
    try {
      var result = await db?.rawInsert(
          'INSERT OR REPLACE INTO book (title, path, seq_no, chapter_title_exp, page, percent, type, cover, parent_id, current_chapter, create_time, update_time, md5) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            book.title,
            book.path,
            book.seqNo,
            book.chapterTitleExp,
            book.page,
            book.percent,
            book.type,
            book.cover,
            book.parentId,
            book.currentChapter,
            book.createTime,
            book.updateTime,
            book.md5
          ]);
      return result;
    } on DatabaseException {
      return -1;
    }
  }

  Future<List<Book>> getAllBook() async {
    var db = await database;
    var query =
        await db?.query('book', orderBy: 'update_time Desc, seq_no asc');
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<List<Book>> getAllSyncBook(List<int> bookTypes) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'type in (${List.filled(bookTypes.length, '?').join(', ')})',
        whereArgs: bookTypes);
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<List<Book>> getAllSyncBookByParentId(String parentId, List<int> bookTypes) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'parent_id = ? and type in (${List.filled(bookTypes.length, '?').join(', ')})',
        whereArgs: [parentId, ...bookTypes]);
    List<Book> books =
    query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<List<Book>> getBookByParentId(String parentId) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'update_time Desc, seq_no asc');
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<Book?> getByMd5(String md5) async {
    var db = await database;
    var query = await db?.query('book', where: 'md5 = ?', whereArgs: [md5]);
    Book? book = query!.isNotEmpty ? Book.fromMap(query[0]) : null;
    return book;
  }

  Future<List<Book>> getBookByNotInMd5AndType(List<String> md5s, List<int> types) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'md5 not in (${List.filled(md5s.length, '?').join(', ')}) and type in (${List.filled(types.length, '?').join(', ')})',
        whereArgs: [...md5s, ...types],
        orderBy: 'update_time Desc, seq_no asc');
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<List<Book>> getByTitle(String title) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'title like ? and type != ?',
        whereArgs: ['%$title%', Constant.directoryType],
        orderBy: 'update_time Desc');
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<Book> getById(String id) async {
    var db = await database;
    var query = await db?.query('book', where: 'id = ?', whereArgs: [id]);
    Book book = query!.isNotEmpty ? Book.fromMap(query[0]) : Book();
    return book;
  }

  Future<List<Book>> getDirectoryByTitle(String title) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'title = ? and type = ?',
        whereArgs: [title, Constant.directoryType],
        orderBy: 'update_time Desc');
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<List<Book>> getDirectoryByTitleAndNotMe(
      String title, String id) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'title = ? and type = ? and id != ?',
        whereArgs: [title, Constant.directoryType, id],
        orderBy: 'update_time Desc');
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<List<Book>> getBooksByIds(List<String> ids) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'id in (${List.filled(ids.length, '?').join(', ')})',
        whereArgs: ids);
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<List<Book>> getDirectoryByPatentId(parentId) async {
    var db = await database;
    var query = await db?.query('book',
        where: 'parent_id = ? and type = ?',
        whereArgs: [parentId, Constant.directoryType],
        orderBy: 'update_time Desc');
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<List<Book>> getBooksByPath(List<String> paths) async {
    var db = await database;
    var query = await db
        ?.rawQuery('select * from book where ${generateLike('path', paths)}');
    List<Book> books =
        query!.isNotEmpty ? query.map((t) => Book.fromMap(t)).toList() : [];
    return books;
  }

  Future<void> deleteById(String id) async {
    var db = await database;
    await db?.rawDelete('DELETE FROM book WHERE id = ?', [id]);
  }

  Future<void> deleteByIds(List<String> ids) async {
    var db = await database;
    await db?.delete('book',
        whereArgs: ids,
        where: 'id in (${List.filled(ids.length, '?').join(', ')})');
  }

  Future<void> updateById(Book book) async {
    var db = await database;
    book.updateTime = DateTime.now().millisecondsSinceEpoch;
    await db?.update('book', book.toMap(),
        where: 'id = ?',
        whereArgs: [book.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateParentIdById(id, parentId) async {
    var db = await database;
    await db?.rawUpdate(
        'update book set parent_id = ? where id = ?', [parentId, id]);
  }

  Future<void> updateAll(List<Book> books) async {
    var db = await database;
    for (var book in books) {
      await db?.update('book', book.toMap(),
          where: 'id = ?',
          whereArgs: [book.id],
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<int?> insertChapter(Chapter chapter) async {
    final db = await database;
    try {
      var result = await db?.rawInsert(
          'INSERT OR REPLACE INTO chapter (title, path, seq_no, page, percent, type, cover, book_id, create_time, update_time) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            chapter.title,
            chapter.path,
            chapter.seqNo,
            chapter.page,
            chapter.percent,
            chapter.type,
            chapter.cover,
            chapter.bookId,
            chapter.createTime,
            chapter.updateTime
          ]);
      return result;
    } on DatabaseException {
      return -1;
    }
  }

  Future<List<Chapter>> getChapterByBookId(String bookId) async {
    var db = await database;
    var query = await db?.query('chapter',
        where: 'book_id = ? and type = ?',
        whereArgs: [bookId, Constant.chapterType],
        orderBy: 'seq_no asc');
    List<Chapter> chapters =
        query!.isNotEmpty ? query.map((t) => Chapter.fromMap(t)).toList() : [];
    return chapters;
  }

  Future<void> deleteChapterById(String id) async {
    var db = await database;
    await db?.rawDelete('DELETE FROM chapter WHERE id = ?', [id]);
  }

  Future<void> deleteChapterByBookId(String id) async {
    var db = await database;
    await db?.rawDelete('DELETE FROM chapter WHERE book_id = ?', [id]);
  }

  Future<void> deleteDirectory(String id, String dirPath) async {
    var bookList = await getBookByParentId(id);
    for (var book in bookList) {
      if (book.type == Constant.bookType) {
        var bookPath = join(dirPath, Directory(book.path).parent.path);
        if (bookPath != dirPath) {
          await FileUtils.deletePath(bookPath);
          await deleteChapterByBookId(book.id);
          await deleteById(book.id);
        }
      } else if (book.type == Constant.directoryType) {
        await deleteDirectory(book.id, dirPath);
      } else if (book.type == Constant.outSideType) {
        await deleteById(book.id);
      } else {
        await FileUtils.deletePath(join(dirPath, book.path));
        await deleteById(book.id);
      }
    }

    await deleteById(id);
  }

  Future<void> mergeDB(String dbPath, ValueNotifier<String> tipText) async {
    final newDb = await openDatabase(dbPath);

    try {
      Map<String, String> bookSourceIdMap = {};
      final bookSources = await newDb.rawQuery("SELECT * FROM book_source;");

      for (var bookSource in bookSources) {
        BookSource newBookSource = BookSource.fromMap(bookSource);
        bookSourceIdMap[newBookSource.id] =
            (await insertBookSource(newBookSource)).toString();
      }

      final books = await newDb.rawQuery("SELECT * FROM book;");

      Map<String, String> bookIdMap = {};
      List<Book> bookList = [];

      for (var book in books) {
        Book newBook = Book.fromMap(book);
        tipText.value = '处理 ${newBook.title} 中...';
        newBook.updateTime = DateTime.now().millisecondsSinceEpoch;
        newBook.createTime = DateTime.now().millisecondsSinceEpoch;

        if (newBook.type == Constant.outSideType) {
          try {
            var split = newBook.path.split('|');
            var bookSourceId = split[0];
            var url = split[1];
            newBook.path = '${bookSourceIdMap[bookSourceId]}|$url';
          } catch (e) {
            continue;
          }
        }

        var bookId = await insert(newBook);

        bookIdMap[newBook.id] = bookId.toString();

        var oldBook = Book.fromMap(newBook.toMap());
        oldBook.id = bookId.toString();
        bookList.add(oldBook);

        var query = await newDb.query('chapter',
            where: 'book_id = ? and type = ?',
            whereArgs: [newBook.id, Constant.chapterType],
            orderBy: 'seq_no asc');
        List<Chapter> chapters = query.isNotEmpty
            ? query.map((t) => Chapter.fromMap(t)).toList()
            : [];
        for (var chapter in chapters) {
          chapter.bookId = bookId.toString();
          chapter.updateTime = DateTime.now().millisecondsSinceEpoch;
          chapter.createTime = DateTime.now().millisecondsSinceEpoch;

          await insertChapter(chapter);
        }
      }

      for (var book in bookList) {
        if (book.parentId.isNotEmpty) {
          book.parentId = bookIdMap[book.parentId] ?? '';
          updateById(book);
        }
      }

      tipText.value = '删除多余数据中...';
      await deleteNotExistsData();

      var list = await getAllSyncBook([Constant.bookType]);
      for (var book in list) {
        Directory directory = Directory(join(Directory(book.path).parent.path, 'chapter'));
        if (!(await directory.exists())) {
          tipText.value = '重新生成 ${book.title} 章节中...';
          await BookUtils.changeChapter(book, book.chapterTitleExp);
          OperationLog operationLog = OperationLog.setOperationLog(book, book.id, Constant.operationAddType);
          await insertOperationLog(operationLog);
        }
      }
    } finally {
      await newDb.close();
    }
  }

  Future<List<BookSource>> getAllBookSource() async {
    var db = await database;
    var query = await db?.query('book_source');
    List<BookSource> bookSources = query!.isNotEmpty
        ? query.map((t) => BookSource.fromMap(t)).toList()
        : [];
    return bookSources;
  }

  Future<List<BookSource>> getAllEnableBookSource() async {
    var db = await database;
    var query = await db?.query('book_source', where: 'enable = 1');
    List<BookSource> bookSources = query!.isNotEmpty
        ? query.map((t) => BookSource.fromMap(t)).toList()
        : [];
    return bookSources;
  }

  Future<int?> insertBookSource(BookSource bookSource) async {
    final db = await database;
    var jsonEncoder = const JsonEncoder();
    try {
      var result = await db?.rawInsert(
          'INSERT OR REPLACE INTO book_source (base_url, name, search_url, search_info, chapter_info, chapter_content_info, start_chapter_index, replace_content_list, enable) values(?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            bookSource.baseUrl,
            bookSource.name,
            bookSource.searchUrl,
            jsonEncoder.convert(bookSource.searchInfo),
            jsonEncoder.convert(bookSource.chapterInfo),
            jsonEncoder.convert(bookSource.chapterContentInfo),
            bookSource.startChapterIndex,
            jsonEncoder.convert(bookSource.replaceContentList),
            bookSource.enable,
          ]);
      return result;
    } on DatabaseException {
      return -1;
    }
  }

  Future<void> deleteBookSourceById(String id) async {
    var db = await database;
    await db?.rawDelete('DELETE FROM book_source WHERE id = ?', [id]);
  }

  Future<void> updateBookSourceById(BookSource bookSource) async {
    var db = await database;
    await db?.update('book_source', bookSource.toMap(),
        where: 'id = ?',
        whereArgs: [bookSource.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<BookSource> getBookSourceById(String id) async {
    var db = await database;
    var query =
        await db?.query('book_source', where: 'id = ?', whereArgs: [id]);
    BookSource bookSource =
        query!.isNotEmpty ? BookSource.fromMap(query[0]) : BookSource();
    return bookSource;
  }

  String generateLike(String column, List<String> condition) {
    return condition.map((item) => ' $column LIKE "%$item%"').join(' OR ');
  }

  Future<int?> insertOperationLog(OperationLog operationLog) async {
    final db = await database;
    try {
      var result = await db?.rawInsert(
          'INSERT OR REPLACE INTO operation_log (title, seq_no, chapter_title_exp, page, percent, type, book_id, md5, current_chapter, create_time) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            operationLog.title,
            operationLog.seqNo,
            operationLog.chapterTitleExp,
            operationLog.page,
            operationLog.percent,
            operationLog.type,
            operationLog.bookId,
            operationLog.md5,
            operationLog.currentChapter,
            operationLog.createTime,
          ]);
      return result;
    } on DatabaseException {
      return -1;
    }
  }

  Future<List<OperationLog>> getAllNotAddOperationLog() async {
    var db = await database;
    var query = await db?.query('operation_log',
        where: 'type != ?',
        whereArgs: [Constant.operationAddType],
        orderBy: 'create_time asc');
    List<OperationLog> logs = query!.isNotEmpty
        ? query.map((t) => OperationLog.fromMap(t)).toList()
        : [];
    return logs;
  }

  Future<List<OperationLog>> getAllAddOperationLog() async {
    var db = await database;
    var query = await db?.query('operation_log',
        where: 'type = ?',
        whereArgs: [Constant.operationAddType],
        orderBy: 'create_time asc');
    List<OperationLog> logs = query!.isNotEmpty
        ? query.map((t) => OperationLog.fromMap(t)).toList()
        : [];
    return logs;
  }

  Future<void> deleteOperationLogById(String id) async {
    var db = await database;
    await db?.rawDelete('DELETE FROM operation_log WHERE id = ?', [id]);
  }

  Future<int?> insertSyncLog(SyncLog syncLog) async {
    final db = await database;
    try {
      var result = await db?.rawInsert(
          'INSERT OR REPLACE INTO sync_log (create_time) values(?)', [
        syncLog.createTime,
      ]);
      return result;
    } on DatabaseException {
      return -1;
    }
  }

  Future<List<SyncLog>> getAllSyncLog() async {
    var db = await database;
    var query = await db?.query('sync_log', orderBy: 'create_time asc');
    List<SyncLog> logs =
        query!.isNotEmpty ? query.map((t) => SyncLog.fromMap(t)).toList() : [];
    return logs;
  }

  Future<void> deleteNotExistsData() async {
    var list = await getAllBook();
    var dataDir = await getApplicationDocumentsDirectory();
    for (var book in list) {
      if (book.type == Constant.bookType) {
        var bookPath = join(dataDir.path, Directory(book.path).parent.path);
        if (bookPath != dataDir.path && !(await Directory(bookPath).exists())) {
          await deleteChapterByBookId(book.id);
          await deleteById(book.id);
        }
      } else if (book.type == Constant.directoryType) {
      } else if (book.type == Constant.outSideType) {
      } else {
        var bookPath = join(dataDir.path, book.path);
        if (!(await Directory(bookPath).exists())) {
          await deleteById(book.id);
        }
      }
    }
  }

  Future<void> deleteSyncLogByNotEqualId(String id) async {
    var db = await database;
    await db?.rawDelete('DELETE FROM sync_log WHERE id != ?', [id]);
  }

  Future<List<RegexpHistory>> getAllRegexpHistory() async {
    var db = await database;
    var query = await db?.query('regexp_history');
    List<RegexpHistory> regexpHistories = query!.isNotEmpty
        ? query.map((t) => RegexpHistory.fromMap(t)).toList()
        : [];
    return regexpHistories;
  }

  Future<List<RegexpHistory>> getRegexpHistoryByRegexp(String regexp) async {
    var db = await database;
    var query = await db?.query('regexp_history', where: 'regexp = ?', whereArgs: [regexp]);
    List<RegexpHistory> regexpHistories = query!.isNotEmpty
        ? query.map((t) => RegexpHistory.fromMap(t)).toList()
        : [];
    return regexpHistories;
  }

  Future<int?> insertRegexpHistory(RegexpHistory regexpHistory) async {
    final db = await database;
    try {
      var result = await db?.rawInsert(
          'INSERT OR REPLACE INTO regexp_history (regexp, create_time) values(?, ?)', [
            regexpHistory.regexp,
            regexpHistory.createTime,
      ]);
      return result;
    } on DatabaseException {
      return -1;
    }
  }

  Future<void> deleteRegexpHistoryByRegexp(String regexp) async {
    var db = await database;
    await db?.rawDelete('DELETE FROM regexp_history WHERE regexp = ?', [regexp]);
  }
}
