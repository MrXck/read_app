class Constant {
  static const String baseUrl = 'https://www.yuumi.cc';
  static const String getAppVersionUrl = '$baseUrl/api/version';

  // static const String syncUrl = 'http://127.0.0.1:9999';
  static const String syncUrl = 'https://www.yuumi.cc/api/readapp';

  static Map<String, String> headers = {
    'Content-Type': 'application/json'
  };

  static const String loginUrl = '$syncUrl/user/login';
  static const String registerUrl = '$syncUrl/user/register';

  static const String getAllBookUrl = '$syncUrl/book/all';
  static const String updateBookUrl = '$syncUrl/book/update';
  static const String validBookMd5Url = '$syncUrl/book/validMd5';

  static const String downloadBookUrl = '$syncUrl/file/download/';
  static const String uploadBookUrl = '$syncUrl/file/upload';

  static const int bookType = 1;
  static const int comicType = 2;
  static const int directoryType = 3;
  static const int mediaType = 4;
  static const int chapterType = 5;
  static const int outSideType = 6;
  static const int pdfType = 7;

  static const int operationAddType = 1;
  static const int operationUpdateType = 2;
  static const int operationDeleteType = 3;
  static const int operationAddRegexpType = 4;
  static const int operationDeleteRegexpType = 5;

  static const int secretType = 1;
  static const int publicType = 0;

  static const String defaultChapterTitleExp = r'^\s*?第.*?章';

  static const int defaultChapterContentMaxLength = 50000;
  static const int defaultChapterTitleMaxLength = 50;

  static const String dataKeySplitStr = '~';

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
  static int defaultBackgroundColor = 0xFFE6DBC5;

  static const String readConfigKey = 'config';
  static const String appConfigKey = 'app_config';
  static const String syncConfigKey = 'sync';
  static const String needSyncTypeKey = 'need_sync_type_list';
  static const String tokenKey = 'token';
  static const String secretKey = 'secret';

  static List<String> sortList = [
    'title asc',
    'title desc',
    '',
  ];

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
