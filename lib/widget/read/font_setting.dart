import 'package:flutter/material.dart';
import 'package:read_app/pojo/settings.dart';

typedef UpdateFunc = void Function(Settings setting);

class ReadFontSetting extends StatelessWidget {
  final UpdateFunc updateFunc;
  final Settings settings;

  String hexToStringWithPrefix(int hexValue) {
    return hexValue.toRadixString(16);
  }

  int hexStringToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  const ReadFontSetting(
      {super.key, required this.settings, required this.updateFunc});

  @override
  Widget build(BuildContext context) {
    final List<String> fontFamilyList = [
      'pingfang',
      'hanchanbanyuanti',
      'hanchanduanheisong',
      'jiyinghuipianheyuan',
      'shiweijiatangsongti',
      'lianxiangxiaoxinheitichanggui',
      'yousheshayufeitejiankangti',
    ];
    final textController = TextEditingController();
    var size = MediaQuery.of(context).size;
    textController.text = hexToStringWithPrefix(settings.fontColor);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      height: size.height,
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: SizedBox(
          height: 352,
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '字体大小',
                    style: TextStyle(fontFamily: settings.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      settings.fontSize--;
                      updateFunc(settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: const Text(
                        'A-',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    child: Text('${settings.fontSize}'),
                  ),
                  InkWell(
                    onTap: () {
                      settings.fontSize++;
                      updateFunc(settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: const Text(
                        'A+',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '字体行高',
                    style: TextStyle(fontFamily: settings.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      settings.lineHeight -= 0.1;
                      updateFunc(settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: const Text(
                        'A-',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    child: Text((settings.lineHeight).toStringAsFixed(1)),
                  ),
                  InkWell(
                    onTap: () {
                      settings.lineHeight += 0.1;
                      updateFunc(settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: const Text(
                        'A+',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '内容字重',
                    style: TextStyle(fontFamily: settings.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      if (settings.contentFontWeight <= 0) {
                        return;
                      }
                      settings.contentFontWeight -= 1;
                      updateFunc(settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: const Text(
                        'A-',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    child: Text(settings.contentFontWeight.toString()),
                  ),
                  InkWell(
                    onTap: () {
                      if (settings.contentFontWeight >= 8) {
                        return;
                      }
                      settings.contentFontWeight += 1;
                      updateFunc(settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: const Text(
                        'A+',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '标题字重',
                    style: TextStyle(fontFamily: settings.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      if (settings.titleFontWeight <= 0) {
                        return;
                      }
                      settings.titleFontWeight -= 1;
                      updateFunc(settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: const Text(
                        'A-',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    child: Text(settings.titleFontWeight.toString()),
                  ),
                  InkWell(
                    onTap: () {
                      if (settings.titleFontWeight >= 8) {
                        return;
                      }
                      settings.titleFontWeight += 1;
                      updateFunc(settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      decoration: const BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: const Text(
                        'A+',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '字体颜色：',
                    style: TextStyle(
                      fontFamily: settings.fontFamily,
                    ),
                  ),
                  SizedBox(
                    width: size.width - 180,
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: "输入颜色",
                        hintStyle: TextStyle(color: Colors.black26),
                        contentPadding: EdgeInsets.all(0),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () async {
                        settings.fontColor = hexStringToInt(textController.text);
                        updateFunc(settings);
                      },
                      child: Text(
                        '确定',
                        style: TextStyle(
                          fontFamily: settings.fontFamily,
                        ),
                      ))
                ],
              ),
            ),
            SizedBox(
                height: 130,
                width: size.width,
                child: ListView(
                    children: fontFamilyList.map((item) {
                      return ListTile(
                          title: Text(
                            item,
                            style: TextStyle(
                                fontFamily: item,
                                color: settings.fontFamily == item
                                    ? Colors.blue
                                    : Colors.black),
                          ),
                          onTap: () {
                            settings.fontFamily = item;
                            updateFunc(settings);
                          });
                    }).toList()))
          ]),
        ),
      ),
    );
  }
}
