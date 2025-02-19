import 'package:package_info_plus/package_info_plus.dart';

class PackageUtils {
  static Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }
}