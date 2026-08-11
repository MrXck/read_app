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
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/platform_utils.dart';
import 'package:read_app/utils/sync_utils.dart';
import 'package:read_app/utils/update_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';

import 'bindings/bind_controller.dart';


void initListenShare() {
  // 监听共享数据流
  FlutterSharingIntent.instance.getMediaStream().listen(
      (List<SharedFile> value) async {
    if (value.isEmpty) {
      return;
    }

    for (var file in value) {
      if (file.type == SharedMediaType.TEXT && file.value != null) {
        await FileUtils.saveBook(file.value, '');
      }
    }
  }, onError: (err) {
    print("getIntentDataStream error: $err");
  });

  // 获取应用启动时的初始共享数据
  FlutterSharingIntent.instance
      .getInitialSharing()
      .then((List<SharedFile> value) async {
    if (value.isEmpty) {
      return;
    }

    for (var file in value) {
      if (file.type == SharedMediaType.TEXT && file.value != null) {
        await FileUtils.saveBook(file.value, '');
      }
    }

    FlutterSharingIntent.instance.reset();
  });
}

void initIOSListenShare() {
  // 监听共享数据流
  FlutterSharingIntent.instance.getMediaStream().listen(
          (List<SharedFile> value) async {
    if (value.isEmpty) {
      return;
    }

    for (var file in value) {
      Get.snackbar('提示', 'value ${file.value}  type ${file.type}');
      if (file.type == SharedMediaType.FILE && file.value != null) {
        // 需要手动读取文件内容
        try {
          await FileUtils.saveBook(file.value, '');
        } catch (e) {
          print("读取分享文件失败: $e");
        }
      }
    }
  }, onError: (err) {
    print("getIntentDataStream error: $err");
  });

  // 获取应用启动时的初始共享数据
  FlutterSharingIntent.instance
      .getInitialSharing()
      .then((List<SharedFile> value) async {
    if (value.isEmpty) {
      return;
    }

    for (var file in value) {
      if (file.type == SharedMediaType.FILE && file.value != null) {
        await FileUtils.saveBook(file.value, '');
      }
    }

    FlutterSharingIntent.instance.reset();
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (PlatFormUtils.isDesktop()) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: Size(Constant.defaultWindowWidth, Constant.defaultWindowHeight),
      center: true,
      skipTaskbar: false,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.show();
    });
  }
  // debugPaintSizeEnabled = true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      initListenShare();
      break;
    case TargetPlatform.iOS:
      initIOSListenShare();
      break;
    default:
      break;
  }
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
        final ByteData fontData =
            ByteData.sublistView(await File(file.path).readAsBytes());
        final loader = FontLoader(basename(file.path).split('.')[0]);
        loader.addFont(Future.value(fontData));
        await loader.load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SyncUtils.sync();
    UpdateUtils.updateApp();
    double num = 4;

    if (PlatFormUtils.isDesktop()) {
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
                Widget app = GetMaterialApp(
                  theme: ThemeData(
                      fontFamily: snapshot.data?.appFont),
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
                );
                if (PlatFormUtils.isDesktop()) {
                  app = GestureDetector(
                      onPanStart: (d) {
                        var position = d.localPosition;
                        var size = MediaQuery.of(context).size;
                        if (position.dy <= size.height * 0.05) {
                          windowManager.startDragging();
                        }
                        // windowManager.startResizing(ResizeEdge.bottomRight);
                      },
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: GetMaterialApp(
                                theme: ThemeData(
                                  colorScheme: ColorScheme.fromSeed(
                                    seedColor: Colors.white,
                                    surface: Colors.white, // surface 颜色也会影响 Scaffold 背景
                                  ),
                                  fontFamily: snapshot.data?.appFont),
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
                              )),
                          Positioned(
                              right: 0,
                              bottom: num,
                              top: num,
                              width: num,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeRight,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) => windowManager
                                        .startResizing(ResizeEdge.right),
                                    child: const SizedBox.shrink()),
                              )),
                          Positioned(
                              left: 0,
                              bottom: num,
                              top: num,
                              width: num,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeLeft,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) => windowManager
                                        .startResizing(ResizeEdge.left),
                                    child: const SizedBox.shrink()),
                              )),
                          Positioned(
                              right: num,
                              left: num,
                              top: 0,
                              height: num,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeUp,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) => windowManager
                                        .startResizing(ResizeEdge.top),
                                    child: const SizedBox.shrink()),
                              )),
                          Positioned(
                              right: num,
                              bottom: 0,
                              left: num,
                              height: num,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeDown,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) => windowManager
                                        .startResizing(ResizeEdge.bottom),
                                    child: const SizedBox.shrink()),
                              )),

                          Positioned(
                              top: 0,
                              width: num,
                              left: 0,
                              height: num,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeUpLeft,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) => windowManager
                                        .startResizing(ResizeEdge.topLeft),
                                    child: const SizedBox.shrink()),
                              )),
                          Positioned(
                              top: 0,
                              width: num,
                              right: 0,
                              height: num,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeUpRight,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) => windowManager
                                        .startResizing(ResizeEdge.topRight),
                                    child: const SizedBox.shrink()),
                              )),
                          Positioned(
                              bottom: 0,
                              width: num,
                              left: 0,
                              height: num,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeDownLeft,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) => windowManager
                                        .startResizing(ResizeEdge.bottomLeft),
                                    child: const SizedBox.shrink()),
                              )),
                          Positioned(
                              bottom: 0,
                              width: num,
                              right: 0,
                              height: num,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.resizeDownRight,
                                child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (_) => windowManager
                                        .startResizing(ResizeEdge.bottomRight),
                                    child: const SizedBox.shrink()),
                              )),
                        ],
                      ));
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
                      if (event is KeyDownEvent) {
                        switch (event.logicalKey) {
                          case LogicalKeyboardKey.escape:
                            Get.back();
                            return;
                          case LogicalKeyboardKey.controlLeft:
                            exit(0);
                        }
                      }
                    },
                    focusNode: FocusNode()..requestFocus(),
                    child: app,
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
