import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingUtils {
  static List<GlobalKey> keyList = [];
  static List<ValueNotifier> tipList = [];

  static showLoading({String tip = '加载中'}) {
    GlobalKey key = GlobalKey();
    ValueNotifier<String> tipText = ValueNotifier<String>(tip);
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
                  ValueListenableBuilder(
                      valueListenable: tipText,
                      builder: (BuildContext context, value, Widget? child) {
                        return Text(value);
                      }),
                ],
              ),
            )),
        barrierDismissible: false);
    keyList.add(key);
    tipList.add(tipText);
    return tipText;
  }

  static hideLoading() {
    var key = keyList.firstOrNull;
    var tip = tipList.firstOrNull;

    if (key != null) {
      try {
        Navigator.pop(key.currentContext!);
      } finally {
        keyList.remove(key);
      }
    }

    if (tip != null) {
      try {
        tip.dispose();
      } finally {
        tipList.remove(tip);
      }
    }
  }
}
