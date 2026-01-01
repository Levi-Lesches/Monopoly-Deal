import "dart:async";

class Chooser<T> {
  final _controller = StreamController<T>.broadcast();
  void choose(T t) => _controller.add(t);
  Future<T> get next => _controller.stream.first;
}
