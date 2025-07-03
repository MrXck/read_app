import 'package:get/get.dart';
import 'package:read_app/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingController extends GetxController {

  var isOpenHidden = false.obs;
  var isOpenVolumeFlip = false.obs;
  var isOpenSync = false.obs;
  var isSyncing = false.obs;

  init() async {
    var shared = await SharedPreferences.getInstance();
    isOpenSync.value = shared.getBool(Constant.syncConfigKey) ?? false;
  }

  updateSync() async {
    var shared = await SharedPreferences.getInstance();
    isOpenSync.value = !isOpenSync.value;
    shared.setBool(Constant.syncConfigKey, isOpenSync.value);
  }

  @override
  void onInit() {
    init();
    super.onInit();
  }
}
