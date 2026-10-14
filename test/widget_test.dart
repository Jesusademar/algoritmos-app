import 'package:flutter_test/flutter_test.dart';

import 'package:app_grafos/app/app.dart';
import 'package:app_grafos/screens/dashboard_screen.dart';

void main() {
  testWidgets('la aplicación inicia en el panel principal', (tester) async {
    await tester.pumpWidget(const LogiVerseApp());

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('LogiVerse Core'), findsOneWidget);
    expect(
      find.text('Análisis de\nAlgoritmos', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Explorar Algoritmos'), findsOneWidget);
  });
}
