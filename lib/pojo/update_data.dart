class UpdateData {
  late String version;
  late String url;
  late String versionDesc;

  static UpdateData fromMap(Map<String, dynamic> map) {
    UpdateData updateData = UpdateData();
    updateData.version = map['version'];
    updateData.url = map['url'];
    updateData.versionDesc = map['versionDesc'];
    return updateData;
  }
}