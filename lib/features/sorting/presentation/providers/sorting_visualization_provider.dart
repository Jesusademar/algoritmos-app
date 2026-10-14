import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/domain/sorting_problem.dart';
import 'package:app_grafos/features/sorting/domain/sorting_result.dart';
import 'package:app_grafos/features/sorting/domain/sorting_solver.dart';
import 'package:app_grafos/features/sorting/domain/sorting_step.dart';

/// Manages the state of sorting visualization
class SortingVisualizationProvider extends ChangeNotifier {
  final SortingSolver _solver = const SortingSolver();

  late SortingResult _result;
  int _currentStepIndex = 0;
  bool _isPlaying = false;
  double _speed = 1.0; // Multiplier for animation speed (0.5x, 1x, 2x, etc.)
  final SortingAlgorithm algorithm;
  final List<int> _originalArray;
  late SortingProblem _problem;
  Duration _calculationDuration = Duration.zero;

  SortingVisualizationProvider({
    required List<int> array,
    required this.algorithm,
    SortingOrder order = SortingOrder.ascending,
    int initialStepIndex = 0,
    double initialSpeed = 1,
  }) : _originalArray = List<int>.unmodifiable(array) {
    _problem = SortingProblem(
      originalArray: _originalArray,
      algorithm: algorithm,
      order: order,
    );
    _initialize();
    if (initialStepIndex < 0 ||
        initialStepIndex >= _result.stepCount ||
        !initialSpeed.isFinite ||
        initialSpeed < 0.5 ||
        initialSpeed > 2) {
      throw ArgumentError('El paso o la velocidad inicial no son válidos.');
    }
    _currentStepIndex = initialStepIndex;
    _speed = initialSpeed;
  }

  void _initialize() {
    final timer = Stopwatch()..start();
    _result = _solver.solve(_problem);
    timer.stop();
    _calculationDuration = timer.elapsed;
    _currentStepIndex = 0;
    _isPlaying = false;
  }

  // Getters
  SortingOrder get order => _problem.order;
  List<int> get originalArray => _originalArray;
  Duration get calculationDuration => _calculationDuration;
  String get executionComplexity =>
      algorithm == SortingAlgorithm.insertionSort && totalSwaps == 0
      ? algorithm.bestCase
      : algorithm.worstCase;
  SortingStep get currentStep => _currentStepIndex < _result.stepCount
      ? _result.steps[_currentStepIndex]
      : _result.steps.last;

  int get currentStepIndex => _currentStepIndex;
  int get totalSteps => _result.stepCount;
  bool get isPlaying => _isPlaying;
  double get speed => _speed;
  bool get isComplete => _currentStepIndex >= _result.stepCount - 1;
  int get totalComparisons => _result.totalComparisons;
  int get totalSwaps => _result.totalSwaps;
  List<int> get finalArray => _result.finalArray;
  List<int> get currentArray => currentStep.array;
  int? get comparingIndex1 => currentStep.comparingIndex1;
  int? get comparingIndex2 => currentStep.comparingIndex2;
  int? get movingIndex => currentStep.movingIndex;
  Set<int> get sortedIndices => currentStep.sortedIndices;
  String get description => currentStep.description;

  // Actions
  void setOrder(SortingOrder order) {
    if (this.order == order) return;
    _problem = _problem.copyWith(order: order);
    _initialize();
    notifyListeners();
  }

  void play() {
    if (!isComplete) {
      _isPlaying = true;
      notifyListeners();
    }
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void nextStep() {
    if (_currentStepIndex < _result.stepCount - 1) {
      _currentStepIndex++;
      if (isComplete) _isPlaying = false;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void reset() {
    _currentStepIndex = 0;
    _isPlaying = false;
    notifyListeners();
  }

  void setSpeed(double newSpeed) {
    _speed = newSpeed.clamp(0.5, 2.0);
    notifyListeners();
  }

  void advanceStep() {
    nextStep();
  }

  Color getColorForIndex(int index) {
    if (index == comparingIndex1 || index == comparingIndex2) {
      return AppColors.comparing;
    } else if (index == movingIndex) {
      return AppColors.moving;
    } else if (sortedIndices.contains(index)) {
      return AppColors.success;
    } else {
      return AppColors.unsorted;
    }
  }
}
