import 'package:flutter/material.dart';
import 'package:read_app/pojo/font_setting.dart';

typedef UpdateFunc = void Function(FontSetting fontSetting);

class ReadFontSetting extends StatelessWidget {
  final UpdateFunc updateFunc;
  final FontSetting fontSetting;

  String hexToStringWithPrefix(int hexValue) {
    return hexValue.toRadixString(16);
  }

  int hexStringToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  const ReadFontSetting(
      {super.key, required this.fontSetting, required this.updateFunc});

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
    textController.text = hexToStringWithPrefix(fontSetting.fontColor);
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
                    style: TextStyle(fontFamily: fontSetting.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      fontSetting.fontSize--;
                      updateFunc(fontSetting);
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
                    child: Text('${fontSetting.fontSize}'),
                  ),
                  InkWell(
                    onTap: () {
                      fontSetting.fontSize++;
                      updateFunc(fontSetting);
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
                    style: TextStyle(fontFamily: fontSetting.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      fontSetting.lineHeight -= 0.1;
                      updateFunc(fontSetting);
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
                    child: Text((fontSetting.lineHeight).toStringAsFixed(1)),
                  ),
                  InkWell(
                    onTap: () {
                      fontSetting.lineHeight += 0.1;
                      updateFunc(fontSetting);
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
                    style: TextStyle(fontFamily: fontSetting.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      if (fontSetting.contentFontWeight <= 0) {
                        return;
                      }
                      fontSetting.contentFontWeight -= 1;
                      updateFunc(fontSetting);
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
                    child: Text(fontSetting.contentFontWeight.toString()),
                  ),
                  InkWell(
                    onTap: () {
                      if (fontSetting.contentFontWeight >= 8) {
                        return;
                      }
                      fontSetting.contentFontWeight += 1;
                      updateFunc(fontSetting);
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
                    style: TextStyle(fontFamily: fontSetting.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      if (fontSetting.titleFontWeight <= 0) {
                        return;
                      }
                      fontSetting.titleFontWeight -= 1;
                      updateFunc(fontSetting);
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
                    child: Text(fontSetting.titleFontWeight.toString()),
                  ),
                  InkWell(
                    onTap: () {
                      if (fontSetting.titleFontWeight >= 8) {
                        return;
                      }
                      fontSetting.titleFontWeight += 1;
                      updateFunc(fontSetting);
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
                      fontFamily: fontSetting.fontFamily,
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
                        fontSetting.fontColor = hexStringToInt(textController.text);
                        updateFunc(fontSetting);
                      },
                      child: Text(
                        '确定',
                        style: TextStyle(
                          fontFamily: fontSetting.fontFamily,
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
                                color: fontSetting.fontFamily == item
                                    ? Colors.blue
                                    : Colors.black),
                          ),
                          onTap: () {
                            fontSetting.fontFamily = item;
                            updateFunc(fontSetting);
                          });
                    }).toList()))
          ]),
        ),
      ),
    );
  }
}
