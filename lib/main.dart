import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:read_app/controller/setting_controller.dart';

// import 'package:flutter/rendering.dart';
import 'package:read_app/router/router.dart';
import 'package:get/get.dart';
import 'package:read_app/tab/tab.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'bindings/bind_controller.dart';

bool isDesktop() {
  return !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
}

void main() async {
  if (isDesktop()) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(300, 300),
      center: true,
      skipTaskbar: false,
      // titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }
  // debugPaintSizeEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final SettingController settingController = Get.find();

  @override
  Widget build(BuildContext context) {
    if (isDesktop()) {
      databaseFactory = databaseFactoryFfi;
    }
    return MouseRegion(
      onEnter: (_) {
        windowManager.setOpacity(1.0);
      },
      onExit: (_) {
        if (settingController.isOpenHidden.value) {
          windowManager.setOpacity(0.01);
        }
      },
      child: KeyboardListener(
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            Get.back();
          }
        },
        focusNode: FocusNode()..requestFocus(),
        child: GetMaterialApp(
          theme: ThemeData(fontFamily: 'pingfang'),
          debugShowCheckedModeBanner: false,
          initialRoute: "/",
          getPages: AppPage.routes,
          home: const TabPage(),
          initialBinding: BindController(),
          // localizationsDelegates: const [
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          // ],
          // supportedLocales: const [
          //   Locale('zh', 'CN'), // 中国大陆的中文
          // ]
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TabPage(),
    );
  }
}
