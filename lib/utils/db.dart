import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/pojo/chapter.dart';
import 'package:read_app/spider/spider.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/file_utils.dart';
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
    });
    return db;
  }

  Future<int?> insert(Book book) async {
    final db = await database;
    try {
      var result = await db?.rawInsert(
          'INSERT OR REPLACE INTO book (title, path, seq_no, chapter_title_exp, page, percent, type, cover, parent_id, current_chapter, create_time, update_time) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
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
            book.updateTime
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

  Future<void> mergeDB(String dbPath) async {
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
        newBook.updateTime = DateTime.now().millisecondsSinceEpoch;
        newBook.createTime = DateTime.now().millisecondsSinceEpoch;

        if (newBook.type == Constant.outSideType) {
          var split = newBook.path.split('|');
          var bookSourceId = split[0];
          var url = split[1];
          newBook.path = '${bookSourceIdMap[bookSourceId]}|$url';
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
}
