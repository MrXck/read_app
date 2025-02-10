import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

Function callback = (double beforeVolume, double nowVolume, FlutterVolumeController controller) {};

class VolumeUtils {
  AudioSessionCategory? _audioSessionCategory;

  double _initVolume = 0.1;

  AudioStream _audioStream = AudioStream.music;

  double _currentVolume = 0.0;

  double get volume => _currentVolume;

  void init(Function callback) async {
    _initVolume = await FlutterVolumeController.getVolume() ?? 0.1;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isIOS) {
        await _loadIOSAudioSessionCategory();
      }
      if (Platform.isAndroid) {
        await _loadAndroidAudioStream();
      }
    });
    FlutterVolumeController.addListener((volume) {
      double beforeVolume = _currentVolume;
      _currentVolume = volume;
      callback(beforeVolume, volume);
    });
  }

  Future<void> _loadIOSAudioSessionCategory() async {
    final category = await FlutterVolumeController.getIOSAudioSessionCategory();
    if (category != null) {
      _audioSessionCategory = category;
    }
  }

  Future<void> _loadAndroidAudioStream() async {
    final audioStream = await FlutterVolumeController.getAndroidAudioStream();
    if (audioStream != null) {
      _audioStream = _audioStream;
    }
  }

  void removeListener({needRestore = false}) {
    FlutterVolumeController.removeListener();
    if (needRestore) {
      setVolume(_initVolume);
    }
  }

  void setVolume(double volume) {
    _currentVolume = volume;
    FlutterVolumeController.setVolume(volume);
  }
}
