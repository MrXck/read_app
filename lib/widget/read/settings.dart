import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:read_app/pojo/settings.dart';

typedef UpdateFunc = void Function(Settings setting);
typedef UpdateExpFunc = void Function(String text);

class ReadSettings extends StatefulWidget {
  final Settings settings;
  final UpdateFunc updateFunc;
  final UpdateExpFunc updateExpFunc;
  final List<int> backgroundColorList;
  final TextEditingController chapterTitleExpController;

  const ReadSettings(
      {super.key,
      required this.chapterTitleExpController,
      required this.settings,
      required this.updateFunc,
      required this.updateExpFunc,
      required this.backgroundColorList});

  @override
  State<ReadSettings> createState() => _ReadSettingsState();
}

class _ReadSettingsState extends State<ReadSettings> {
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Positioned(
        bottom: 70,
        left: 0,
        right: 0,
        child: Container(
            height: 272,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white),
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '翻页模式',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ),
                      InkWell(
                          onTap: () {
                            widget.settings.isVer = false;
                            widget.updateFunc(widget.settings);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(40)),
                                border: widget.settings.isVer == false
                                    ? Border.all(
                                        color: Colors.black,
                                        style: BorderStyle.solid,
                                        width: 2)
                                    : Border.all(color: Colors.white,
                                    style: BorderStyle.solid,
                                    width: 2)),
                            child: Text(
                              '左右滚动',
                              style: TextStyle(
                                fontFamily: widget.settings.fontFamily,
                              ),
                            ),
                          )),
                      InkWell(
                          onTap: () {
                            widget.settings.isVer = true;
                            widget.updateFunc(widget.settings);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(40)),
                                border: widget.settings.isVer == true
                                    ? Border.all(
                                        color: Colors.black,
                                        style: BorderStyle.solid,
                                        width: 2)
                                    : Border.all(color: Colors.white,
                                    style: BorderStyle.solid,
                                    width: 2)),
                            child: Text(
                              '上下滚动',
                              style: TextStyle(
                                fontFamily: widget.settings.fontFamily,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '背景颜色',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ),
                      ...widget.backgroundColorList.map((item) {
                        return InkWell(
                          onTap: () {
                            widget.settings.backgroundColor = item;
                            widget.updateFunc(widget.settings);
                          },
                          child: Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                                color: Color(item),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(40)),
                                border: widget.settings.backgroundColor == item
                                    ? Border.all(
                                        color: Colors.black,
                                        style: BorderStyle.solid,
                                        width: 2)
                                    : Border.all(color: Colors.white)),
                          ),
                        );
                      })
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '背景颜色',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.defaultDialog(
                              title: '背景颜色',
                              content: ColorPicker(
                                pickerColor:
                                Color(widget.settings.backgroundColor),
                                onColorChanged: (color) {
                                  setState(() {
                                    widget.settings.backgroundColor =
                                        color.value;
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
                            color: Color(widget.settings.backgroundColor),
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
                        '底部时间',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ),
                      InkWell(
                          onTap: () {
                            widget.settings.showBottom = false;
                            widget.updateFunc(widget.settings);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                borderRadius:
                                const BorderRadius.all(Radius.circular(40)),
                                border: widget.settings.showBottom == false
                                    ? Border.all(
                                    color: Colors.black,
                                    style: BorderStyle.solid,
                                    width: 2)
                                    : Border.all(color: Colors.white,
                                    style: BorderStyle.solid,
                                    width: 2)),
                            child: Text(
                              '隐藏',
                              style: TextStyle(
                                fontFamily: widget.settings.fontFamily,
                              ),
                            ),
                          )),
                      InkWell(
                          onTap: () {
                            widget.settings.showBottom = true;
                            widget.updateFunc(widget.settings);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                borderRadius:
                                const BorderRadius.all(Radius.circular(40)),
                                border: widget.settings.showBottom == true
                                    ? Border.all(
                                    color: Colors.black,
                                    style: BorderStyle.solid,
                                    width: 2)
                                    : Border.all(color: Colors.white,
                                    style: BorderStyle.solid,
                                    width: 2)),
                            child: Text(
                              '显示',
                              style: TextStyle(
                                fontFamily: widget.settings.fontFamily,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('内容空格除系数'),
                      InkWell(
                        onTap: () {
                          widget.settings
                                  .chapterContentEmptyStrDivisionCoefficient -=
                              0.01;
                          widget.updateFunc(widget.settings);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40))),
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontFamily: widget.settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          widget.settings
                              .chapterContentEmptyStrDivisionCoefficient
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: widget.settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings
                                  .chapterContentEmptyStrDivisionCoefficient +=
                              0.01;
                          widget.updateFunc(widget.settings);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40))),
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontFamily: widget.settings.fontFamily,
                            ),
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
                        '章节标题乘大小',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.chapterTitleMultiFontSize -= 0.01;
                          widget.updateFunc(widget.settings);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                              BorderRadius.all(Radius.circular(40))),
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontFamily: widget.settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          widget.settings.chapterTitleMultiFontSize
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: widget.settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.chapterTitleMultiFontSize += 0.01;
                          widget.updateFunc(widget.settings);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                              BorderRadius.all(Radius.circular(40))),
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontFamily: widget.settings.fontFamily,
                            ),
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
                        '标题非中除系数',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings
                              .chapterTitleNotChinaStrDivisionCoefficient -=
                          0.01;
                          widget.updateFunc(widget.settings);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                              BorderRadius.all(Radius.circular(40))),
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontFamily: widget.settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          widget.settings
                              .chapterTitleNotChinaStrDivisionCoefficient
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: widget.settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings
                              .chapterTitleNotChinaStrDivisionCoefficient +=
                          0.01;
                          widget.updateFunc(widget.settings);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                              BorderRadius.all(Radius.circular(40))),
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontFamily: widget.settings.fontFamily,
                            ),
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
                        '标题字数除系数',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.chapterTitleStrDivisionCoefficient -=
                              0.01;
                          widget.updateFunc(widget.settings);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40))),
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontFamily: widget.settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          widget.settings.chapterTitleStrDivisionCoefficient
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: widget.settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.chapterTitleStrDivisionCoefficient +=
                              0.01;
                          widget.updateFunc(widget.settings);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40))),
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontFamily: widget.settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 10),
                  width: double.infinity,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '章节正则：',
                        style: TextStyle(
                          fontFamily: widget.settings.fontFamily,
                        ),
                      ),
                      SizedBox(
                        width: width - 180,
                        child: TextField(
                          controller: widget.chapterTitleExpController,
                          decoration: const InputDecoration(
                            hintText: "输入正则匹配章节名",
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
                            widget.updateExpFunc(
                                widget.chapterTitleExpController.text);
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
              ],
            )));
  }
}
