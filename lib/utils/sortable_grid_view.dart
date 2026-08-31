import 'package:flutter/material.dart';

typedef CanAccept = bool Function(int oldIndex, int newIndex);
typedef DataWidgetBuilder = Widget Function(BuildContext context, dynamic data);
typedef DragEnd<T> = void Function(List<T> dataList);
typedef DragStart = void Function();

class SortableGridView<T extends HasId> extends StatefulWidget {
  final List<T> dataList;
  final DataWidgetBuilder itemBuilder;
  final CanAccept canAccept;
  final DragEnd<T> dragEnd;
  final DragStart dragStart;
  final double itemWidth;
  final double itemHeight;
  final List<double> itemPadding;
  final List<double> itemMargin;
  final Duration duration;

  const SortableGridView(
    this.dataList, {
    super.key,
    this.duration = const Duration(milliseconds: 100),
    required this.itemPadding,
    required this.itemMargin,
    required this.itemWidth,
    required this.itemHeight,
    required this.itemBuilder,
    required this.canAccept,
    required this.dragEnd,
    required this.dragStart,
  });

  @override
  State<StatefulWidget> createState() => _SortableGridViewState<T>();
}

class _SortableGridViewState<T extends HasId> extends State<SortableGridView>
    with TickerProviderStateMixin {
  late List<T> _dataList;

  late List<T> _dataListBackUp = [];

  Map<String, Map<String, double>> _positionMap = {};

  late ScrollController _scrollController;

  final ValueNotifier<int> _renderIndex = ValueNotifier(0);

  late int columnNum;
  late double height;

  @override
  void initState() {
    _scrollController = ScrollController();
    // 添加监听器以获取滚动位置
    _scrollController.addListener(() {
      var temp = (_scrollController.offset / widget.itemHeight).ceil() * columnNum;
      if ((temp - _renderIndex.value).abs() > columnNum * 2) {
        _renderIndex.value = temp;
      }
    });
    _dataList = widget.dataList.cast<T>();
    _dataListBackUp = _dataList.sublist(0);
    super.initState();
  }

  int _calcColumnNum(double width) {
    var totalWidth = widget.itemWidth +
        widget.itemPadding[0] +
        widget.itemPadding[2] +
        widget.itemMargin[0] +
        widget.itemMargin[2];

    return (width / totalWidth).floor();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var width = size.width;
    height = size.height;
    columnNum = _calcColumnNum(width);

    if (_positionMap.isEmpty) {
      _positionMap = _calcPosition(_dataListBackUp, columnNum);
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height: (_dataList.length / columnNum).ceil() *
            (widget.itemHeight +
                widget.itemPadding[1] +
                widget.itemPadding[3] +
                widget.itemMargin[1] +
                widget.itemMargin[3]),
        child: RepaintBoundary(
          child: Stack(
            children: _generateWidget(columnNum),
          ),
        ),
      ),
    );
  }

  List<Widget> _generateWidget(int columnNum) {
    List<Widget> widgetList = [];

    for (var i = 0; i < _dataList.length; i++) {
      var data = _dataList[i];
      widgetList.add(_buildSortableWidget(data, i, columnNum));
    }

    return widgetList;
  }

  Map<String, Map<String, double>> _calcPosition(
      List<T> dataList, int columnNum) {
    Map<String, Map<String, double>> positionMap = {};
    for (var index = 0; index < dataList.length; index++) {
      var top = 0.0;
      var left = 0.0;

      var totalHeight = widget.itemHeight +
          widget.itemPadding[1] +
          widget.itemPadding[3] +
          widget.itemMargin[1] +
          widget.itemMargin[3];
      var totalWidth = widget.itemWidth +
          widget.itemPadding[0] +
          widget.itemPadding[2] +
          widget.itemMargin[0] +
          widget.itemMargin[2];

      var lineNum = (index / columnNum).floor();
      if (index % columnNum == 0) {
        top = lineNum * totalHeight;
      } else {
        var lineNum = (index / columnNum).floor();
        if (index % columnNum == 1) {
          top = lineNum * totalHeight;
          left = totalWidth;
        } else {
          top = lineNum * totalHeight;
          left = totalWidth * (index % columnNum);
        }
      }

      positionMap[dataList[index].id] = {
        'top': top,
        'left': left,
      };
    }
    return positionMap;
  }

  Widget _buildSortableWidget(T data, int index, int columnNum) {
    return ValueListenableBuilder(
        valueListenable: _renderIndex,
        builder: (context, value, child) {
          if (_renderIndex.value - columnNum * 5 > _dataListBackUp.indexOf(data) ||
              _renderIndex.value + columnNum * 5 < _dataListBackUp.indexOf(data)) {
            return const Offstage(
              offstage: true,
              child: SizedBox.shrink(),
            );
          }

          return AnimatedPositioned(
              left: _positionMap[data.id]?['left'],
              top: _positionMap[data.id]?['top'],
              duration: widget.duration,
              child: LongPressDraggable<T>(
                data: data,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: widget.itemWidth,
                    height: widget.itemHeight,
                    child: widget.itemBuilder(context, data),
                  ),
                ),
                onDragStarted: () {
                  widget.dragStart();
                },
                onDraggableCanceled: (Velocity velocity, Offset offset) {
                  widget.dragEnd(_dataListBackUp);
                },
                onDragCompleted: () {
                  widget.dragEnd(_dataListBackUp);
                },
                onDragUpdate: (details) {
                  print(details);
                },
                // childWhenDragging: Material(
                //   color: Colors.transparent,
                //   child: Container(
                //     margin: EdgeInsets.fromLTRB(
                //         widget.itemMargin[0],
                //         widget.itemMargin[1],
                //         widget.itemMargin[2],
                //         widget.itemMargin[3]),
                //     padding: EdgeInsets.fromLTRB(
                //         widget.itemPadding[0],
                //         widget.itemPadding[1],
                //         widget.itemPadding[2],
                //         widget.itemPadding[3]),
                //     height: widget.itemHeight +
                //         widget.itemPadding[1] +
                //         widget.itemPadding[3] +
                //         widget.itemMargin[1] +
                //         widget.itemMargin[3],
                //     width: widget.itemWidth +
                //         widget.itemPadding[0] +
                //         widget.itemPadding[2] +
                //         widget.itemMargin[0] +
                //         widget.itemMargin[2],
                //     child: widget.itemBuilder(context, data),
                //   ),
                // ),
                childWhenDragging: Container(),
                child: Container(
                  height: widget.itemHeight +
                      widget.itemPadding[1] +
                      widget.itemPadding[3] +
                      widget.itemMargin[1] +
                      widget.itemMargin[3],
                  width: widget.itemWidth +
                      widget.itemPadding[0] +
                      widget.itemPadding[2] +
                      widget.itemMargin[0] +
                      widget.itemMargin[2],
                  margin: EdgeInsets.fromLTRB(
                      widget.itemMargin[0],
                      widget.itemMargin[1],
                      widget.itemMargin[2],
                      widget.itemMargin[3]),
                  padding: EdgeInsets.fromLTRB(
                      widget.itemPadding[0],
                      widget.itemPadding[1],
                      widget.itemPadding[2],
                      widget.itemPadding[3]),
                  child: DragTarget<T>(
                    builder: (context, candidateData, rejectedData) {
                      return widget.itemBuilder(context, data);
                    },
                    onAcceptWithDetails: (details) {
                      setState(() {
                        _dataList = _dataListBackUp.sublist(0);
                      });
                    },
                    onWillAcceptWithDetails: (details) {
                      var oldIndex = _dataListBackUp.indexOf(details.data);
                      var newIndex = _dataListBackUp.indexOf(data);
                      final accept = widget.canAccept(oldIndex, newIndex);

                      if (!accept) {
                        return false;
                      }

                      setState(() {
                        _dataListBackUp.remove(details.data);
                        _dataListBackUp.insert(newIndex, details.data);
                        _positionMap = _calcPosition(_dataListBackUp, columnNum);
                      });

                      return true;
                    },
                    onLeave: (details) {},
                    onMove: (details) {},
                  ),
                ),
              ));
        });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class HasId extends Object {
  late final String id;
}
