import 'package:app_grafos/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la aplicación inicia en el panel principal', (tester) async {
    await tester.pumpWidget(const LogiVerseApp());

    expect(find.text('LogiVerse Core'), findsOneWidget);
    expect(find.text('Análisis de Algoritmos'), findsOneWidget);
    expect(find.text('Ver Algoritmos'), findsOneWidget);
  });
}
