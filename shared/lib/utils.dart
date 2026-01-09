/// A JSON object
typedef Json = Map<String, dynamic>;

typedef FromJson<T> = T Function(Json);

abstract class Serializable {
  const Serializable();
  Json toJson();
}

/// Utils on [Map].
extension MapUtils<K, V> on Map<K, V> {
  /// Gets all the keys and values as 2-element records.
	Iterable<(K, V)> get records => entries.map((entry) => (entry.key, entry.value));
}

/// Zips two lists, like Python
Iterable<(E1, E2)> zip<E1, E2>(List<E1> list1, List<E2> list2) sync* {
  if (list1.length != list2.length) throw ArgumentError("Trying to zip lists of different lengths");
  for (var index = 0; index < list1.length; index++) {
    yield (list1[index], list2[index]);
  }
}

/// Extensions on lists
extension ListUtils<E> on List<E> {
  /// Iterates over a pair of indexes and elements, like Python
  Iterable<(int, E)> get enumerate sync* {
    for (var i = 0; i < length; i++) {
      yield (i, this[i]);
    }
  }

  Iterable<E> exceptFor(E element) =>
    where((other) => other != element);

  int nextIndex(int index) {
    final result = index + 1;
    return result == length ? 0 : result;
  }

  void toggle(E element) => contains(element) ? remove(element) : add(element);
}

extension IterUtils<E> on Iterable<E> {
  E max(num Function(E) compare) =>
    reduce((a, b) => compare(a) > compare(b) ? a : b);
}

Iterable<int> range(int n) sync* {
  for (var i = 0; i < n; i++) {
    yield i;
  }
}

extension JsonUtils on Json {
  T? mapNullable<T, V>(String key, T Function(V) func) =>
    this[key] == null ? null : func(this[key] as V);

  List<T> parseList<T>(String key, T Function(Json) fromJson) => [
    for (final innerJson in (this[key] as List).cast<Json>())
      fromJson(innerJson),
  ];
}

extension NullableUtils<T> on T? {
  R? map<R>(R Function(T) func) {
    final self = this;
    return self == null ? null : func(self);
  }
}

extension SetUtils<E> on Set<E> {
  void toggle(E element) => contains(element) ? remove(element) : add(element);
}

extension StringUtils on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

T? safely<T>(T Function() func) {
  try {
    return func();
  // Intended to be a catch all
  // ignore: avoid_catches_without_on_clauses
  } catch (error) {
    return null;
  }
}
