import 'package:get/get.dart';
import 'package:read_app/page/comic.dart';
import 'package:read_app/page/login.dart';
import 'package:read_app/page/pdf.dart';
import 'package:read_app/page/read.dart';
import 'package:read_app/page/read_outside.dart';
import 'package:read_app/page/register.dart';
import 'package:read_app/page/search.dart';
import 'package:read_app/page/search_outside.dart';
import 'package:read_app/page/settings.dart';
import 'package:read_app/page/sync.dart';
import 'package:read_app/page/upload_file.dart';
import 'package:read_app/page/video.dart';
import 'package:read_app/tab/tab.dart';

class AppPage {
  static final routes = [
    GetPage(
      name: "/",
      page: () => const TabPage(),
    ),
    GetPage(
      name: "/uploadFile",
      page: () => const UploadFilePage(),
    ),
    GetPage(
      name: "/read",
      page: () => const ReadPage(),
    ),
    GetPage(
      name: "/search",
      page: () => const SearchPage(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 100),
    ),
    GetPage(
      name: "/search_outside",
      page: () => const SearchOutsidePage(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 100),
    ),
    GetPage(
      name: "/read_outside",
      page: () => const ReadOutSidePage(),
    ),
    GetPage(
      name: "/comic",
      page: () => const ComicPage(),
    ),
    GetPage(
      name: "/video",
      page: () => const VideoPage(),
    ),
    GetPage(
      name: "/pdf",
      page: () => const PdfPage(),
    ),
    GetPage(
      name: "/settings",
      page: () => const SettingsPage(),
    ),
    GetPage(
      name: "/sync",
      page: () => const SyncPage(),
    ),
    GetPage(
        name: "/login",
        page: () => const LoginPage(),
        transition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 200)),
    GetPage(
        name: "/register",
        page: () => const RegisterPage(),
        transition: Transition.rightToLeft,
        transitionDuration: const Duration(milliseconds: 200)),
  ];
}
