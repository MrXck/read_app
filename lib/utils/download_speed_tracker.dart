class DownloadSpeedTracker {
  int _lastCount = 0;
  double _lastSpeed = 0;
  final double _alpha;
  final Stopwatch _stopwatch = Stopwatch()..start();

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  DownloadSpeedTracker({this._alpha = 0.3});

  /// 返回平滑后的速度（bytes/s）
  double onProgress(int count) {
    final elapsed = _stopwatch.elapsedMicroseconds / 1e6; // 微秒精度

    // 间隔太短，不值得计算，返回上次结果
    if (elapsed < 0.05) return _lastSpeed;

    final delta = count - _lastCount;
    _lastCount = count;
    _stopwatch.reset();
    _stopwatch.start();

    // count 回退（重试/续传重置），直接重新开始统计
    if (delta < 0) return _lastSpeed = 0;

    final instant = delta / elapsed; // bytes/s

    // 指数移动平均（EMA）平滑，消除突发抖动
    _lastSpeed = _lastSpeed == 0
        ? instant
        : _lastSpeed + (instant - _lastSpeed) * _alpha;

    return _lastSpeed;
  }

  void reset() {
    _stopwatch.reset();
    _stopwatch.start();
    _lastCount = 0;
    _lastSpeed = 0;
  }
}
