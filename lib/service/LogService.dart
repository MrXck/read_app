import 'dart:async';

import 'package:get/get.dart';
import 'package:read_app/pojo/operation_log.dart';
import 'package:read_app/utils/db.dart';

class LogService {
  LogService._();

  static final LogService instance = LogService._();

  final StreamController<OperationLog> _controller =
      StreamController<OperationLog>.broadcast();

  bool _started = false;

  void init() {
    if (_started) return;
    _started = true;
    _controller.stream.listen((log) async {
      try {
        await DatabaseHelper.db.insertOperationLog(log);
      } catch (e) {
        print('日志写入失败: $e');
      }
    });
  }

  void log(OperationLog log) {
    _controller.add(log);
  }
}
