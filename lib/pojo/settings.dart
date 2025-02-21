class Settings {
  late int backgroundColor = 0xFFE6DBC5;
  late double fontSize = 16;
  late double lineHeight = 1.6;
  late int needDecreaseWidth = 0;
  late int needDecreaseHeight = 0;
  late double needIncreaseLineHeight = 0.3;
  late double needMultiFontSize = 1.14;
  late double chapterTitleMultiFontSize = 1.4;
  late double chapterTitleNotChinaStrDivisionCoefficient = 1.4;
  late double chapterContentNotChinaStrDivisionCoefficient = 1.4;
  late double chapterContentEnglishUpperStrDivisionCoefficient = 1.4;
  late double chapterContentEnglishLowerStrDivisionCoefficient = 1.4;
  late double chapterContentEmptyStrDivisionCoefficient = 1.3;
  late double chapterContentNumStrDivisionCoefficient = 1.4;
  late double chapterTitleStrDivisionCoefficient = 1.5;
  late String fontFamily = 'pingfang';
  late int fontColor = 0xff000000;
  late int titleFontWeight = 7;
  late int contentFontWeight = 4;
  late bool isVer = false;
  late int titleFontColor = 0xCFCACACA;
  late bool showBottom = true;
  late bool openFlip = true;
  late double pageLeftPadding = 10;
  late double pageRightPadding = 10;
  late double pageTopPadding = 0;
  late double pageBottomPadding = 30;

  static Settings fromMap(Map<String, dynamic> config) {
    Settings settings = Settings();
    settings.backgroundColor = config['backgroundColor'] ?? 0xFFE6DBC5;
    settings.isVer = config['isVer'] ?? false;
    settings.fontSize = config['fontSize'] ?? 16;
    settings.lineHeight = config['lineHeight'] ?? 1.6;
    settings.needDecreaseWidth = config['needDecreaseWidth'] ?? 0;
    settings.needDecreaseHeight = config['needDecreaseHeight'] ?? 0;
    settings.needIncreaseLineHeight = config['needIncreaseLineHeight'] ?? 0.3;
    settings.needMultiFontSize = config['needMultiFontSize'] ?? 1.14;
    settings.chapterTitleMultiFontSize =
        config['chapterTitleMultiFontSize'] ?? 1.4;
    settings.chapterTitleNotChinaStrDivisionCoefficient =
        config['chapterTitleNotChinaStrDivisionCoefficient'] ?? 1.4;
    settings.chapterContentNotChinaStrDivisionCoefficient =
        config['chapterContentNotChinaStrDivisionCoefficient'] ?? 1.4;
    settings.chapterContentEnglishUpperStrDivisionCoefficient =
        config['chapterContentEnglishUpperStrDivisionCoefficient'] ?? 1.4;
    settings.chapterContentEnglishLowerStrDivisionCoefficient =
        config['chapterContentEnglishLowerStrDivisionCoefficient'] ?? 1.4;
    settings.chapterContentEmptyStrDivisionCoefficient =
        config['chapterContentEmptyStrDivisionCoefficient'] ?? 1.3;
    settings.chapterContentNumStrDivisionCoefficient =
        config['chapterContentNumStrDivisionCoefficient'] ?? 1.4;
    settings.chapterTitleStrDivisionCoefficient =
        config['chapterTitleStrDivisionCoefficient'] ?? 1.5;
    settings.fontFamily = config['fontFamily'] ?? 'pingfang';
    settings.fontColor = config['fontColor'] ?? 0xff000000;
    settings.titleFontWeight = config['titleFontWeight'] ?? 7;
    settings.contentFontWeight = config['contentFontWeight'] ?? 4;
    settings.titleFontColor = config['titleFontColor'] ?? 0xCFCACACA;
    settings.showBottom = config['showBottom'] ?? true;
    settings.openFlip = config['openFlip'] ?? true;
    settings.pageLeftPadding = config['pageLeftPadding'] ?? 10;
    settings.pageRightPadding = config['pageRightPadding'] ?? 10;
    settings.pageTopPadding = config['pageTopPadding'] ?? 0;
    settings.pageBottomPadding = config['pageBottomPadding'] ?? 30;
    return settings;
  }

  Map toMap() {
    return {
      'backgroundColor': backgroundColor,
      'isVer': isVer,
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'needDecreaseWidth': needDecreaseWidth,
      'needDecreaseHeight': needDecreaseHeight,
      'needIncreaseLineHeight': needIncreaseLineHeight,
      'needMultiFontSize': needMultiFontSize,
      'chapterTitleMultiFontSize': chapterTitleMultiFontSize,
      'chapterTitleNotChinaStrDivisionCoefficient':
      chapterTitleNotChinaStrDivisionCoefficient,
      'chapterContentNotChinaStrDivisionCoefficient':
      chapterContentNotChinaStrDivisionCoefficient,
      'chapterContentEnglishUpperStrDivisionCoefficient':
      chapterContentEnglishUpperStrDivisionCoefficient,
      'chapterContentEnglishLowerStrDivisionCoefficient':
      chapterContentEnglishLowerStrDivisionCoefficient,
      'chapterContentEmptyStrDivisionCoefficient':
      chapterContentEmptyStrDivisionCoefficient,
      'chapterContentNumStrDivisionCoefficient':
      chapterContentNumStrDivisionCoefficient,
      'chapterTitleStrDivisionCoefficient':
      chapterTitleStrDivisionCoefficient,
      'fontFamily': fontFamily,
      'fontColor': fontColor,
      'titleFontWeight': titleFontWeight,
      'contentFontWeight': contentFontWeight,
      'titleFontColor': titleFontColor,
      'showBottom': showBottom,
      'openFlip': openFlip,
      'pageLeftPadding': pageLeftPadding,
      'pageRightPadding': pageRightPadding,
      'pageTopPadding': pageTopPadding,
      'pageBottomPadding': pageBottomPadding,
    };
  }

}
