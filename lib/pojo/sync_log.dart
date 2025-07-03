
class SyncLog {
  late String id;
  late int createTime;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'create_time': createTime
    };
  }

  static SyncLog fromMap(Map t) {
    var syncLog = SyncLog();
    syncLog.id = t['id']?.toString() ?? '0';
    syncLog.createTime = int.parse(t['create_time']?.toString() ?? '0');
    return syncLog;
  }
}