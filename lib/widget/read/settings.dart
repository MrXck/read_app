import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:read_app/pojo/regexp_history.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/pojo/status.dart';
import 'package:read_app/utils/color_utils.dart';
import 'package:read_app/utils/db.dart';
import 'package:read_app/utils/tts_service.dart';

typedef UpdateFunc = void Function(Settings setting);
typedef UpdateExpFunc = void Function(String text);
typedef StartSpeak = void Function();

class ReadSettings extends StatefulWidget {
  final Settings settings;
  final UpdateFunc updateFunc;
  final UpdateExpFunc updateExpFunc;
  final StartSpeak startSpeak;
  final List<int> backgroundColorList;
  final TextEditingController chapterTitleExpController;
  final Status status;

  const ReadSettings(
      {super.key,
      required this.chapterTitleExpController,
      required this.settings,
      required this.updateFunc,
      required this.updateExpFunc,
      required this.backgroundColorList,
      required this.startSpeak,
      required this.status
      });

  @override
  State<ReadSettings> createState() => _ReadSettingsState();
}

class _ReadSettingsState extends State<ReadSettings> {

  void _regexOnPressed() async {
    List<RegexpHistory> regexpHistories =
    await DatabaseHelper.db.getAllRegexpHistory();
    var regexpOptions =
    regexpHistories.map((toElement) {
      return toElement.regexp;
    }).toList();
    ScrollController controller = ScrollController();
    await Get.defaultDialog(
        title: '章节正则',
        content: Autocomplete<String>(
          optionsBuilder:
              (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return regexpOptions;
            }

            // 过滤匹配的选项
            final filtered =
            regexpOptions.where((option) {
              return option.toLowerCase().contains(
                  textEditingValue.text
                      .toLowerCase());
            }).toList();

            // 如果用户输入的内容不在选项中，添加到列表末尾
            final userInput = textEditingValue.text;
            if (!filtered.contains(userInput) &&
                !regexpOptions.contains(userInput)) {
              filtered.add(userInput);
            }
            return filtered;
          },
          fieldViewBuilder: (
              BuildContext context,
              TextEditingController fieldController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted,
              ) {
            fieldController.text =
                widget.chapterTitleExpController.text;
            return TextFormField(
              controller: fieldController,
              focusNode: fieldFocusNode,
              decoration: const InputDecoration(
                labelText: '搜索或输入',
                hintText: '输入章节名正则',
                border: OutlineInputBorder(),
                suffixIcon:
                Icon(Icons.arrow_drop_down),
              ),
            );
          },
          optionsViewBuilder:
              (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius:
                BorderRadius.circular(8),
                child: SizedBox(
                  height: MediaQuery.of(context)
                      .size
                      .height *
                      0.3, // 固定高度
                  width: MediaQuery.of(context)
                      .size
                      .width *
                      0.8, // 设置宽度
                  child: Scrollbar(
                    thumbVisibility: true, // 始终显示滚动条
                    controller: controller,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      controller: controller,
                      itemBuilder: (context, index) {
                        final option =
                        options.elementAt(index);
                        return InkWell(
                          onTap: () =>
                              onSelected(option),
                          child: Container(
                            padding: const EdgeInsets
                                .symmetric(
                                vertical: 12,
                                horizontal: 16),
                            decoration: BoxDecoration(
                              border: index <
                                  options.length -
                                      1
                                  ? Border(
                                bottom: BorderSide(
                                    color: Colors
                                        .grey
                                        .shade200),
                              )
                                  : null,
                            ),
                            child: ListTile(
                              leading: Text(
                                  index.toString()),
                              title: Text(option),
                              trailing: IconButton(
                                  onPressed:
                                      () async {
                                    await DatabaseHelper
                                        .db
                                        .deleteRegexpHistoryByRegexp(
                                        option);
                                    regexpOptions
                                        .remove(
                                        option);
                                    // OperationLog
                                    //     operationLog =
                                    //     OperationLog.setRegexpOperationLog(
                                    //         Constant
                                    //             .operationDeleteRegexpType,
                                    //         widget
                                    //             .chapterTitleExpController
                                    //             .text);
                                    // DatabaseHelper.db
                                    //     .insertOperationLog(
                                    //         operationLog);
                                  },
                                  icon: const Icon(Icons
                                      .delete_forever)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
          onSelected: (String selected) {
            widget.chapterTitleExpController.text =
                selected;
          },
        ),
        onConfirm: () async {
          widget.updateExpFunc(
              widget.chapterTitleExpController.text);

          var regexpHistories = await DatabaseHelper
              .db
              .getRegexpHistoryByRegexp(widget
              .chapterTitleExpController.text);
          if (regexpHistories.isEmpty) {
            RegexpHistory regexpHistory =
            RegexpHistory();
            regexpHistory.regexp =
                widget.chapterTitleExpController.text;
            regexpHistory.createTime =
                DateTime.now().millisecondsSinceEpoch;
            await DatabaseHelper.db
                .insertRegexpHistory(regexpHistory);
            // OperationLog operationLog =
            //     OperationLog.setRegexpOperationLog(
            //         Constant.operationAddRegexpType,
            //         widget.chapterTitleExpController
            //             .text);
            // DatabaseHelper.db
            //     .insertOperationLog(operationLog);
          }

          Get.back();
        },
        textConfirm: '确定',
        textCancel: '取消');
    controller.dispose();
  }

  ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  ValueNotifier<bool> isPause = ValueNotifier(false);

  void init() {
    isSpeaking.value = widget.status.isSpeaking;
    isPause.value = widget.status.isPause;
  }

  @override
  void initState() {
    init();
    super.initState();
  }

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
            decoration: BoxDecoration(
              color: ColorUtils.returnDefaultColor(widget.settings.backgroundColor),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '翻页模式',
                      ),
                      InkWell(
                          onTap: () {
                            widget.settings.isVer = false;
                            widget.settings.isFlip = false;
                            widget.updateFunc(widget.settings);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(40)),
                                border: widget.settings.isVer == false && widget.settings.isFlip == false
                                    ? Border.all(
                                        color: Colors.black,
                                        style: BorderStyle.solid,
                                        width: 2)
                                    : Border.all(
                                        color: Colors.white,
                                        style: BorderStyle.solid,
                                        width: 2)),
                            child: Text(
                              '左右',
                              style: TextStyle(
                                fontFamily: widget.settings.fontFamily,
                              ),
                            ),
                          )),
                      InkWell(
                          onTap: () {
                            widget.settings.isVer = true;
                            widget.settings.isFlip = false;
                            widget.updateFunc(widget.settings);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(40)),
                                border: widget.settings.isVer == true && widget.settings.isFlip == false
                                    ? Border.all(
                                        color: Colors.black,
                                        style: BorderStyle.solid,
                                        width: 2)
                                    : Border.all(
                                        color: Colors.white,
                                        style: BorderStyle.solid,
                                        width: 2)),
                            child: Text(
                              '上下',
                              style: TextStyle(
                                fontFamily: widget.settings.fontFamily,
                              ),
                            ),
                          )),
                      InkWell(
                          onTap: () {
                            widget.settings.isFlip = true;
                            widget.updateFunc(widget.settings);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                borderRadius:
                                const BorderRadius.all(Radius.circular(40)),
                                border: widget.settings.isFlip == true
                                    ? Border.all(
                                    color: Colors.black,
                                    style: BorderStyle.solid,
                                    width: 2)
                                    : Border.all(
                                    color: Colors.white,
                                    style: BorderStyle.solid,
                                    width: 2)),
                            child: Text(
                              '仿真',
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
                      const Text(
                        '背景颜色',
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
                      const Text(
                        '背景颜色',
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
                      const Text(
                        '底部时间',
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
                                    : Border.all(
                                        color: Colors.white,
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
                                    : Border.all(
                                        color: Colors.white,
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
                      const Text(
                        '两侧翻页',
                      ),
                      Switch.adaptive(
                          value: widget.settings.openFlip,
                          onChanged: (value) {
                            widget.settings.openFlip = value;
                            widget.updateFunc(widget.settings);
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
                        '字间距',
                        style: TextStyle(fontFamily: widget.settings.fontFamily),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.letterSpacing -= 0.1;
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
                        Text((widget.settings.letterSpacing).toStringAsFixed(1)),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.letterSpacing += 0.1;
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
                      const Text('页面上边距'),
                      InkWell(
                        onTap: () {
                          widget.settings.pageTopPadding -= 1;
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
                          widget.settings.pageTopPadding.toString(),
                          style: TextStyle(
                            fontFamily: widget.settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.pageTopPadding += 1;
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
                      const Text('页面左边距'),
                      InkWell(
                        onTap: () {
                          widget.settings.pageLeftPadding -= 1;
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
                          widget.settings.pageLeftPadding.toString(),
                          style: TextStyle(
                            fontFamily: widget.settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.pageLeftPadding += 1;
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
                      const Text('页面下边距'),
                      InkWell(
                        onTap: () {
                          widget.settings.pageBottomPadding -= 1;
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
                          widget.settings.pageBottomPadding.toString(),
                          style: TextStyle(
                            fontFamily: widget.settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.pageBottomPadding += 1;
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
                      const Text('页面右边距'),
                      InkWell(
                        onTap: () {
                          widget.settings.pageRightPadding -= 1;
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
                          widget.settings.pageRightPadding.toString(),
                          style: TextStyle(
                            fontFamily: widget.settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          widget.settings.pageRightPadding += 1;
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
                      const Text(
                        '有声',
                      ),
                      ValueListenableBuilder(valueListenable: isSpeaking, builder: (BuildContext context, bool value, Widget? child) {
                        if (value) {
                          return Container(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                            decoration: const BoxDecoration(
                                color: Color(0xFF353535),
                                borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                            child: const Icon(Icons.play_arrow, size: 18,),
                          );
                        }
                        return InkWell(
                          onTap: () {
                            if (widget.status.isPause) {
                              TtsService().resume();
                              widget.status.isPause = false;
                              widget.status.isSpeaking = true;
                              isSpeaking.value = true;
                              isPause.value = false;
                              return;
                            }

                            if (!widget.status.isSpeaking) {
                              widget.startSpeak();
                              widget.status.isSpeaking = true;
                              isSpeaking.value = true;
                              widget.status.isStartSpeak = true;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                            decoration: const BoxDecoration(
                                color: Color(0xFFEAEAEA),
                                borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                            child: const Icon(Icons.play_arrow, size: 18,),
                          ),
                        );
                      }),
                      ValueListenableBuilder(valueListenable: isPause, builder: (BuildContext context, bool value, Widget? child) {
                        if (value) {
                          return Container(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                            decoration: const BoxDecoration(
                                color: Color(0xFF353535),
                                borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                            child: const Icon(Icons.pause, size: 18,),
                          );
                        }
                        return InkWell(
                          onTap: () {
                            if (widget.status.isSpeaking && !widget.status.isPause) {
                              TtsService().pause();
                              widget.status.isPause = true;
                              isPause.value = true;
                              widget.status.isStartSpeak = false;
                              isSpeaking.value = false;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                            decoration: const BoxDecoration(
                                color: Color(0xFFEAEAEA),
                                borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                            child: const Icon(Icons.pause, size: 18,),
                          ),
                        );
                      }),
                      ValueListenableBuilder(valueListenable: isSpeaking, builder: (BuildContext context, bool value, Widget? child) {
                        if (!value) {
                          return Container(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                            decoration: const BoxDecoration(
                                color: Color(0xFF353535),
                                borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                            child: const Icon(Icons.stop_circle_sharp, size: 18,),
                          );
                        }
                        return InkWell(
                          onTap: () {
                            if (widget.status.isSpeaking) {
                              TtsService().stop();
                              widget.status.isSpeaking = false;
                              widget.status.isPause = false;
                              isSpeaking.value = false;
                              isPause.value = false;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                            decoration: const BoxDecoration(
                                color: Color(0xFFEAEAEA),
                                borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                            child: const Icon(Icons.stop_circle_sharp, size: 18,),
                          ),
                        );
                      }),
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
                      const Text(
                        '章节正则：',
                      ),
                      SizedBox(
                        width: width - 100,
                        child: TextButton(
                            onPressed: _regexOnPressed,
                            child: Text(widget.chapterTitleExpController.text)),
                      ),
                    ],
                  ),
                ),
              ],
            )));
  }
}
