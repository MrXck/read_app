class UpdateData {
  late String version;
  late String url;

  static UpdateData fromMap(Map<String, dynamic> map) {
    UpdateData updateData = UpdateData();
    updateData.version = map['version'];
    updateData.url = map['url'];
    return updateData;
  }
}