class Snowflake {
  // 时间戳起始点（通常是某个特定的时间戳，如某年某月某日）
  final int twepoch = DateTime(2020, 1, 1).millisecondsSinceEpoch;

  // 各部分位数分配
  final int workerIdBits = 5; // 机器 ID 占 5 位
  final int datacenterIdBits = 5; // 数据中心 ID 占 5 位
  final int sequenceBits = 12; // 序列号占 12 位

  // 生成的最大值
  final int maxWorkerId = -1 ^ (-1 << 5); // 最大的机器 ID 值
  final int maxDatacenterId = -1 ^ (-1 << 5); // 最大的数据中心 ID 值
  final int sequenceMask = -1 ^ (-1 << 12); // 最大的序列号值

  // 左移位数
  final int workerIdShift = 12; // 机器 ID 左移 12 位
  final int datacenterIdShift = 12 + 5; // 数据中心 ID 左移 17 位
  final int timestampLeftShift = 12 + 5 + 5; // 时间戳左移 22 位

  int lastTimestamp = -1; // 记录上一次生成 ID 的时间戳
  int sequence = 0; // 序列号

  final int workerId; // 机器 ID
  final int datacenterId; // 数据中心 ID

  Snowflake(this.workerId, this.datacenterId) {
    if (workerId > maxWorkerId || workerId < 0) {
      throw Exception('Worker ID 越界，必须在 0 到 $maxWorkerId 之间');
    }
    if (datacenterId > maxDatacenterId || datacenterId < 0) {
      throw Exception('Datacenter ID 越界，必须在 0 到 $maxDatacenterId 之间');
    }
  }

  // 获取当前毫秒时间戳
  int _currentTimeMillis() => DateTime.now().millisecondsSinceEpoch;

  // 生成下一个唯一 ID
  int nextId() {
    int timestamp = _currentTimeMillis();

    // 如果当前时间小于上次生成 ID 的时间，抛出异常
    if (timestamp < lastTimestamp) {
      throw Exception('时钟倒退异常，拒绝生成 ID');
    }

    // 同一毫秒内
    if (lastTimestamp == timestamp) {
      sequence = (sequence + 1) & sequenceMask;
      // 序列号溢出，等待下一毫秒
      if (sequence == 0) {
        timestamp = _waitUntilNextMillis(lastTimestamp);
      }
    } else {
      sequence = 0; // 不同毫秒内，重置序列号
    }

    lastTimestamp = timestamp;

    // 组合各部分生成唯一 ID
    return ((timestamp - twepoch) << timestampLeftShift) |
    (datacenterId << datacenterIdShift) |
    (workerId << workerIdShift) |
    sequence;
  }

  // 等待下一毫秒
  int _waitUntilNextMillis(int lastTimestamp) {
    int timestamp = _currentTimeMillis();
    while (timestamp <= lastTimestamp) {
      timestamp = _currentTimeMillis();
    }
    return timestamp;
  }
}