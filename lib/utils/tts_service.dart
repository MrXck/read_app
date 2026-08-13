import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/utils/model_utils.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';

typedef Callback = Function(String text);

class TtsService {
  static final TtsService _instance = TtsService._internal();

  factory TtsService() => _instance;

  TtsService._internal();

  Isolate? _isolate;
  SendPort? _toIsolatePort; // 发送给后台的端口
  ReceivePort? _fromIsolatePort; // 接收后台消息的端口

  late AudioPlayer _player;
  Callback callback = (text) {};

  int sid = 0;
  int seq = 0;
  bool _startPlay = false;


  bool _isReady = false;
  bool _isProcessing = false;
  String _modelPath = '';
  bool _isPlaying = false;
  String _nowSpeakPath = '';
  bool _isStartSpeak = false;
  bool _isStop = false;

  // 队列管理
  final ListQueue<String> _queue = ListQueue();
  final ListQueue<Map> _audioPathQueue = ListQueue();

  /// 初始化服务：启动后台线程
  Future<void> initTTS() async {
    if (_isReady) return;

    // 1. 准备模型路径
    _modelPath = await ModelManager.modelLocalPath;

    if (!Directory(_modelPath).existsSync()) {
      return;
    }

    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) async {
      if (state == PlayerState.completed) {
        _isPlaying = false;
        if (_nowSpeakPath.isNotEmpty) {
          var file = File(_nowSpeakPath);
          if (await file.exists()) {
            await file.delete();
          }
          _nowSpeakPath = '';
        }
        if (_audioPathQueue.isNotEmpty && _isStartSpeak) {
          await _playNextInQueue();
        } else {
          callback('');
        }
      }
    });

    // 2. 创建接收端口
    _fromIsolatePort = ReceivePort();

    // 3. 启动 Isolate
    _isolate = await Isolate.spawn(_backgroundEntry, [
      _fromIsolatePort!.sendPort,
      _modelPath,
    ]);

    // 4. 监听后台消息
    _fromIsolatePort!.listen(_handleMessageFromIsolate);

    print("TTS Service：后台线程已启动，等待模型加载...");
  }

  /// 处理后台线程发来的消息
  void _handleMessageFromIsolate(dynamic message) async {
    if (message is SendPort) {
      _toIsolatePort = message;
      _isReady = true;
      _processQueue();
    } else if (message is Map) {
      // 收到的是文件路径，而不是音频数据
      if (message.containsKey('path')) {
        final path = message['path'] as String;
        final text = message['text'] as String;
        if (_isStartSpeak) {
          await _playFile(path, text); // 直接播放文件
          await _playNextInQueue();
        } else {
          if (!_isStop) {
            print('add $path');
            Map data = {
              'text': text,
              'path': path
            };
            _audioPathQueue.add(data);
          }
        }
      } else {
        // 出错处理
        _processQueue();
      }
    }
  }

  /// 对外接口：朗读
  void speak(String text, int sid) {
    _isStop = false;
    _isStartSpeak = true;
    _queue.add(text);
    this.sid = sid;
    _processQueue();
  }

  /// 处理队列
  Future<void> _processQueue() async {
    if (!_isReady || _queue.isEmpty || _isProcessing) {
      return;
    }
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final text = _queue.removeFirst();

      // --- 关键修改：在主线程计算好文件名，传给后台 ---
      final outputPath =
          '${(await getTemporaryDirectory()).path}/tts_${DateTime.now().millisecondsSinceEpoch}_$seq.wav';
      seq += 1;

      _toIsolatePort!.send({
        'text': text,
        'sid': sid,
        'outputPath': outputPath, // 把路径传下去
      });
    }
  }

  Future<void> _playNextInQueue() async {
    if (_isPlaying) {
      return;
    }
    _isPlaying = true;
    if (_audioPathQueue.isEmpty) {
      return;
    }
    var data = _audioPathQueue.removeFirst();
    var path = data['path'];
    var text = data['text'];
    _nowSpeakPath = path;
    callback(text);
    await _player.play(DeviceFileSource(path));
  }

  /// 播放音频
  Future<void> _playFile(String path, String text) async {
    if (!_startPlay) {
      _startPlay = true;
      _nowSpeakPath = path;
      callback(text);
      await _player.play(DeviceFileSource(path));
    } else {
      print('add $path');
      Map data = {
        'text': text,
        'path': path
      };
      _audioPathQueue.add(data);
    }
  }

  /// 停止
  void stop() {
    _isStop = true;
    _isStartSpeak = false;
    _startPlay = false;
    _queue.clear();
    _audioPathQueue.clear();
    _player.stop();
  }

  void pause() {
    _isStartSpeak = false;
    _player.pause();
  }

  void resume() {
    _isStop = false;
    _isStartSpeak = true;
    if (_player.state == PlayerState.completed) {
      _playNextInQueue();
    } else {
      _player.resume();
    }
  }

  void dispose() {
    if (!_isReady) return;
    _isStartSpeak = false;
    _isStop = true;
    _isReady = false;
    _isProcessing = false;
    _startPlay = false;
    _queue.clear();
    _audioPathQueue.clear();
    _isolate?.kill(priority: Isolate.immediate);
    _fromIsolatePort?.close();
    _player.dispose();
  }
}

