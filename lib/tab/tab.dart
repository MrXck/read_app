import 'package:flutter/material.dart';
import 'package:read_app/tab/book_shelf.dart';
import 'package:read_app/tab/book_source.dart';
import 'package:read_app/tab/file.dart';
import 'package:read_app/tab/my.dart';

class TabPage extends StatefulWidget {
  const TabPage({super.key});

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BookShelfPage(),
    const BookSourceTab(),
    const FileTab(),
    const MyPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 设置body
      body: _pages[_currentIndex],
      // 页面右下角悬浮按钮
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Get.toNamed("/chargeUp");
      //   },
      //   child: const Icon(Icons.add),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // 页面底部导航条
      bottomNavigationBar: BottomNavigationBar(
        // 默认选中第几个 索引 从 0 开始
        currentIndex: _currentIndex,
        // 导航条点击事件
        onTap: (current) {
          setState(() {
            _currentIndex = current;
          });
        },
        // 导航条子元素个数必须大于 1 不然会报错
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: "书架"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "书源"),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy_sharp), label: "文件"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), label: "我的"),
        ],
        // 图标大小
        iconSize: 20,
        // 图标选中时的颜色
        // fixedColor: Colors.black,
        // 如果导航栏有四个或以上元素 需要配置此项
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
