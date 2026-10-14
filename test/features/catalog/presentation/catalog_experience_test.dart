import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/features/binary_tree/presentation/screens/binary_tree_screen.dart';
import 'package:app_grafos/features/catalog/presentation/screens/menu_principal_screen.dart';
import 'package:app_grafos/shared/widgets/algorithm_launch_card.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('busca, recupera el catálogo y abre árboles a ${size.width}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const MenuPrincipalScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlgorithmLaunchCard), findsNWidgets(6));
      await tester.enterText(find.byType(TextField), '  ARBOLES ');
      await tester.pumpAndSettle();
      expect(find.byType(AlgorithmLaunchCard), findsOneWidget);
      expect(find.text('Árboles binarios'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'algoritmo inexistente');
      await tester.pumpAndSettle();
      expect(find.byType(AlgorithmLaunchCard), findsNothing);
      expect(find.text('No encontramos ese algoritmo'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.byType(AlgorithmLaunchCard), findsNWidgets(6));
      await tester.enterText(find.byType(TextField), 'arboles');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Abrir módulo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir módulo'));
      await tester.pumpAndSettle();
      expect(find.byType(BinaryTreeScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(BinaryTreeScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(MenuPrincipalScreen), findsOneWidget);
      expect(find.byType(AlgorithmLaunchCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
