import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/domain/sorting_problem.dart';
import 'package:app_grafos/features/sorting/domain/sorting_result.dart';
import 'package:app_grafos/features/sorting/domain/sorting_step.dart';
import 'package:app_grafos/features/sorting/domain/sorting_solver.dart';
import 'package:app_grafos/features/sorting/domain/sorting_validator.dart';

/// Compara los pasos reales de los cuatro métodos con una entrada común.
class SortingRaceController extends ChangeNotifier {
  SortingRaceController({
    List<int> numbers = const [72, 18, 91, 34, 9, 56, 25, 63],
  }) {
    setNumbers(numbers);
  }

  List<int> _numbers = const [];
  Map<SortingAlgorithm, SortingResult> _results = {};
  SortingOrder _order = SortingOrder.ascending;
  Timer? _timer;
  int _tick = 0;
  int _lastTick = 0;
  int _speed = 1;

  List<int> get numbers => _numbers;
  SortingOrder get order => _order;
  int get tick => _tick;
  int get lastTick => _lastTick;
  int get speed => _speed;
  bool get isPlaying => _timer != null;
  bool get isComplete => _tick == _lastTick;
  SortingResult result(SortingAlgorithm algorithm) => _results[algorithm]!;
  int stepIndex(SortingAlgorithm algorithm) =>
      _tick.clamp(0, result(algorithm).stepCount - 1);
  SortingStep step(SortingAlgorithm algorithm) =>
      result(algorithm).steps[stepIndex(algorithm)];
  bool completed(SortingAlgorithm algorithm) =>
      stepIndex(algorithm) == result(algorithm).stepCount - 1;
  double progress(SortingAlgorithm algorithm) =>
      result(algorithm).stepCount <= 1
      ? 1
      : stepIndex(algorithm) / (result(algorithm).stepCount - 1);
  String complexity(SortingAlgorithm algorithm) =>
      algorithm == SortingAlgorithm.insertionSort &&
          result(algorithm).totalSwaps == 0
      ? algorithm.bestCase
      : algorithm.worstCase;
  List<SortingAlgorithm> get fewestComparisons {
    final minimum = _results.values
        .map((result) => result.totalComparisons)
        .reduce((a, b) => a < b ? a : b);
    return SortingAlgorithm.values
        .where((algorithm) => result(algorithm).totalComparisons == minimum)
        .toList();
  }

  void setNumbers(List<int> numbers) {
    final (valid, error) = SortingValidator.validateArray(numbers);
    if (!valid) throw FormatException(error ?? 'Números no válidos.');
    _numbers = List.unmodifiable(numbers);
    _recalculate();
  }

  void setOrder(SortingOrder order) {
    if (_order == order) return;
    _order = order;
    _recalculate();
  }

  void _recalculate() {
    _stop();
    _tick = 0;
    _results = {
      for (final algorithm in SortingAlgorithm.values)
        algorithm: const SortingSolver().solve(
          SortingProblem(
            originalArray: _numbers,
            algorithm: algorithm,
            order: _order,
          ),
        ),
    };
    _lastTick = _results.values
        .map((result) => result.stepCount - 1)
        .reduce((a, b) => a > b ? a : b);
    notifyListeners();
  }

  void play() {
    if (isPlaying) return;
    if (isComplete) _tick = 0;
    if (_lastTick == 0) return;
    _timer = Timer.periodic(Duration(milliseconds: (110 / _speed).round()), (
      _,
    ) {
      _tick++;
      if (isComplete) _stop();
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _stop();
    notifyListeners();
  }

  void seek(int tick) {
    _stop();
    _tick = tick.clamp(0, _lastTick);
    notifyListeners();
  }

  void next() => seek(_tick + 1);
  void finish() => seek(_lastTick);
  void reset() => seek(0);
  void setSpeed(int value) {
    if (![1, 2, 4].contains(value)) throw ArgumentError.value(value, 'speed');
    final playing = isPlaying;
    _stop();
    _speed = value;
    if (playing) {
      play();
    } else {
      notifyListeners();
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
