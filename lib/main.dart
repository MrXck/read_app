import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/pojo/app_settings.dart';

// import 'package:flutter/rendering.dart';
import 'package:read_app/router/router.dart';
import 'package:get/get.dart';
import 'package:read_app/tab/tab.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/update_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'bindings/bind_controller.dart';

bool isDesktop() {
  return !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop()) {
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

  Future<APPSettings> init() async {
    await initFont();
    var value = await SharedPreferences.getInstance();
    var appConfig = const JsonDecoder()
        .convert(value.getString(Constant.appConfigKey) ?? '{}');
    return APPSettings.fromMap(appConfig);
  }

  Future<void> initFont() async {
    Directory directory = await getApplicationDocumentsDirectory();

    final fontPath = join(directory.path, join('read', 'font'));

    if (await Directory(fontPath).exists()) {
      List<FileSystemEntity> files = Directory(fontPath).listSync();
      for (var file in files) {
        final ByteData fontData = ByteData.sublistView(await File(file.path).readAsBytes());
        final loader = FontLoader(basename(file.path).split('.')[0]);
        loader.addFont(Future.value(fontData));
        await loader.load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    UpdateUtils.updateApp();
    if (isDesktop()) {
      databaseFactory = databaseFactoryFfi;
    }
    return FutureBuilder(
        future: init(),
        builder: (BuildContext context, AsyncSnapshot<APPSettings> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const MaterialApp(
                home: Scaffold(
                  body: Text("未连接"),
                ),
              );
            case ConnectionState.waiting:
              return const MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            case ConnectionState.active:
              return const MaterialApp(
                home: Scaffold(
                  body: Text(""),
                ),
              );
            case ConnectionState.done:
              if (snapshot.hasError) {
                return MaterialApp(
                  home: Scaffold(
                    body: Text(
                      "请求失败 , 报错信息 : ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              } else {
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
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.escape) {
                        Get.back();
                      }
                    },
                    focusNode: FocusNode()..requestFocus(),
                    child: GetMaterialApp(
                      theme: ThemeData(fontFamily: snapshot.data?.appFont),
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
        });
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
