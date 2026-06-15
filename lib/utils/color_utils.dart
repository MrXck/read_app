import 'dart:ui';

import 'package:read_app/utils/constant.dart';

class ColorUtils {
  static bool isTransparent(Color color) {
    return color.alpha == 0;
  }

  static Color returnDefaultColor(int number) {
    return isTransparent(Color(number)) ? Color(Constant.defaultBackgroundColor) : Color(number);
  }
}