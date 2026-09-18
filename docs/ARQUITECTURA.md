# Arquitectura de LogiVerse Core

El proyecto usa una arquitectura por funcionalidades. La regla principal es
que las pantallas muestran y capturan datos, mientras que las clases de
dominio realizan los cálculos sin depender de Flutter.

## Estructura actual

```text
lib/
├── main.dart                         # Punto de entrada mínimo
├── app/
│   ├── app.dart                      # Widget raíz y configuración global
│   └── app_theme.dart                # Tema compartido
├── features/
│   ├── assignment/
│   │   └── domain/                   # Minimización y maximización
│   │       ├── assignment_problem.dart
│   │       ├── assignment_result.dart
│   │       ├── assignment_solver.dart
│   │       └── optimization_mode.dart
│   └── johnson/
│       └── domain/                   # Cálculo actual de red de actividades
│           ├── activity_network_problem.dart
│           ├── activity_network_result.dart
│           └── activity_network_solver.dart
├── models/                           # Modelos del editor gráfico existente
└── screens/                          # Presentación y edición visual existente
```

Las pruebas reflejan la misma organización dentro de `test/`.

## Flujo de dependencias

```text
Pantalla → Problema de dominio → Solver → Resultado de dominio → Pantalla
```

El dominio no puede importar `material.dart`, widgets, archivos ni diálogos.
Así, los algoritmos se pueden probar con `flutter test` y también reutilizar
en otra interfaz.

## Reglas para trabajar en equipo

1. Una modificación del algoritmo se hace en `features/<modulo>/domain` y
   debe incluir o actualizar una prueba.
2. Los cambios visuales se hacen en la pantalla; allí no se implementan
   fórmulas ni búsquedas combinatorias.
3. Los modelos de entrada y salida del algoritmo son inmutables.
4. No se accede a `BuildContext` desde el dominio.
5. Antes de integrar cambios se ejecutan:

   ```powershell
   D:\FlutterSDK\bin\dart.bat analyze lib test
   D:\FlutterSDK\bin\flutter.bat test
   ```

## Distribución sugerida para tres integrantes

- Integrante 1: navegación, diseño, editor visual y experiencia de usuario.
- Integrante 2: asignación por minimización/maximización y sus pruebas.
- Integrante 3: algoritmo de Johnson, validaciones y sus pruebas.

Cada integrante debe trabajar en una rama distinta y unir cambios mediante
revisión, para evitar que los tres editen al mismo tiempo las pantallas grandes.

## Próxima separación recomendada

Las pantallas heredadas todavía contienen diálogos, persistencia y dibujo en
un solo archivo. El siguiente paso seguro es extraer, por funcionalidad:

- `presentation/widgets/` para el lienzo, paneles y diálogos;
- `presentation/<feature>_controller.dart` para el estado de la pantalla;
- `data/` para importar y exportar JSON;
- `shared/graph_editor/` para las piezas visuales realmente comunes.

No conviene crear una clase común gigantesca para los tres módulos: se debe
compartir solamente el editor visual y la persistencia, no las reglas de cada
algoritmo.

## Observación funcional importante

La pantalla llamada `JohnsonScreen` actualmente modela una red de actividades
y calcula tiempos tempranos, tardíos, holguras y ruta crítica. Eso corresponde
a CPM/PERT. La regla clásica de Johnson, descrita en el menú, ordena trabajos
en dos máquinas para minimizar el *makespan*. Antes de la entrega se debe
confirmar cuál de los dos métodos exige el docente; si exige Johnson clásico,
esa pantalla necesita un modelo de trabajos y tiempos por máquina.
