import 'dart:async';
import 'dart:io';

import 'package:hq_video_player/hq_video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/book.dart';
import 'package:read_app/utils/db.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late HqVideoPlayerController videoPlayerController;

  late HqVideoPlayer playerWidget;

  late Book book;

  double startDx = 0.0;
  int changeSeconds = 0;
  int startSecond = 0;
  ValueNotifier<String> process = ValueNotifier('');

  Timer? _dataTimer;
  bool isReady = false;

  Future<void> updateBook() async {
    final duration = videoPlayerController.value.duration;
    final position = videoPlayerController.value.position;

    book.page = position.inSeconds;
    book.percent = (position.inSeconds / duration.inSeconds * 100).isInfinite
        ? 0
        : position.inSeconds / duration.inSeconds * 100;
    DatabaseHelper.db.updateById(book);
  }

  Future<void> init(Book book) async {
    book = await DatabaseHelper.db.getById(book.id);
    var dataDir = await getApplicationDocumentsDirectory();
    book.assetDir = dataDir.path;

    videoPlayerController = HqVideoPlayerController(
      videoUrl: File(join(book.assetDir, book.path)).path,
      sourceType: HqVideoSourceType.file,
      startAt: Duration(seconds: book.page),
    );
    videoPlayerController.addListener(() async {
      if (!isReady && videoPlayerController.value.isReady) {
        isReady = true;
        while (!videoPlayerController.value.isPlaying && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        videoPlayerController.seekTo(Duration(seconds: book.page));
      }
    });

    _dataTimer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      updateBook();
    });

    playerWidget = HqVideoPlayer(
      controller: videoPlayerController,
      config: HqVideoPlayerConfig(
        gestures: const HqVideoPlayerGestures(doubleTapSeekSeconds: 10),
        customWidgets: HqVideoPlayerCustomWidgets(
          customOverlay: Stack(
            children: [
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: process,
                    builder: (context, value, child) {
                      final duration = videoPlayerController.value.duration;
                      if (changeSeconds != 0) {
                        return Text(
                          '$value / ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 20),
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (e) {
                    startSecond =
                        videoPlayerController.value.position.inSeconds;
                    startDx = e.localPosition.dx;
                    changeSeconds = 0;
                  },
                  onPointerMove: (e) {
                    final positionX = e.localPosition.dx - startDx;
                    changeSeconds = (positionX / 10).floor();
                    final now = startSecond + changeSeconds;
                    process.value =
                        '${(now / 60).floor()}:${(now % 60).toString().padLeft(2, '0')}';
                  },
                  onPointerUp: (e) {
                    if (changeSeconds.abs() > 2) {
                      videoPlayerController.seekTo(
                        Duration(seconds: startSecond + changeSeconds),
                      );
                    }
                    changeSeconds = 0;
                    startSecond = 0;
                    process.value = '';
                  },
                  onPointerCancel: (e) {
                    changeSeconds = 0;
                    startSecond = 0;
                    process.value = '';
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    book = Get.arguments as Book;
    super.initState();
  }

  @override
  void dispose() {
    _dataTimer?.cancel();
    updateBook();

    process.dispose();
    videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: FutureBuilder(
          future: init(book),
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
                  return Stack(
                    children: [
                      playerWidget,
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
            }
          },
        ),
      ),
    );
  }
}
