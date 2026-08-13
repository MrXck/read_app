import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/app_settings.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late APPSettings appSettings = APPSettings();
  late List<String> fontFamilyList = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> initFontList() async {
    fontFamilyList = List.from(Constant.fontFamilyList);

    Directory directory = await getApplicationDocumentsDirectory();

    final fontPath = join(directory.path, join('read', 'font'));

    if (await Directory(fontPath).exists()) {
      List<FileSystemEntity> files = Directory(fontPath).listSync();
      for (var file in files) {
        fontFamilyList.add(basename(file.path).split('.')[0]);
      }
    }
  }

  Future<void> init() async {
    await initFontList();
    var value = await SharedPreferences.getInstance();
    var appConfig = const JsonDecoder()
        .convert(value.getString(Constant.appConfigKey) ?? '{}');
    appSettings = APPSettings.fromMap(appConfig);
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    return Scaffold(
        appBar: null,
        body: SafeArea(
            child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  const Text("设置")
                ],
              ),
            ),
            SizedBox(
                height: height - 40,
                child: FutureBuilder(
                    future: init(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return const Text("未连接");
                        case ConnectionState.waiting:
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        case ConnectionState.active:
                          return const Text("");
                        case ConnectionState.done:
                          if (snapshot.hasError) {
                            return Text(
                              "请求失败 , 报错信息 : ${snapshot.error}",
                              style: const TextStyle(color: Colors.red),
                            );
                          } else {
                            return ListView(children: [
                              ListTile(
                                onTap: () {
                                  Get.bottomSheet(
                                    Container(
                                      height: 200,
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16)),
                                      ),
                                      child: Material(
                                        child: ListView(
                                            children: fontFamilyList.map((item) {
                                              return ListTile(
                                                  title: Text(
                                                    item,
                                                    style: TextStyle(
                                                        fontFamily: item,
                                                        color: appSettings.appFont ==
                                                            item
                                                            ? Colors.blue
                                                            : Colors.black),
                                                  ),
                                                  onTap: () async {
                                                    setState(() {
                                                      appSettings.appFont = item;
                                                    });
                                                    var value =
                                                    await SharedPreferences
                                                        .getInstance();
                                                    value.setString(
                                                        Constant.appConfigKey,
                                                        const JsonEncoder().convert(
                                                            appSettings.toMap()));
                                                    Get.changeTheme(ThemeData(
                                                        fontFamily:
                                                        appSettings.appFont));
                                                  });
                                            }).toList()),
                                      ),
                                    ),
                                  );
                                },
                                title: const Text('字体选择'),
                                trailing: Text(appSettings.appFont),
                              ),
                              ListTile(
                                onTap: () async {
                                  List<String> successList = await FileUtils.selectAndImportFont();
                                  setState(() {
                                    fontFamilyList.addAll(successList);
                                  });
                                },
                                title: const Text('导入字体'),
                              )
                            ]);
                          }
                      }
                    }))
          ],
        )));
  }
}
