class RegexUtils {
  static int matchNotChinaStr(String text) {
    RegExp regex = RegExp(
      r"[^\u4e00-\u9fff\u3400-\u4DBF\u2000-\u2A6D\u2A70-\u2B73\u2B74-\u2B81\u2B82-\u2CEA\uFF01-\uFF60\uFF65-\uFF9F\u2026\u2014\uFF5E\u3010-\u301F\u2E80-\u2EFFa-zA-Z0-9\s]"
    );
    Iterable<Match> matches = regex.allMatches(text);
    return matches.length;
  }

  static int matchNumStr(String text) {
    RegExp regex = RegExp(r"[0-9]"
    );
    Iterable<Match> matches = regex.allMatches(text);
    return matches.length;
  }

  static int matchEnglishUpperStr(String text) {
    RegExp regex = RegExp(r"[A-Z]");
    Iterable<Match> matches = regex.allMatches(text);
    return matches.length;
  }

  static int matchEnglishLowerStr(String text) {
    RegExp regex = RegExp(r"[a-z]");
    Iterable<Match> matches = regex.allMatches(text);
    return matches.length;
  }

  static int matchEmptyStr(String text) {
    RegExp regex = RegExp(r"\s");
    Iterable<Match> matches = regex.allMatches(text);
    return matches.length;
  }
}