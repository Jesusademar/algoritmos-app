import 'dart:collection';

/// Vector persistente: cada escritura comparte los demás tramos de la lista.
/// Una comparación guarda una referencia, sin copiar todos los números.
class SortingArray extends ListBase<Object> {
  SortingArray(List<Object> values)
    : _length = values.length,
      _root = values.isEmpty ? null : _Node.build(values, 0, values.length);
  final int _length;
  _Node? _root;
  @override
  int get length => _length;
  @override
  set length(int value) => throw UnsupportedError('Longitud fija');
  @override
  Object operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return _root!.at(index, 0, length);
  }

  @override
  void operator []=(int index, Object value) {
    RangeError.checkValidIndex(index, this);
    _root = _root!.withValue(index, value, 0, length);
  }

  List<Object> get snapshot => _Snapshot(_root, length);
}

class _Snapshot extends ListBase<Object> {
  _Snapshot(this.root, this._length);
  final _Node? root;
  final int _length;
  @override
  int get length => _length;
  @override
  set length(int value) => throw UnsupportedError('Instantánea inmutable');
  @override
  void operator []=(int index, Object value) =>
      throw UnsupportedError('Instantánea inmutable');
  @override
  Object operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return root!.at(index, 0, length);
  }
}

class _Node {
  const _Node({this.value, this.left, this.right});
  final Object? value;
  final _Node? left;
  final _Node? right;
  static _Node build(List<Object> values, int start, int end) {
    if (end - start == 1) return _Node(value: values[start]);
    final middle = (start + end) ~/ 2;
    return _Node(
      left: build(values, start, middle),
      right: build(values, middle, end),
    );
  }

  Object at(int index, int start, int end) {
    if (end - start == 1) return value!;
    final middle = (start + end) ~/ 2;
    return index < middle
        ? left!.at(index, start, middle)
        : right!.at(index, middle, end);
  }

  _Node withValue(int index, Object number, int start, int end) {
    if (end - start == 1) return _Node(value: number);
    final middle = (start + end) ~/ 2;
    return index < middle
        ? _Node(
            left: left!.withValue(index, number, start, middle),
            right: right,
          )
        : _Node(
            left: left,
            right: right!.withValue(index, number, middle, end),
          );
  }
}

/// Conjunto inmutable 0..count-1, sin copiar el prefijo en cada comparación.
class SortedPrefix extends SetBase<int> {
  SortedPrefix(this.count);
  final int count;
  @override
  bool contains(Object? element) =>
      element is int && element >= 0 && element < count;
  @override
  int? lookup(Object? element) => contains(element) ? element as int : null;
  @override
  int get length => count;
  @override
  Iterator<int> get iterator => Iterable<int>.generate(count).iterator;
  @override
  Set<int> toSet() => Set<int>.of(this);
  @override
  bool add(int value) => throw UnsupportedError('Conjunto inmutable');
  @override
  bool remove(Object? value) => throw UnsupportedError('Conjunto inmutable');
}
