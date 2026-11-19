import 'dart:convert';

import 'package:app_grafos/features/fuzzy/data/matlab_launch_service.dart';
import 'package:app_grafos/features/fuzzy/presentation/screens/fuzzy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fuzzy_experience_test.dart' show openScreen, tapText;

const file = MatlabFisFile('ejemplo.fis', '[System]\nName=\'ejemplo\'');
const id = '0123456789abcdef0123456789abcdef';

MatlabLaunchService service({
  MatlabFilePicker? picker,
  required Future<http.Response> Function(http.Request) handle,
}) => MatlabLaunchService(
  picker: picker ?? () async => file,
  clientFactory: () => MockClient(handle),
  baseUri: Uri.parse('http://localhost:4187'),
  pollInterval: Duration.zero,
  maxPolls: 3,
);

http.Response reply(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'envía el archivo elegido y espera confirmación real del diseñador',
    () async {
      var polls = 0;
      final launcher = service(
        handle: (request) async {
          switch (request.url.path) {
            case '/api/matlab/session':
              return reply({'token': 'session'});
            case '/api/matlab/open-fuzzy':
              expect(request.method, 'POST');
              expect(request.headers['X-Logiverse-Token'], 'session');
              expect(jsonDecode(request.body), {
                'name': file.name,
                'content': file.content,
              });
              return reply({'jobId': id}, 202);
            default:
              polls++;
              return reply({'state': polls == 1 ? 'starting' : 'ready'});
          }
        },
      );
      await launcher.openFuzzy(file: await launcher.pickFile());
      expect(polls, 2);
    },
  );

  test('rechaza extensiones, datos inválidos y páginas externas', () async {
    for (final invalid in [
      const MatlabFisFile('x.txt', '[System]'),
      const MatlabFisFile('x.fis', 'not a fis'),
      const MatlabFisFile('x.fis', '[System]\u0000'),
      MatlabFisFile('x.fis', '[System]${'x' * (2 * 1024 * 1024)}'),
    ]) {
      expect(invalid.validate, throwsFormatException);
    }
    await expectLater(
      MatlabLaunchService(baseUri: Uri.parse('https://example.com'))
          .openFuzzy(),
      throwsFormatException,
    );
  });

  test(
    'servidor estático o inicio pendiente no se anuncia como abierto',
    () async {
      await expectLater(
        service(
          handle: (_) async => http.Response('<html>static server</html>', 200),
        ).openFuzzy(),
        throwsFormatException,
      );
      await expectLater(
        service(
          handle: (request) async => reply(
            request.url.path.endsWith('session')
                ? {'token': 's'}
                : request.method == 'POST'
                ? {'jobId': id}
                : {'state': 'starting'},
          ),
        ).openFuzzy(),
        throwsFormatException,
      );
    },
  );

  for (final size in [const Size(320, 700), const Size(1280, 900)]) {
    testWidgets(
      'botones abren diseñador, cancelan y permiten reintentar a ${size.width}',
      (tester) async {
        var canceled = true;
        var licenseError = true;
        final launches = <dynamic>[];
        await openScreen(
          tester,
          FuzzyScreen(
            matlabService: service(
              picker: () async => canceled ? null : file,
              handle: (request) async {
                if (request.url.path.endsWith('session')) {
                  return reply({'token': 's'});
                }
                if (request.method == 'POST') {
                  launches.add(jsonDecode(request.body));
                  return reply({'jobId': id}, 202);
                }
                return reply(
                  licenseError
                      ? {
                          'state': 'error',
                          'message': 'MATLAB necesita una licencia activa.',
                        }
                      : {'state': 'ready'},
                );
              },
            ),
          ),
          size: size,
          scale: 1.3,
        );
        await tapText(tester, 'Cargar archivo');
        expect(launches, isEmpty);
        await tapText(tester, 'Abrir MATLAB');
        expect(launches.single, isEmpty);
        expect(
          find.text('MATLAB necesita una licencia activa.'),
          findsOneWidget,
        );
        licenseError = false;
        canceled = false;
        await tapText(tester, 'Cargar archivo');
        expect(launches.last, {'name': file.name, 'content': file.content});
        expect(
          find.text('ejemplo.fis se abrió en Fuzzy Logic Designer de MATLAB.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
