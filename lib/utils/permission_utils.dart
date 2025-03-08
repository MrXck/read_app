import 'package:permission_handler/permission_handler.dart';
import 'package:read_app/utils/platform_utils.dart';

class PermissionUtils {

  static Future<PermissionStatus> getFilePermission() async {

    var version = await PlatFormUtils.getSdkVersion();

    if (version > 28) {
      return await Permission
          .manageExternalStorage
          .request();
    } else {
      return await Permission.storage.request();
    }
  }
}