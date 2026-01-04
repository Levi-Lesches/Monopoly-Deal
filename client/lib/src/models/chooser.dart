import "dart:async";

class Chooser<T> {
  final _controller = StreamController<T>.broadcast();
  void choose(T t) => _controller.add(t);
  Future<T> get next => _controller.stream.first;
  Future<List<T>> waitFor(int n) => _controller.stream.take(n).toList();
  StreamSubscription<T> listen(void Function(T) func) => _controller.stream.listen(func);
  void cancel() => _controller.addError("Cancelled");
}
