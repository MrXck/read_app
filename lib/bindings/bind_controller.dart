import 'package:get/get.dart';
import 'package:read_app/controller/setting_controller.dart';


class BindController extends Bindings {
  @override
  void dependencies() {
    Get.put(SettingController());
  }

}
