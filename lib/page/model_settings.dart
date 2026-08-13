import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/model_utils.dart';
import 'package:read_app/utils/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelSettingsPage extends StatefulWidget {
  const ModelSettingsPage({super.key});

  @override
  State<ModelSettingsPage> createState() => _ModelSettingsState();
}

class _ModelSettingsState extends State<ModelSettingsPage> {
  ValueNotifier<bool> modelExist = ValueNotifier(false);
  Settings settings = Settings();
  List<int> speakList = List.generate(104, (index) {
    return index + 1;
  });

  Future<void> init() async {
    var value = await SharedPreferences.getInstance();
    var config = const JsonDecoder().convert(
      value.getString(Constant.readConfigKey) ?? '{}',
    );
    settings = Settings.fromMap(config);

    if (await Directory(await ModelManager.modelLocalPath).exists()) {
      modelExist.value = true;
    }
  }

  @override
  void initState() {
    super.initState();
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
                  const Text("设置"),
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
                      return const Center(child: CircularProgressIndicator());
                    case ConnectionState.active:
                      return const Text("");
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Text(
                          "请求失败 , 报错信息 : ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        );
                      } else {
                        return ListView(
                          children: [
                            ListTile(
                              onTap: () {
                                Get.bottomSheet(
                                  Container(
                                    height: 200,
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: Material(
                                      child: ListView(
                                        children: speakList.map((item) {
                                          return ListTile(
                                            title: Text(
                                              item.toString(),
                                              style: TextStyle(
                                                color: settings.sid == item
                                                    ? Colors.blue
                                                    : Colors.black,
                                              ),
                                            ),
                                            onTap: () async {
                                              setState(() {
                                                settings.sid = item;
                                              });
                                              var value =
                                                  await SharedPreferences.getInstance();
                                              value.setString(
                                                Constant.readConfigKey,
                                                const JsonEncoder().convert(
                                                  settings.toMap(),
                                                ),
                                              );
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              title: const Text('说话人选择'),
                              trailing: Text(settings.sid.toString()),
                            ),
                            ValueListenableBuilder(
                              valueListenable: modelExist,
                              builder:
                                  (
                                    BuildContext context,
                                    bool value,
                                    Widget? child,
                                  ) {
                                    if (!value) {
                                      return ListTile(
                                        onTap: () async {
                                          await ModelManager.copyModelsIfNeeded();
                                          TtsService().initTTS();
                                        },
                                        leading: const Text('下载模型'),
                                      );
                                    }
                                    return const ListTile(title: Text('模型已下载'));
                                  },
                            ),
                          ],
                        );
                      }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
