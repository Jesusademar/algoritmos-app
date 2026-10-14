# Arquitectura de LogiVerse Core

La aplicación está organizada por funcionalidades. Cada algoritmo conserva
sus cálculos y validaciones en el dominio y sus pantallas dentro del mismo
módulo. Los elementos visuales comunes y el acceso a archivos se comparten.

## Estructura

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── app_theme.dart
│   └── navigation/algorithm_modules.dart
├── features/
│   ├── dashboard/presentation/{screens,widgets}/
│   ├── catalog/presentation/{screens,widgets}/
│   ├── graph/presentation/{screens,widgets}/
│   ├── assignment/{domain,presentation}/
│   ├── johnson/{domain,presentation}/
│   ├── esquina_nor_oeste/{domain,presentation}/
│   ├── sorting/{domain,presentation}/
│   └── binary_tree/{domain,presentation}/
└── shared/
    ├── graph_editor/
    │   ├── models/{nodo,conexion}.dart
    │   └── geometry/offset_geometry.dart
    ├── persistence/
    │   ├── graph_document.dart
    │   ├── graph_document_codec.dart
    │   └── graph_file_service.dart
    └── widgets/
```

Las rutas anteriores `lib/screens/` y `lib/models/` se mantienen como archivos
`export` de compatibilidad. Permiten resolver imports existentes; no contienen
otra implementación. Los cambios se hacen en los módulos y en `shared/`.

Dentro de cada `presentation/`, las pantallas se ubican en `screens/` y los
lienzos, dibujos y componentes en `widgets/`. Ordenamiento mantiene su estado
de reproducción en `providers/sorting_visualization_provider.dart`.

## Responsabilidades

- **`app/`:** crea la aplicación y configura el tema. `algorithm_modules.dart`
  define nombres, descripciones, categorías, colores y destinos de los seis
  módulos. El dashboard y el menú usan este catálogo único.
- **`features/*/domain/`:** problemas, resultados, cálculos y validaciones.
  Estas clases usan Dart y no dependen de widgets ni de `BuildContext`.
- **`features/*/presentation/screens/`:** interacción, edición, apertura de
  diálogos y coordinación entre los datos y los resultados. Las pantallas de
  grafos todavía mantienen el estado de edición local mediante `State`.
- **`features/*/presentation/widgets/`:** dibujo y presentación. Los pintores
  de grafos, asignación, transporte y actividades están separados de sus
  pantallas. Cada uno conserva las reglas visuales de su propio módulo.
- **`shared/graph_editor/`:** modelos mutables del editor y geometría de
  conexiones. `Nodo` y `Conexion` contienen tipos gráficos de `dart:ui` y no
  forman parte del dominio matemático.
- **`shared/persistence/`:** formato de los documentos y acceso multiplataforma
  a archivos JSON. `GraphFileService` permite sustituir lector y escritor en
  las pruebas; los módulos no escriben directamente con `dart:io`.
- **`shared/widgets/`:** superficies, encabezados, paneles, tarjetas de acceso,
  pasos del manual y diálogo de guardado. No contiene lógica de algoritmos.

Los documentos de árboles y ordenamiento contienen datos de Dart y validan
las entradas antes de reemplazar el estado visible. Ordenamiento conserva la
entrada original y recalcula los pasos al cargar, recuperando la sesión en
pausa. Los árboles conservan su estructura y las posiciones de sus nodos.

## Flujo de datos

```text
Pantalla → Problema → Solver → Resultado → Visualización
Pantalla ↔ Documento JSON ↔ GraphFileService
```

No se comparten reglas matemáticas entre algoritmos por parecerse visualmente.
Por ejemplo, las restricciones de una red de actividades y las de asignación
se validan en su módulo correspondiente.

## Sistema visual

`AppColors` define la paleta y `AppLayout` reúne radios, márgenes, ancho de
contenido y límites de los paneles. `AppTheme` configura tipografía, entradas,
botones, menús, diálogos y mensajes. Cada módulo usa un acento identificable.

`AlgorithmScaffold` proporciona encabezado y fondo. `AlgorithmWorkspace`
adapta el lienzo y su panel entre móvil y escritorio. `AlgorithmPanelSection`
organiza los controles y resultados. `AlgorithmLaunchCard` comparte el diseño
y los estados de foco y ratón entre el catálogo y los métodos de ordenamiento.
Las tarjetas crecen según su contenido para admitir texto ampliado.

## Añadir un módulo

1. Crear su carpeta bajo `features/` y sus cálculos en `domain/`.
2. Crear la pantalla en `presentation/screens/` y el dibujo en
   `presentation/widgets/`.
3. Usar los componentes y el tema compartidos.
4. Registrar el módulo en `app/navigation/algorithm_modules.dart`.
5. Incorporar las pruebas de cálculos y flujos en `test/features/<módulo>/`.
6. Verificar navegación, diseño compacto, archivos y errores relevantes.

## Verificaciones

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
```

Las pruebas incluyen validaciones matemáticas, interacción, guardar/cargar,
navegación con teclado, texto ampliado y tamaños de móvil y escritorio.
La descarga real se comprueba con la prueba para Chrome en
`test/shared/persistence/graph_file_web_test.dart`.

El módulo llamado Johnson representa una red de actividades CPM/PERT, no la
regla clásica de secuenciación de trabajos en dos máquinas.
