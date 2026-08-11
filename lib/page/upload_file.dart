import 'dart:io';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:mime/mime.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/controller/setting_controller.dart';
import 'package:read_app/utils/file_utils.dart';
import 'package:read_app/utils/random.dart';

class HttpServiceLogic {
  List<HttpServer> services = [];
  late String address = '';
  List<String> ipList = [];
  int port = 25210;

  Future<List<String>> getIpv4AndIpV6Addresses() async {
    try {
      // 获取所有网络接口信息
      List<NetworkInterface> interfaces = await NetworkInterface.list(
        // includeLoopback: true, // 是否包含回环接口
        includeLinkLocal: true, // 是否包含链路本地接口（例如IPv6的自动配置地址）。
        type: InternetAddressType.IPv4,
      );

      // 遍历所有网络接口
      for (var interface in interfaces) {
        // check if interface is en0 which is the wifi connection on the iphone
        // 遍历接口的地址
        for (var address in interface.addresses) {
          if (address.address.isNotEmpty) {
            if (address.type == InternetAddressType.IPv4) {
              ipList.add(address.address);
            }
          }
        }
      }
    } catch (e) {
      print(e);
    }
    return ipList;
  }

  Future<List<String>> startListen() async {
    List<String> removeIpList = [];
    for (var ip in ipList) {
      try {
        await startService(ip, ip);
      } catch (e) {
        removeIpList.add(ip);
      }
    }
    for (var ip in removeIpList) {
      ipList.remove(ip);
    }
    return ipList;
  }

  // 启动服务
  startService(tempIpv4, tempIpv6) async {
    if (tempIpv4.toString().isEmpty) {
      return;
    }
    // 启动 HttpService
    var service = await HttpServer.bind(tempIpv4, port);
    services.add(service);
    // 这种获取方式不准 只能获取到0.0.0.0
    // 监听所有Http请求
    service.forEach((HttpRequest request) async {
      if (request.uri.path == '/') {
        // 入口文件
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(await rootBundle.loadString('assets/www/index.html'))
          ..close();
      } else if (request.uri.path == '/upload' &&
          request.method.toUpperCase() == 'POST') {
        // 上传接口 这边定义跟后端写法差不多
        if (request.headers.contentType?.mimeType == 'multipart/form-data') {
          // 指定 multipart/form-data 传输二进制类型
          // 这里使用mime/mime.dart 的 MimeMultipartTransformer 解析二进制数据
          // 坑点 使用官方示例会报错，然后调整以下
          String boundary =
              request.headers.contentType!.parameters['boundary']!;
          // 然后处理HttpRequest流
          await for (var multipart
              in MimeMultipartTransformer(boundary).bind(request)) {
            // 然后在body里面的 filename和field 都在 multipart.headers里面 然后文件流就是multipart本身
            String? contentDisposition =
                multipart.headers['content-disposition'];
            String? filename = contentDisposition
                ?.split("; ")
                .where((item) => item.startsWith("filename="))
                .first
                .replaceFirst("filename=", "")
                .replaceAll('"', '');
            // 我这边指定txt文件，否则跳过，如果不需要就略过
            if (filename == null || filename.isEmpty) {
              continue;
            }

            try {
              await FileUtils.uploadFile(
                  await multipart.toBytes(), filename.toLowerCase());
              // 这边我直接成功，可以做其他判断
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.json
                ..write({"code": 1, "msg": "upload success"})
                ..close();
            } catch (e) {
              // 这边我直接成功，可以做其他判断
              request.response
                ..statusCode = HttpStatus.internalServerError
                ..headers.contentType = ContentType.json
                ..write({"code": 0, "msg": e.toString()})
                ..close();
            }
          }
        } else {
          // 其他请求都是404
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      } else if (request.uri.path == '/uploadComic' &&
          request.method.toUpperCase() == 'POST') {
        if (request.headers.contentType?.mimeType == 'multipart/form-data') {
          // 指定 multipart/form-data 传输二进制类型
          // 这里使用mime/mime.dart 的 MimeMultipartTransformer 解析二进制数据
          // 坑点 使用官方示例会报错，然后调整以下
          String boundary =
              request.headers.contentType!.parameters['boundary']!;
          // 然后处理HttpRequest流
          await for (var multipart
              in MimeMultipartTransformer(boundary).bind(request)) {
            // 然后在body里面的 filename和field 都在 multipart.headers里面 然后文件流就是multipart本身
            String? contentDisposition =
                multipart.headers['content-disposition'];
            String? filename = contentDisposition
                ?.split("; ")
                .where((item) => item.startsWith("filename="))
                .first
                .replaceFirst("filename=", "")
                .replaceAll('"', '');
            // 我这边指定txt文件，否则跳过，如果不需要就略过
            if (filename == null ||
                filename.isEmpty ||
                !filename.toLowerCase().endsWith('.zip')) {
              continue;
            }

            filename = filename.replaceAll('', '');

            try {
              Directory tempDirectory = await getTemporaryDirectory();
              var comicDirName = generateRandomString(32);
              final file = File(join(tempDirectory.path, '$comicDirName.zip'));
              if (!await file.parent.exists()) {
                await file.parent.create(recursive: true);
              }
              final sink = file.openWrite();
              await multipart.pipe(sink);
              await sink.close();

              await FileUtils.uploadZipFileByFilePath(
                  file.path, filename);
              request.response
                ..statusCode = HttpStatus.ok
                ..headers.contentType = ContentType.json
                ..write({"code": 1, "msg": "upload success"})
                ..close();
            } catch (e) {
              // 这边我直接成功，可以做其他判断
              request.response
                ..statusCode = HttpStatus.internalServerError
                ..headers.contentType = ContentType.json
                ..write({"code": 0, "msg": e.toString()})
                ..close();
            }
          }
        } else {
          // 其他请求都是404
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      }
    });
  }

  //关闭服务
  closeService() {
    for (var service in services) {
      service.close();
    }
  }
}

class UploadFilePage extends StatefulWidget {
  const UploadFilePage({super.key});

  @override
  State<UploadFilePage> createState() => _UploadFilePageState();
}

class _UploadFilePageState extends State<UploadFilePage> {
  late HttpServiceLogic logic;
  String address = '';
  List<String> addressList = [];
  final SettingController settingController = Get.find();

  @override
  void initState() {
    settingController.isSyncing.value = true;
    logic = HttpServiceLogic();
    logic.getIpv4AndIpV6Addresses().then((value) async {
      List<String> ips = await logic.startListen();

      setState(() {
        addressList = ips;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    try {
      logic.closeService();
    } finally {
      settingController.isSyncing.value = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        body: SafeArea(
            child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                color: Colors.white,
                child: Center(
                  child: Wrap(
                    direction: Axis.vertical,
                    alignment: WrapAlignment.center,
                    children: [
                      ...addressList.map((element) {
                        return Text(
                          '$element:${logic.port}',
                          style: const TextStyle(fontSize: 20),
                        );
                      }),
                      TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: const Text('返回'))
                    ],
                  ),
                ))));
  }
}
