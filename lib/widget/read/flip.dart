import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:read_app/pojo/settings.dart';

class ReadFlip extends StatefulWidget {
  final Settings settings;
  final Function prevFunc;
  final Function nextFunc;
  final double height;
  final double width;

  const ReadFlip({
    super.key,
    required this.settings,
    required this.prevFunc,
    required this.nextFunc,
    required this.height,
    required this.width,
  });

  @override
  State<ReadFlip> createState() => _ReadFlipState();
}

class _ReadFlipState extends State<ReadFlip> {
  Widget generateWidget() {
    var isVer = widget.settings.isVer;
    var height = widget.height;
    var width = widget.width;

    Widget generateWidget;

    List<Widget> children = [];

    if (isVer) {
      children.add(Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              widget.prevFunc();
            },
            child: Container(
              color: Colors.transparent,
              height: height / 5,
              width: width,
            ),
          )));
      children.add(Positioned(
          right: 0,
          left: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              widget.nextFunc();
            },
            child: Container(
              color: Colors.transparent,
              height: height / 5,
              width: width,
            ),
          )));
      generateWidget = Stack(
        children: children,
      );
    } else {
      children.add(Positioned(
          left: 0,
          bottom: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              widget.prevFunc();
            },
            child: Container(
              color: Colors.transparent,
              height: height,
              width: width / 5,
            ),
          )));
      children.add(Positioned(
          right: 0,
          bottom: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              widget.nextFunc();
            },
            child: Container(
              color: Colors.transparent,
              height: height,
              width: width / 5,
            ),
          )));
      generateWidget = Stack(
        children: children,
      );
    }

    return generateWidget;
  }

  @override
  Widget build(BuildContext context) {
    return generateWidget();
  }
}
