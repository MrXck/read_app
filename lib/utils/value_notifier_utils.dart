import 'package:flutter/foundation.dart';

/// 内容变化也会通知的 ValueNotifier<List<T>>
class ListValueNotifier<T> extends ValueNotifier<List<T>> {
  ListValueNotifier(super._value);

  @override
  set value(List<T> newValue) {
    // 内容级比较：内容一样就不通知，避免无意义的重建
    if (listEquals(value, newValue)) return;
    super.value = newValue;
  }

  // ---------- 便捷的修改方法，修改后自动通知 ----------

  void add(T item) => value = [...value, item];

  void remove(T item) => value = value.where((e) => e != item).toList();

  void removeAt(int index) {
    final list = [...value];
    list.removeAt(index);
    value = list;
  }

  void insert(int index, T item) {
    final list = [...value];
    list.insert(index, item);
    value = list;
  }

  bool contains(T item) => value.contains(item);

  void clear() => value = [];

  /// 原地修改后手动触发通知（比如你在外部直接改了 list）
  void refresh() => notifyListeners();
}