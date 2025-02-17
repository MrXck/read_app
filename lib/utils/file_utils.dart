import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/utils/book_utils.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/random.dart';
import 'package:share_plus/share_plus.dart';

import 'db.dart';

class FileUtils {
  static String getFileExtension(String filePath) {
    return filePath.split('.').last; // 获取最后一个点后面的部分
  }

  static Future<String> loadFile(String path) async {
    return await File(path).readAsString();
  }

  static Future<bool> isDirectory(String path) async {
    final entity = FileSystemEntity.typeSync(path);
    return entity == FileSystemEntityType.directory;
  }

  static Future<void> deletePath(String path) async {
    if (path.isEmpty) {
      return;
    }
    if (await isDirectory(path)) {
      await deleteDirectoryRecursively(Directory(path));
    } else {
      await deleteFile(path);
    }
  }

  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);

    // 检查文件是否存在
    if (await file.exists()) {
      try {
        // 删除文件
        await file.delete();
      } catch (e) {}
    } else {}
  }

  static Future<void> deleteDirectoryRecursively(Directory directory) async {
    if (await directory.exists()) {
      // 列出文件夹中的所有文件和子文件夹
      await for (var entity in directory.list(recursive: false)) {
        if (entity is File) {
          // 如果是文件，直接删除
          await entity.delete();
        } else if (entity is Directory) {
          // 如果是文件夹，递归删除文件夹
          await deleteDirectoryRecursively(entity);
        }
      }
      // 删除文件夹本身
      await directory.delete();
    }
  }

  static Future<void> uploadFile(List<int> fileBytes, filename) async {
    var extension = getFileExtension(filename);

    if (Constant.allPdfType.contains(extension)) {
      uploadPdf(fileBytes, filename);
    } else if (Constant.allMediaType.contains(extension)) {
      uploadMedia(fileBytes, filename);
    } else if (Constant.allTextType.contains(extension)) {
      uploadText(fileBytes, filename);
    } else if (Constant.allFontType.contains(extension)) {
      uploadFont(fileBytes, filename);
    }
  }

  static Future<void> uploadMedia(List<int> fileBytes, filename) async {
    Directory directory = await getApplicationDocumentsDirectory();

    final relativeDirPath = path.join('read', 'media');

    final assetsDir = path.join(directory.path, relativeDirPath);

    if (!await Directory(assetsDir).exists()) {
      await Directory(assetsDir).create(recursive: true);
    }

    var name = '${generateRandomString(32)}.${getFileExtension(filename)}';

    String filePath = path.join(assetsDir, name);
    File file = File.fromUri(Uri.file(filePath));
    await file.writeAsBytes(fileBytes);
    // 可以做其他操作

    var split = filename.split('.');

    Book book = Book();
    book.percent = 0;
    book.page = 0;
    book.chapterTitleExp = Constant.defaultChapterTitleExp;
    book.title = split.sublist(0, split.length - 1).join('.');
    book.updateTime = DateTime.now().millisecondsSinceEpoch;
    book.createTime = DateTime.now().millisecondsSinceEpoch;
    book.seqNo = 0;
    book.parentId = '';
    book.path = path.join(relativeDirPath, name);
    book.type = Constant.mediaType;
    book.cover = "";
    book.currentChapter = 0;
    await DatabaseHelper.db.insert(book);
  }

  static Future<void> uploadText(List<int> fileBytes, filename) async {
    Directory directory = await getApplicationDocumentsDirectory();

    var bookDirName = generateRandomString(32);

    final relativeDirPath = path.join('read', 'book', bookDirName);

    final assetsDir = path.join(directory.path, relativeDirPath);

    final absoluteDirPath = path.join(directory.path, relativeDirPath);

    if (!await Directory(assetsDir).exists()) {
      await Directory(assetsDir).create(recursive: true);
    }

    var name = '${generateRandomString(32)}.txt';

    String filePath = path.join(assetsDir, name);
    File file = File.fromUri(Uri.file(filePath));
    await file.writeAsBytes(fileBytes);
    // 可以做其他操作

    var split = filename.split('.');

    Book book = Book();
    book.percent = 0;
    book.page = 0;
    book.chapterTitleExp = Constant.defaultChapterTitleExp;
    book.title = split.sublist(0, split.length - 1).join('.');
    book.updateTime = DateTime.now().millisecondsSinceEpoch;
    book.createTime = DateTime.now().millisecondsSinceEpoch;
    book.seqNo = 0;
    book.parentId = '';
    book.path = path.join(relativeDirPath, name);
    book.type = Constant.bookType;
    book.cover = "";
    book.currentChapter = 0;
    var bookId = await DatabaseHelper.db.insert(book);

    try {
      var content = await BookUtils.loadBook(file.path);
      var chapterContentList = BookUtils.splitChapterContent(
          content, Constant.defaultChapterTitleExp);
      await BookUtils.saveChapter(relativeDirPath, absoluteDirPath,
          chapterContentList, bookId.toString());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> uploadPdf(List<int> fileBytes, filename) async {
    Directory directory = await getApplicationDocumentsDirectory();

    final relativeDirPath = path.join('read', 'pdf');

    final assetsDir = path.join(directory.path, relativeDirPath);

    if (!await Directory(assetsDir).exists()) {
      await Directory(assetsDir).create(recursive: true);
    }

    var name = '${generateRandomString(32)}.pdf';

    String filePath = path.join(assetsDir, name);
    File file = File.fromUri(Uri.file(filePath));
    await file.writeAsBytes(fileBytes);
    // 可以做其他操作

    var split = filename.split('.');

    Book book = Book();
    book.percent = 0;
    book.page = 0;
    book.chapterTitleExp = Constant.defaultChapterTitleExp;
    book.title = split.sublist(0, split.length - 1).join('.');
    book.updateTime = DateTime.now().millisecondsSinceEpoch;
    book.createTime = DateTime.now().millisecondsSinceEpoch;
    book.seqNo = 0;
    book.parentId = '';
    book.path = path.join(relativeDirPath, name);
    book.type = Constant.pdfType;
    book.cover = "";
    book.currentChapter = 0;
    await DatabaseHelper.db.insert(book);
  }

  static Future<void> uploadFont(List<int> fileBytes, filename) async {
    Directory directory = await getApplicationDocumentsDirectory();
    final relativeDirPath = path.join('read', 'font');

    final assetsDir = path.join(directory.path, relativeDirPath);

    if (!await Directory(assetsDir).exists()) {
      await Directory(assetsDir).create(recursive: true);
    }

    String filePath = path.join(assetsDir, filename);
    File file = File.fromUri(Uri.file(filePath));
    await file.writeAsBytes(fileBytes);

    final ByteData fontData = ByteData.sublistView(await File(file.path).readAsBytes());
    final loader = FontLoader(basename(file.path).split('.')[0]);
    loader.addFont(Future.value(fontData));
    await loader.load();
  }

  static Future<void> selectAndImportFile(String parentId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: Constant.allTextType);

    if (result != null) {
      for (var i = 0; i < result.files.length; i++) {
        await saveBook(result.files[i].path, parentId);
      }
    }
  }

  static Future<void> selectAndImportFont() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: Constant.allFontType);

    if (result != null) {
      for (var i = 0; i < result.files.length; i++) {
        await uploadFile(await File(result.files[i].path!).readAsBytes(), result.files[i].name);
      }
    }
  }

  static Future<void> saveBook(var selectFile, String parentId) async {
    final file = File(selectFile);
    final dir = await getApplicationDocumentsDirectory();
    var bookDirName = generateRandomString(32);

    final relativeDirPath = path.join('read', 'book', bookDirName);

    final assetsDir = path.join(dir.path, relativeDirPath);

    final absoluteDirPath = path.join(dir.path, relativeDirPath);

    var content = await BookUtils.loadBook(file.path);

    if (!await Directory(assetsDir).exists()) {
      await Directory(assetsDir).create(recursive: true);
    }

    var name = '${generateRandomString(32)}.${getFileExtension(file.path)}';
    final filePath = path.join(assetsDir, '', name);
    await file.copy(filePath);

    var chapterContentList =
        BookUtils.splitChapterContent(content, Constant.defaultChapterTitleExp);

    Book book = Book();
    book.percent = 0;
    book.page = 0;
    book.chapterTitleExp = Constant.defaultChapterTitleExp;
    var split = path.basename(selectFile).split('.');
    book.title = split.sublist(0, split.length - 1).join('.');
    book.updateTime = DateTime.now().millisecondsSinceEpoch;
    book.createTime = DateTime.now().millisecondsSinceEpoch;
    book.seqNo = 0;
    book.cover = "";
    book.parentId = parentId;
    book.type = Constant.bookType;
    book.path = path.join(relativeDirPath, name);
    book.currentChapter = 0;

    var bookId = await DatabaseHelper.db.insert(book);

    await BookUtils.saveChapter(relativeDirPath, absoluteDirPath,
        chapterContentList, bookId.toString());
  }

  static Future<void> selectAndImportMedia(String parentId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: Constant.allMediaType);

    if (result != null) {
      for (var i = 0; i < result.files.length; i++) {
        await saveMedia(result.files[i], parentId);
      }
    }
  }

  static Future<void> saveMedia(var selectFile, String parentId) async {
    final file = File(selectFile.path!);
    final dir = await getApplicationDocumentsDirectory();

    final relativeDirPath = path.join('read', 'media');

    final assetsDir = path.join(dir.path, relativeDirPath);

    if (!await Directory(assetsDir).exists()) {
      await Directory(assetsDir).create(recursive: true);
    }

    var name = '${generateRandomString(32)}.${getFileExtension(file.path)}';

    final filePath = path.join(assetsDir, name);
    await file.copy(filePath);
    Book book = Book();
    book.percent = 0;
    book.page = 0;
    book.chapterTitleExp = Constant.defaultChapterTitleExp;
    var split = selectFile.name.split('.');
    book.title = split.sublist(0, split.length - 1).join('.');
    book.updateTime = DateTime.now().millisecondsSinceEpoch;
    book.createTime = DateTime.now().millisecondsSinceEpoch;
    book.seqNo = 0;
    book.cover = "";
    book.parentId = parentId;
    book.type = Constant.mediaType;
    book.path = path.join(relativeDirPath, name);
    book.currentChapter = 0;
    DatabaseHelper.db.insert(book);
  }

  static Future<void> saveComic(var selectDirectory, String parentId) async {
    Directory directory = Directory(selectDirectory);
    List<FileSystemEntity> files = directory.listSync();

    // 提取文件名中的数字并按数字排序
    files.sort((a, b) {
      // 提取文件名
      var nameA = path.basenameWithoutExtension(a.uri.pathSegments.last);
      var nameB = path.basenameWithoutExtension(b.uri.pathSegments.last);

      // 使用正则表达式提取文件名中的数字
      var numberA = int.tryParse(nameA) ?? 999;
      var numberB = int.tryParse(nameB) ?? 999;

      // 比较提取的数字
      return numberA.compareTo(numberB);
    });

    final dir = await getApplicationDocumentsDirectory();

    String newDirPath = '${dir.path}/${generateRandomString(32)}';

    Directory newDir = Directory(newDirPath);

    final relativeDirPath = path.join('read', 'comic');

    final assetsDir = path.join(dir.path, relativeDirPath);

    newDirPath = path.join(assetsDir, generateRandomString(32));

    var cover = "";
    var oldImageList = [];

    // 打印文件列表
    for (var oldFile in files) {
      final mimeType = lookupMimeType(oldFile.path);

      if (mimeType != null) {
        if (mimeType.startsWith('image/')) {
          oldImageList.add(oldFile.path);
        } else if (mimeType == 'application/pdf') {
        } else {}
      } else {}
    }

    if (oldImageList.isEmpty) {
      return;
    }
    newDir = Directory(newDirPath);

    while (!await Directory(assetsDir).exists()) {
      await Directory(assetsDir).create(recursive: true);
    }

    newDir.createSync();

    var newImageList = [];

    for (var i = 0; i < oldImageList.length; i++) {
      var oldPath = oldImageList[i];
      final filePath = '${newDir.path}/$i.${getFileExtension(oldPath)}';
      newImageList.add(filePath);
      File file = File(oldPath);
      await file.copy(filePath);
    }

    if (newImageList.isNotEmpty) {
      cover = path.join(relativeDirPath, path.basename(newDir.path),
          path.basename(newImageList[0]));
    } else {
      return;
    }

    Book book = Book();
    book.percent = 0;
    book.page = 0;
    book.chapterTitleExp = Constant.defaultChapterTitleExp;
    book.title = path.basename(selectDirectory);
    book.updateTime = DateTime.now().millisecondsSinceEpoch;
    book.createTime = DateTime.now().millisecondsSinceEpoch;
    book.type = Constant.comicType;
    book.cover = cover;
    book.seqNo = 0;
    book.parentId = parentId;
    book.path = path.join(relativeDirPath, path.basename(newDir.path));
    book.currentChapter = 0;
    DatabaseHelper.db.insert(book);
  }

  static Future<String> selectDirectory() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath == null) {
        return "";
      }

      return directoryPath;
    } else {
      return "";
    }
  }

  static Future<void> saveBookByDirectory(
      String dirPath, String parentId) async {
    Directory directory = Directory(dirPath);
    List<FileSystemEntity> files = directory.listSync();

    // 打印文件列表
    for (var oldFile in files) {
      final mimeType = lookupMimeType(oldFile.path);

      if (mimeType != null) {
        if (mimeType == 'text/plain') {
          await saveBook(oldFile.path, parentId);
        } else if (mimeType == 'application/pdf') {
        } else {}
      } else {}
    }
  }

  static Future<void> saveComicByDirectory(
      String dirPath, String parentId) async {
    Directory directory = Directory(dirPath);
    List<FileSystemEntity> files = directory.listSync();

    for (var oldFile in files) {
      if (await isDirectory(oldFile.path)) {
        await saveComic(oldFile.path, parentId);
      }
    }
  }

  static Future<void> selectAndImportDirectory(String parentId) async {
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath == null) {
        return;
      }

      await saveComic(directoryPath, parentId);
    } else {}
  }

  static Future<void> compressDirectory(
      String dirPath, String outputPath) async {
    // 创建一个空的 ZIP 文件
    var archive = Archive();

    // 获取文件夹中的所有文件
    var dir = Directory(dirPath);

    // 将文件添加到 ZIP 存档中
    await for (var file in dir.list(recursive: true)) {
      if (file is File) {
        var fileBytes = await file.readAsBytes();
        var relativePath = path.relative(file.path, from: dirPath);
        archive.addFile(ArchiveFile(relativePath, fileBytes.length, fileBytes));
      }
    }

    // 将存档写入到文件
    var zipData = await compute(encodeZip, archive);
    // var outputFile = File(outputPath);
    // await outputFile.writeAsBytes(zipData!);
    // print('压缩完成，输出文件路径：$outputPath');

    saveFile('导出', zipData);
  }

  static List<int> encodeZip(Archive archive) {
    return ZipEncoder().encode(archive) ?? [];
  }

  static Future<String> selectJsonFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);

    if (result != null) {
      return await loadFile(result.files.first.path!);
    }

    return '';
  }

  static Future<String> selectZipFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['zip']);

    if (result != null) {
      if (result.files.single.path != null) {
        return result.files.single.path!;
      }
    }
    return '';
  }

  static Future<void> saveFile(String fileName, var bytes) async {
    // 获取应用的临时目录
    var tempDir = await getTemporaryDirectory();

    // 创建一个临时文件路径
    var time = DateTime.now();
    var filePath = path.join(tempDir.path,
        '导出-${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}-${time.hour.toString().padLeft(2, '0')}-${time.minute.toString().padLeft(2, '0')}-${time.second.toString().padLeft(2, '0')}.zip');

    // 将文件写入临时路径
    var file = File(filePath);
    await file.writeAsBytes(bytes);

    final files = <XFile>[];
    files.add(XFile(filePath));
    Share.shareXFiles(files, text: "导出.zip");
  }

  static Future<void> saveJsonFile(String fileName, String content) async {
    // 获取应用的临时目录
    var tempDir = await getTemporaryDirectory();

    // 创建一个临时文件路径
    var time = DateTime.now();
    var filePath = path.join(tempDir.path,
        '书源-${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}-${time.hour.toString().padLeft(2, '0')}-${time.minute.toString().padLeft(2, '0')}-${time.second.toString().padLeft(2, '0')}.json');

    // 将文件写入临时路径
    var file = File(filePath);
    await file.writeAsString(content);

    final files = <XFile>[];
    files.add(XFile(filePath));
    Share.shareXFiles(files, text: "书源.json");
  }

  static Future<void> unzipFile(String zipFilePath, String outputDir) async {
    var file = File(zipFilePath);
    var bytes = await file.readAsBytes();

    // 解压ZIP文件
    var archive = ZipDecoder().decodeBytes(bytes);

    var outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    // 解压文件内容
    for (var file in archive) {
      var filename = path.join(outputDir, file.name);
      if (file.isFile) {
        var outFile = File(filename);

        var directory = Directory(path.dirname(filename));
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        await outFile.writeAsBytes(file.content);
      } else {
        await Directory(filename).create(recursive: true);
      }
    }

    print('解压完成，文件保存在：$outputDir');
  }

  static Future<void> copyDirectory(String fromPath, String toPath) async {
    final destination = Directory(toPath);
    final source = Directory(fromPath);

    // 如果目标目录不存在则创建它
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    // 遍历源目录的所有文件和子文件夹
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        // 递归复制子目录
        var newDirectory =
            Directory(path.join(destination.path, path.basename(entity.path)));
        await copyDirectory(entity.path, newDirectory.path);
      } else if (entity is File) {
        if (entity.path.endsWith('data.db')) {
          await DatabaseHelper.db.mergeDB(entity.path);
          continue;
        }

        // 复制文件
        var newFile =
            File(path.join(destination.path, path.basename(entity.path)));
        await newFile.writeAsBytes(await entity.readAsBytes());
      }
    }
  }

  static Future<void> uploadZipFile(
      List<int> fileBytes, String filename) async {
    String tempPath = '';
    String outputDir = '';
    try {
      Directory tempDirectory = await getTemporaryDirectory();

      var comicDirName = generateRandomString(32);

      tempPath = path.join(tempDirectory.path, '$comicDirName.zip');
      outputDir = path.join(tempDirectory.path, comicDirName);

      File file = File.fromUri(Uri.file(tempPath));

      await file.writeAsBytes(fileBytes);

      await FileUtils.unzipFile(tempPath, outputDir);

      Directory outputDirectory = Directory(outputDir);

      await FileUtils.saveComicByDirectory(outputDir, '');

      bool hasDir = false;
      await for (var entity in outputDirectory.list(recursive: false)) {
        if (entity is Directory) {
          hasDir = true;
        }
      }

      if (!hasDir) {
        await FileUtils.saveComic(outputDir, '');
      }
    } catch (e) {
      rethrow;
    } finally {
      FileUtils.deletePath(tempPath);
      FileUtils.deletePath(outputDir);
    }
  }

  static Future<void> selectAndImportPdf(String parentId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: Constant.allPdfType);

    if (result != null) {
      for (var i = 0; i < result.files.length; i++) {
        await savePdf(result.files[i], parentId);
      }
    }
  }

  static Future<void> savePdf(var selectFile, String parentId) async {
    final file = File(selectFile.path!);
    final dir = await getApplicationDocumentsDirectory();

    final relativeDirPath = path.join('read', 'pdf');

    final assetsDir = path.join(dir.path, relativeDirPath);

    if (!await Directory(assetsDir).exists()) {
      await Directory(assetsDir).create(recursive: true);
    }

    var name = '${generateRandomString(32)}.${getFileExtension(file.path)}';

    final filePath = path.join(assetsDir, name);
    await file.copy(filePath);
    Book book = Book();
    book.percent = 0;
    book.page = 0;
    book.chapterTitleExp = Constant.defaultChapterTitleExp;
    var split = selectFile.name.split('.');
    book.title = split.sublist(0, split.length - 1).join('.');
    book.updateTime = DateTime.now().millisecondsSinceEpoch;
    book.createTime = DateTime.now().millisecondsSinceEpoch;
    book.seqNo = 0;
    book.cover = "";
    book.parentId = parentId;
    book.type = Constant.pdfType;
    book.path = path.join(relativeDirPath, name);
    book.currentChapter = 0;
    DatabaseHelper.db.insert(book);
  }
}
