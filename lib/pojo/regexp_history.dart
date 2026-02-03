class RegexpHistory {
  late String id;
  late String regexp;
  late String source;
  late String example;
  late int createTime;

  Map<String, dynamic> toMap() {
    return {
      'regexp': regexp,
      'source': source,
      'example': example,
      'create_time': createTime,
      'id': id
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'regexp': regexp,
      'source': source,
      'example': example,
      'create_time': createTime,
      'id': id
    };
  }

  static RegexpHistory fromMap(Map t) {
    var regexpHistory = RegexpHistory();
    regexpHistory.createTime = int.parse(t['create_time']?.toString() ?? '0');
    regexpHistory.id = t['id']?.toString() ?? '0';
    regexpHistory.regexp = t['regexp']?.toString() ?? '';
    regexpHistory.source = t['source']?.toString() ?? '';
    regexpHistory.example = t['example']?.toString() ?? '';
    return regexpHistory;
  }

  @override
  String toString() {
    return regexp.toString();
  }
}