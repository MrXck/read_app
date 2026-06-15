import 'dart:ui';

import 'package:window_manager/window_manager.dart';

class MyWindowListener extends WindowListener {
  final VoidCallback onResize;

  MyWindowListener(this.onResize);

  @override
  void onWindowResized() {
    onResize();
  }
}