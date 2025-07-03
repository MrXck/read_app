import 'dart:convert';
import 'package:crypto/crypto.dart';

class HASH {
  static String md5String(String input) {
    final bytes = utf8.encode(input); // 转换为字节数组
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  static String md5Byte(List<int> bytes) {
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}
