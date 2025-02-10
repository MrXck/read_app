import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingUtils {

  static List<GlobalKey> keyList = [];

  static showLoading({String tip = '加载中'}) {
    GlobalKey key = GlobalKey();
    Get.dialog(
        Dialog(
          key: key,
            child: Container(
          height: 150,
          width: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(tip),
            ],
          ),
        )),
        barrierDismissible: false);
    keyList.add(key);
  }

  static hideLoading() {
    var key = keyList.firstOrNull;

    if (key != null) {
      try {
        Navigator.pop(key.currentContext!);
      } finally {
        keyList.remove(key);
      }
    }
  }
}
