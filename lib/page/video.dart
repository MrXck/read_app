import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/utils/db.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  // UI控制栏（进度条、播放、暂停按钮等，Chewiee独特的）
  late VideoPlayerController videoPlayerController;

  // 视频控制器（视频播放的核心，与video_player基本一致）
  late ChewieController chewieController;

  // 集成UI控制栏和视频播放器的组件
  late Chewie playerWidget;

  late Book book;

  ValueNotifier<String> process = ValueNotifier('');

  double startDx = 0.0;
  int changeSeconds = 0;
  int startSecond = 0;

  Future<void> init(Book book) async {
    book = await DatabaseHelper.db.getById(book.id);
    var dataDir = await getApplicationDocumentsDirectory();
    book.assetDir = dataDir.path;

    // 视频控制器，播放网络视频，播放方式可以是[networkUrl, asset, file, contentUri]
    videoPlayerController = VideoPlayerController.file(
      File(join(book.assetDir, book.path)),
    );
    // 初始化视频控制器
    await videoPlayerController.initialize();
    videoPlayerController.seekTo(Duration(seconds: book.page));

    // 初始化控制栏
    chewieController = ChewieController(
      // 控制栏UI集成视频控制器
      videoPlayerController: videoPlayerController,
      autoPlay: false, // 自动播放
      looping: false, // 循环播放
      aspectRatio: 16 / 9,
      playbackSpeeds: const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 4]
    );

    playerWidget = Chewie(
      controller: chewieController,
    );
  }

  @override
  void initState() {
    book = Get.arguments as Book;
    init(book);
    super.initState();
  }

  @override
  void dispose() {
    final duration = videoPlayerController.value.duration;
    final position = videoPlayerController.value.position;

    book.page = position.inSeconds;
    book.percent = position.inSeconds / duration.inSeconds * 100;
    DatabaseHelper.db.updateById(book);

    videoPlayerController.dispose();
    chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        body: FutureBuilder(
            future: init(book),
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
                    return Stack(
                      children: [
                        GestureDetector(
                          onTapDown: (details) {
                            final position =
                                videoPlayerController.value.position;
                            startSecond = position.inSeconds;
                            startDx = details.localPosition.dx;
                          },
                          onHorizontalDragUpdate: (details) {
                            final position =
                                videoPlayerController.value.position;

                            if (startSecond == 0) {
                              startSecond = position.inSeconds;
                            }
                            final positionX =
                                details.localPosition.dx - startDx; // 计算播放进度
                            changeSeconds = (positionX / 10).floor();
                            final now = position.inSeconds + changeSeconds;
                            process.value =
                                '${(now / 60).floor()}:${(now % 60).toString().padLeft(2, '0')}';
                          },
                          onHorizontalDragEnd: (details) {
                            videoPlayerController.seekTo(
                                Duration(seconds: startSecond + changeSeconds));
                            setState(() {
                              startDx = 0.0;
                              changeSeconds = 0;
                              startSecond = 0;
                            });
                          },
                          child: playerWidget,
                        ),
                        Positioned(
                            top: 0,
                            left: 10,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Get.back();
                                  },
                                  icon: const Icon(Icons.arrow_back_ios_new),
                                )
                              ],
                            )),
                        Positioned(
                          top: 30,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ValueListenableBuilder(
                                valueListenable: process,
                                builder: (context, value, child) {
                                  final duration =
                                      videoPlayerController.value.duration;
                                  if (changeSeconds > 0) {
                                    return Text(
                                      '$value / ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 20),
                                    );
                                  } else {
                                    return Container();
                                  }
                                }),
                          ),
                        )
                      ],
                    );
                  }
              }
            }));
  }
}
