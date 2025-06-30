class UpdateData {
  late String version;
  late String url;
  late String windowsUrl;
  late List<String> versionDesc;

  static UpdateData fromMap(Map<String, dynamic> map) {
    UpdateData updateData = UpdateData();
    updateData.version = map['version'];
    updateData.url = map['url'];
    updateData.windowsUrl = map['windowsUrl'];
    updateData.versionDesc = List.from(map['versionDesc']);
    return updateData;
  }
}