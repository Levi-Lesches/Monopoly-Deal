import "dart:async";

import "package:flutter/foundation.dart";
import "package:shared/utils.dart";

class Chooser<T> with ChangeNotifier {
  final _controller = StreamController<T>.broadcast();
  Future<T> get next => _controller.stream.first;
  Future<List<T>> waitFor(int n) => _controller.stream.take(n).toList();
  // StreamSubscription<T> listen(void Function(T) func) => _controller.stream.listen(func);
  void cancel() => _controller.addError("Cancelled");

  Completer<List<T>>? _listCompleter;
  List<T> values = [];
  Future<List<T>> waitForList() {
    if (_listCompleter != null) throw StateError("Already waiting");
    values.clear();
    _listCompleter = Completer();
    return _listCompleter!.future;
  }

  void choose(T t) {
    if (_listCompleter == null) {
      _controller.add(t);
    } else {
      values.toggle(t);
      notifyListeners();
    }
  }

  void confirmList() {
    _listCompleter?.complete(values.toList());
    values.clear();
    _listCompleter = null;
  }
}
