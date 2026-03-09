import 'dart:convert';

import 'package:get/get.dart';
import 'package:read_app/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingController extends GetxController {

  var isOpenHidden = false.obs;
  var isOpenVolumeFlip = false.obs;
  var isOpenSync = false.obs;
  var isSyncing = false.obs;
  var isSecretMode = false.obs;
  var needSyncTypeList = [].obs;

  init() async {
    var shared = await SharedPreferences.getInstance();
    isOpenSync.value = shared.getBool(Constant.syncConfigKey) ?? false;

    var needSyncTypeListString = shared.getString(Constant.needSyncTypeKey) ?? "[]";

    needSyncTypeList.value = const JsonDecoder().convert(needSyncTypeListString) ?? [];
    print(needSyncTypeListString);
  }

  updateSync() async {
    var shared = await SharedPreferences.getInstance();
    isOpenSync.value = !isOpenSync.value;
    shared.setBool(Constant.syncConfigKey, isOpenSync.value);
  }

  updateSyncTypeList(int type) async {
    var shared = await SharedPreferences.getInstance();
    if (needSyncTypeList.contains(type)) {
      needSyncTypeList.remove(type);
    } else {
      needSyncTypeList.add(type);
    }

    shared.setString(Constant.needSyncTypeKey, const JsonEncoder().convert(needSyncTypeList));
  }

  @override
  void onInit() {
    init();
    super.onInit();
  }
}
