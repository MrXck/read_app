import 'package:flutter/material.dart';
import 'package:read_app/pojo/settings.dart';

typedef UpdateFunc = void Function(Settings setting);
typedef UpdateExpFunc = void Function(String text);

class ReadSettings extends StatelessWidget {
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
                      InkWell(
                        onTap: () {
                          settings.isVer = !settings.isVer;
                          updateFunc(settings);
                        },
                        child: settings.isVer ? const Text('左右滚动') : const Text('上下滚动'),
                      ),
                      ...backgroundColorList.map((item) {
                        return InkWell(
                          onTap: () {
                            settings.backgroundColor = item;
                            updateFunc(settings);
                          },
                          child: Container(
                            height: 30,
                            width: width / 7,
                            decoration: BoxDecoration(
                                color: Color(item),
                                borderRadius:
                                const BorderRadius.all(Radius.circular(40)),
                                border: settings.backgroundColor == item
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '减宽度',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                      ),
                    ),
                    Text(
                      '减高度',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          settings.needDecreaseWidth--;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          '${settings.needDecreaseWidth}',
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.needDecreaseWidth++;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.needDecreaseHeight--;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          '${settings.needDecreaseHeight}',
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.needDecreaseHeight++;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Container(
                //   margin: const EdgeInsets.only(bottom: 10),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       const Text('内容英文大写字母除系数'),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterContentEnglishUpperStrDivisionCoefficient -=
                //               0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //                   BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '-',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //       Container(
                //         margin: const EdgeInsets.only(left: 6, right: 6),
                //         child: Text(
                //           settings
                //               .chapterContentEnglishUpperStrDivisionCoefficient
                //               .toStringAsFixed(2),
                //           style: TextStyle(
                //             fontFamily: settings.fontFamily,
                //           ),
                //         ),
                //       ),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterContentEnglishUpperStrDivisionCoefficient +=
                //               0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //                   BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '+',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // Container(
                //   margin: const EdgeInsets.only(bottom: 10),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       const Text('内容英文小写字母除系数'),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterContentEnglishLowerStrDivisionCoefficient -=
                //               0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //                   BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '-',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //       Container(
                //         margin: const EdgeInsets.only(left: 6, right: 6),
                //         child: Text(
                //           settings
                //               .chapterContentEnglishLowerStrDivisionCoefficient
                //               .toStringAsFixed(2),
                //           style: TextStyle(
                //             fontFamily: settings.fontFamily,
                //           ),
                //         ),
                //       ),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterContentEnglishLowerStrDivisionCoefficient +=
                //               0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //                   BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '+',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('内容空格除系数'),
                      InkWell(
                        onTap: () {
                          settings.chapterContentEmptyStrDivisionCoefficient -=
                              0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          settings.chapterContentEmptyStrDivisionCoefficient
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.chapterContentEmptyStrDivisionCoefficient +=
                              0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Container(
                //   margin: const EdgeInsets.only(bottom: 10),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       const Text('内容数字除系数'),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterContentNumStrDivisionCoefficient -=
                //           0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //               BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '-',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //       Container(
                //         margin: const EdgeInsets.only(left: 6, right: 6),
                //         child: Text(
                //           settings.chapterContentNumStrDivisionCoefficient
                //               .toStringAsFixed(2),
                //           style: TextStyle(
                //             fontFamily: settings.fontFamily,
                //           ),
                //         ),
                //       ),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterContentNumStrDivisionCoefficient +=
                //           0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //               BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '+',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '减去行高',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                      ),
                    ),
                    Text(
                      '字体相乘大小',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          settings.needIncreaseLineHeight -= 0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          settings.needIncreaseLineHeight.toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.needIncreaseLineHeight += 0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.needMultiFontSize -= 0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          settings.needMultiFontSize.toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.needMultiFontSize += 0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '章节标题相乘大小',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                      ),
                    ),
                    // Text(
                    //   '内容非中除系数',
                    //   style: TextStyle(
                    //     fontFamily: settings.fontFamily,
                    //   ),
                    // ),
                    InkWell(
                      onTap: () {
                        settings.chapterTitleMultiFontSize -= 0.01;
                        updateFunc(settings);
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
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 6, right: 6),
                      child: Text(
                        settings.chapterTitleMultiFontSize.toStringAsFixed(2),
                        style: TextStyle(
                          fontFamily: settings.fontFamily,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        settings.chapterTitleMultiFontSize += 0.01;
                        updateFunc(settings);
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
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Container(
                //   margin: const EdgeInsets.only(bottom: 10),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       InkWell(
                //         onTap: () {
                //           settings.chapterTitleMultiFontSize -= 0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //                   BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '-',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //       Container(
                //         margin: const EdgeInsets.only(left: 6, right: 6),
                //         child: Text(
                //           settings.chapterTitleMultiFontSize.toStringAsFixed(2),
                //           style: TextStyle(
                //             fontFamily: settings.fontFamily,
                //           ),
                //         ),
                //       ),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterTitleMultiFontSize += 0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //                   BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '+',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterContentNotChinaStrDivisionCoefficient -=
                //               0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //                   BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '-',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //       Container(
                //         margin: const EdgeInsets.only(left: 6, right: 6),
                //         child: Text(
                //           settings.chapterContentNotChinaStrDivisionCoefficient
                //               .toStringAsFixed(2),
                //           style: TextStyle(
                //             fontFamily: settings.fontFamily,
                //           ),
                //         ),
                //       ),
                //       InkWell(
                //         onTap: () {
                //           settings.chapterContentNotChinaStrDivisionCoefficient +=
                //               0.01;
                //           updateFunc(settings);
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                //           decoration: const BoxDecoration(
                //               color: Color(0xFFEAEAEA),
                //               borderRadius:
                //                   BorderRadius.all(Radius.circular(40))),
                //           child: Text(
                //             '+',
                //             style: TextStyle(
                //               fontFamily: settings.fontFamily,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '标题非中除系数',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                      ),
                    ),
                    Text(
                      '标题字数除系数',
                      style: TextStyle(
                        fontFamily: settings.fontFamily,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          settings.chapterTitleNotChinaStrDivisionCoefficient -=
                              0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          settings.chapterTitleNotChinaStrDivisionCoefficient
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.chapterTitleNotChinaStrDivisionCoefficient +=
                              0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.chapterTitleStrDivisionCoefficient -= 0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 6),
                        child: Text(
                          settings.chapterTitleStrDivisionCoefficient
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontFamily: settings.fontFamily,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          settings.chapterTitleStrDivisionCoefficient += 0.01;
                          updateFunc(settings);
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
                              fontFamily: settings.fontFamily,
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
                          fontFamily: settings.fontFamily,
                        ),
                      ),
                      SizedBox(
                        width: width - 180,
                        child: TextField(
                          controller: chapterTitleExpController,
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
                            updateExpFunc(chapterTitleExpController.text);
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
              ],
            )));
  }
}
