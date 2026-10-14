import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/features/sorting/domain/sorting_algorithm.dart';
import 'package:app_grafos/features/sorting/domain/sorting_order.dart';
import 'package:app_grafos/features/sorting/presentation/providers/sorting_race_controller.dart';

void main() {
  test('compara la misma entrada, valida datos y recupera estados en ambos sentidos', () {
    final input = [9, 3, 6, 3];
    final race = SortingRaceController(numbers: input);
    addTearDown(race.dispose);
    input[0] = 99;
    expect(race.numbers, [9, 3, 6, 3]);
    race.finish();
    for (final method in SortingAlgorithm.values) {
      expect(race.step(method).array, [3, 3, 6, 9]);
      expect(race.completed(method), isTrue);
      expect(race.progress(method), 1);
    }
    race.seek(-20);
    expect(race.tick, 0);
    for (final method in SortingAlgorithm.values) {
      expect(race.step(method).array, [9, 3, 6, 3]);
    }
    expect(() => race.setNumbers([101]), throwsFormatException);
    expect(race.numbers, [9, 3, 6, 3]);
    race.setOrder(SortingOrder.descending);
    race.finish();
    for (final method in SortingAlgorithm.values) {
      expect(race.step(method).array, [9, 6, 3, 3]);
    }
    race.setOrder(SortingOrder.ascending);
    race.setNumbers([1, 2, 3, 4, 5]);
    race.finish();
    expect(race.fewestComparisons, contains(SortingAlgorithm.insertionSort));
    expect(race.complexity(SortingAlgorithm.insertionSort), 'O(n)');
  });
  testWidgets('reproducción, pausa, velocidad y fin cancelan el reloj', (
    tester,
  ) async {
    final race = SortingRaceController(numbers: [8, 7, 6, 5, 4, 3, 2, 1]);
    race.play();
    await tester.pump(const Duration(milliseconds: 330));
    expect(race.tick, 3);
    race.pause();
    await tester.pump(const Duration(seconds: 2));
    expect(race.tick, 3);
    race.setSpeed(4);
    race.play();
    await tester.pump(const Duration(milliseconds: 84));
    expect(race.tick, 6);
    race.finish();
    expect(race.isPlaying, isFalse);
    race.play();
    expect(race.tick, 0);
    race.dispose();
    await tester.pump(const Duration(seconds: 2));
  });
}
