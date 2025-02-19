class Constant {
  static String baseUrl = 'https://www.yuumi.cc';
  static String getAppVersionUrl = '$baseUrl/api/version';

  static int bookType = 1;
  static int comicType = 2;
  static int directoryType = 3;
  static int mediaType = 4;
  static int chapterType = 5;
  static int outSideType = 6;
  static int pdfType = 7;

  static String defaultChapterTitleExp = r'^\s*?第.*?章';

  static int defaultChapterContentMaxLength = 50000;

  static String dataKeySplitStr = '~';

  static List<String> allMediaType = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'aac',
    'mp3',
    'ac3'
  ];
  static List<String> allTextType = ['txt'];
  static List<String> allPdfType = ['pdf'];
  static List<String> allFontType = ['otf', 'ttf'];

  static String readConfigKey = 'config';
  static String appConfigKey = 'app_config';

  static List<String> fontFamilyList = [
    'pingfang',
    'hanchanbanyuanti',
    'hanchanduanheisong',
    'jiyinghuipianheyuan',
    'lianxiangxiaoxinheitichanggui',
    'yousheshayufeitejiankangti',
    'DFPKingGothicGB-Light-2',
    'DFPKingGothicGB-Medium-2',
    'DFPKingGothicGB-Semibold-2',
    'HuaKangJinGangHei-Regular-2',
  ];
}