// ==========================================
// 后台线程入口 (必须是顶层函数)
// ==========================================
void _backgroundEntry(List<dynamic> args) {
  final SendPort mainSendPort = args[0];
  final String modelPath = args[1];

  final receivePort = ReceivePort();
  // 告诉主线程通信端口
  mainSendPort.send(receivePort.sendPort);
  initBindingsAsync();

  var provider = 'cpu';

  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
      break;
    case TargetPlatform.android:
      provider = 'nnapi';
      break;
    case TargetPlatform.iOS:
      provider = 'coreml';
      break;
    default:
      break;
  }

  // 加载模型 (只加载一次)
  final vitsConfig = OfflineTtsKokoroModelConfig(
    model: join(modelPath, 'model.onnx'),
    tokens: join(modelPath, 'tokens.txt'),
    dataDir: join(modelPath, 'espeak-ng-data'),
    voices: join(modelPath, 'voices.bin'),
    dictDir: modelPath,
    lengthScale: 1.0,
    lexicon: join(modelPath, 'lexicon-zh.txt'),
    lang: 'zh'
  );
  final modelConfig = OfflineTtsModelConfig(
    kokoro: vitsConfig,
    numThreads: 4,
    provider: provider,
    debug: false,
  );

  final tts = OfflineTts(OfflineTtsConfig(model: modelConfig));

  // 监听主线程消息
  receivePort.listen((message) {
    if (message is Map) {
      final text = message['text'] as String;
      final sid = message['sid'] as int;
      // 新增：接收主线程传来的保存路径
      final outputPath = message['outputPath'] as String;

      // 1. 生成音频
      final output = tts.generate(text: text, sid: sid);

      // 2. 在后台线程直接写入文件
      _writeWavFileIsolate(output.samples, output.sampleRate, outputPath);

      // 3. 只返回路径字符串给主线程 (不再是巨大的 Float32List)
      mainSendPort.send({'path': outputPath, 'text': text});
    }
  });
}

void _writeWavFileIsolate(Float32List samples, int sampleRate, String path) {
  final file = File(path);

  // 1. 转换数据格式：Float32 -> Int16 (16-bit PCM)
  final int16Samples = Int16List(samples.length);
  for (int i = 0; i < samples.length; i++) {
    final val = (samples[i] * 32767.0).clamp(-32768.0, 32767.0);
    int16Samples[i] = val.toInt();
  }

  final bytesData = int16Samples.buffer.asUint8List();
  final dataSize = bytesData.lengthInBytes;

  // 2. 构建 WAV 文件头 (共 44 字节)
  final header = ByteData(44);

  // RIFF Chunk
  header.setUint8(0, 'R'.codeUnitAt(0));
  header.setUint8(1, 'I'.codeUnitAt(0));
  header.setUint8(2, 'F'.codeUnitAt(0));
  header.setUint8(3, 'F'.codeUnitAt(0));
  header.setUint32(4, 36 + dataSize, Endian.little);
  header.setUint8(8, 'W'.codeUnitAt(0));
  header.setUint8(9, 'A'.codeUnitAt(0));
  header.setUint8(10, 'V'.codeUnitAt(0));
  header.setUint8(11, 'E'.codeUnitAt(0));

  // fmt Subchunk
  header.setUint8(12, 'f'.codeUnitAt(0));
  header.setUint8(13, 'm'.codeUnitAt(0));
  header.setUint8(14, 't'.codeUnitAt(0));
  header.setUint8(15, ' '.codeUnitAt(0));
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);

  // data Subchunk
  header.setUint8(36, 'd'.codeUnitAt(0));
  header.setUint8(37, 'a'.codeUnitAt(0));
  header.setUint8(38, 't'.codeUnitAt(0));
  header.setUint8(39, 'a'.codeUnitAt(0));
  header.setUint32(40, dataSize, Endian.little);

  final headerBytes = header.buffer.asUint8List();

  final combinedBytes = Uint8List(headerBytes.length + bytesData.length);
  combinedBytes.setAll(0, headerBytes);
  combinedBytes.setAll(headerBytes.length, bytesData);

  file.writeAsBytesSync(combinedBytes, flush: true);
}
