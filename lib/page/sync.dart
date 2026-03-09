import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/pojo/sync_log.dart';
import 'package:read_app/utils/constant.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/sync_utils.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {

  final SettingController settingController = Get.find();

  ValueNotifier<String> tips = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
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
                    const Text("同步")
                  ],
                ),
              ),
              Obx(() {
                if (settingController.isSyncing.value) {
                  return const Text('正在同步中');
                }
                return const Text('等待同步中');
              }),
              Obx(() {
                if (settingController.isSyncing.value) {
                  return TextButton(onPressed: () {}, child: const Text('等待同步完成'),);
                }
                return TextButton(onPressed: () async {
                  if (!settingController.isOpenSync.value) {
                    tips.value = '请开启同步后进行此操作';
                    return;
                  }
                  if (!settingController.isSyncing.value) {
                    settingController.isSyncing.value = true;
                    print('同步中 ${DateTime.now()}');
                    try {
                      tips.value = '正在上传新文件...';
                      await SyncUtils.syncUploadFile();
                      tips.value = '正在上传操作历史...';
                      await SyncUtils.uploadOperationLogs();
                      tips.value = '正在下载远端操作...';
                      await SyncUtils.syncRemoteUpdate();
                      SyncLog syncLog = SyncLog();
                      syncLog.createTime = DateTime.now().millisecondsSinceEpoch;
                      var logId =
                      (await DatabaseHelper.db.insertSyncLog(syncLog)).toString();
                      DatabaseHelper.db.deleteSyncLogByNotEqualId(logId);
                      tips.value = '同步完成';
                    } catch (e) {
                      print(e);
                      tips.value = '发生错误: ${e.toString()}';
                    } finally {
                      settingController.isSyncing.value = false;
                    }
                  } else {
                    tips.value = '正在同步中等同步完成后在操作';
                  }
                }, child: const Text('开始同步'));
              }),
              ValueListenableBuilder(
                  valueListenable: tips,
                  builder: (BuildContext context, value,
                      Widget? child) {
                    return Text(
                      value,
                      style: const TextStyle(color: Colors.red),
                    );
                  }),
              Obx(() {
                return Text(settingController.syncTip.value);
              }),
              Obx(() {
                  return Row(
                    children: [
                      Checkbox(value: settingController.needSyncTypeList.contains(Constant.pdfType), onChanged: (value) {
                        settingController.updateSyncTypeList(Constant.pdfType);
                      }),
                      const Text('pdf类型')
                    ],
                  );
              }),
              Obx(() {
                return Row(
                  children: [
                    Checkbox(value: settingController.needSyncTypeList.contains(Constant.bookType), onChanged: (value) {
                      settingController.updateSyncTypeList(Constant.bookType);
                    }),
                    const Text('txt类型')
                  ],
                );
              }),
            ],
          )
      ),
    );
  }

  @override
  void dispose() {
    tips.dispose();
    super.dispose();
  }
}
