import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:read_app/utils/constant.dart';

typedef UpdateFunc = void Function(Settings setting);

class ReadFontSetting extends StatefulWidget {
  final UpdateFunc updateFunc;
  final Settings settings;

  const ReadFontSetting(
      {super.key, required this.settings, required this.updateFunc});

  @override
  State<ReadFontSetting> createState() => _ReadFontSettingState();
}

class _ReadFontSettingState extends State<ReadFontSetting> {
  List<String> fontFamilyList = [];

  String hexToStringWithPrefix(int hexValue) {
    return hexValue.toRadixString(16);
  }

  int hexStringToInt(String hex) {
    return int.parse(hex, radix: 16);
  }

  @override
  void initState() {
    initFontList();
    super.initState();
  }

  Future<void> initFontList() async {
    List<String> fontList = List.from(Constant.fontFamilyList);

    Directory directory = await getApplicationDocumentsDirectory();

    final fontPath = join(directory.path, join('read', 'font'));

    if (await Directory(fontPath).exists()) {
      List<FileSystemEntity> files = Directory(fontPath).listSync();
      for (var file in files) {
        fontList.add(basename(file.path).split('.')[0]);
      }
    }
    setState(() {
      fontFamilyList = fontList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
    var size = MediaQuery.of(context).size;
    textController.text = hexToStringWithPrefix(widget.settings.fontColor);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      height: size.height,
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: SizedBox(
          height: 380,
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '字体大小',
                    style: TextStyle(fontFamily: widget.settings.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      widget.settings.fontSize--;
                      widget.updateFunc(widget.settings);
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
                    child: Text('${widget.settings.fontSize}'),
                  ),
                  InkWell(
                    onTap: () {
                      widget.settings.fontSize++;
                      widget.updateFunc(widget.settings);
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
                    style: TextStyle(fontFamily: widget.settings.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      widget.settings.lineHeight -= 0.1;
                      widget.updateFunc(widget.settings);
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
                    child:
                        Text((widget.settings.lineHeight).toStringAsFixed(1)),
                  ),
                  InkWell(
                    onTap: () {
                      widget.settings.lineHeight += 0.1;
                      widget.updateFunc(widget.settings);
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
                    style: TextStyle(fontFamily: widget.settings.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      if (widget.settings.contentFontWeight <= 0) {
                        return;
                      }
                      widget.settings.contentFontWeight -= 1;
                      widget.updateFunc(widget.settings);
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
                    child: Text(widget.settings.contentFontWeight.toString()),
                  ),
                  InkWell(
                    onTap: () {
                      if (widget.settings.contentFontWeight >= 8) {
                        return;
                      }
                      widget.settings.contentFontWeight += 1;
                      widget.updateFunc(widget.settings);
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
                    style: TextStyle(fontFamily: widget.settings.fontFamily),
                  ),
                  InkWell(
                    onTap: () {
                      if (widget.settings.titleFontWeight <= 0) {
                        return;
                      }
                      widget.settings.titleFontWeight -= 1;
                      widget.updateFunc(widget.settings);
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
                    child: Text(widget.settings.titleFontWeight.toString()),
                  ),
                  InkWell(
                    onTap: () {
                      if (widget.settings.titleFontWeight >= 8) {
                        return;
                      }
                      widget.settings.titleFontWeight += 1;
                      widget.updateFunc(widget.settings);
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
                      fontFamily: widget.settings.fontFamily,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.defaultDialog(
                          title: '字体颜色',
                          content: ColorPicker(
                            pickerColor: Color(widget.settings.fontColor),
                            onColorChanged: (color) {
                              setState(() {
                                widget.settings.fontColor = color.value;
                              });
                            },
                            colorPickerWidth: 300,
                            pickerAreaHeightPercent: 0.7,
                            enableAlpha: true,
                            labelTypes: const [
                              ColorLabelType.hsl,
                              ColorLabelType.hsv
                            ],
                            displayThumbColor: true,
                            paletteType: PaletteType.hsl,
                            pickerAreaBorderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(2),
                            ),
                            hexInputBar: false,
                          ));
                    },
                    child: Text(
                      '颜色',
                      style: TextStyle(
                        fontFamily: widget.settings.fontFamily,
                        color: Color(widget.settings.fontColor),
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () async {
                        widget.updateFunc(widget.settings);
                      },
                      child: Text(
                        '确定',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ))
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '左上角字体颜色：',
                    style: TextStyle(
                      fontFamily: widget.settings.fontFamily,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.defaultDialog(
                          title: '左上角字体颜色',
                          content: ColorPicker(
                            pickerColor: Color(widget.settings.titleFontColor),
                            onColorChanged: (color) {
                              setState(() {
                                widget.settings.titleFontColor = color.value;
                              });
                            },
                            colorPickerWidth: 300,
                            pickerAreaHeightPercent: 0.7,
                            enableAlpha: true,
                            labelTypes: const [
                              ColorLabelType.hsl,
                              ColorLabelType.hsv
                            ],
                            displayThumbColor: true,
                            paletteType: PaletteType.hsl,
                            pickerAreaBorderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(2),
                            ),
                            hexInputBar: false,
                          ));
                    },
                    child: Text(
                      '颜色',
                      style: TextStyle(
                        fontFamily: widget.settings.fontFamily,
                        color: Color(widget.settings.titleFontColor),
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () async {
                        widget.updateFunc(widget.settings);
                      },
                      child: Text(
                        '确定',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
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
                            color: widget.settings.fontFamily == item
                                ? Colors.blue
                                : Colors.black),
                      ),
                      onTap: () {
                        widget.settings.fontFamily = item;
                        widget.updateFunc(widget.settings);
                      });
                }).toList()))
          ]),
        ),
      ),
    );
  }
}
