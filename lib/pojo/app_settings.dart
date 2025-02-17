class APPSettings {
  late String appFont = "pingfang";

  static APPSettings fromMap(Map<String, dynamic> config) {
    APPSettings appSettings = APPSettings();
    appSettings.appFont = config['appFont'] ?? 'pingfang';
    return appSettings;
  }

  Map toMap() {
    return {
      'appFont': appFont,
    };
  }
}
