# LogiVerse Core

Laboratorio interactivo de algoritmos e investigación de operaciones,
desarrollado con Flutter por Jesus Canqui, Miguel Sanchez y Jenny Quispe.

## Módulos

- **Grafos:** edición de nodos y conexiones, matriz de adyacencia y grados.
- **Asignación:** minimización y maximización, con filas o columnas ficticias
  para matrices rectangulares.
- **Johnson / red de actividades:** tiempos tempranos y tardíos, holguras y
  ruta crítica; validación de ciclos y conexiones.
- **Esquina Noroeste / transporte:** distribución de oferta y demanda,
  optimización de costos y balance automático.
- **Ordenamiento:** Selection, Insertion, Merge y Shell; sentido ascendente o
  descendente, reproducción por pasos y reporte Big O al finalizar.
- **Árboles binarios:** inserción manual o aleatoria por rango, nodos móviles,
  recorridos Pre-order, In-order y Post-order, y reconstrucción con dos recorridos.

El dashboard ofrece ejemplos preparados para los seis módulos. La carrera de
ordenamiento compara los cuatro métodos con una entrada común, controles de
reproducción, línea de tiempo y métricas al terminar. Sus turnos visuales no
representan mediciones de velocidad real.

Los módulos incluyen ayuda y archivos JSON para guardar y cargar los datos.
La interfaz se adapta a pantallas móviles, tabletas y escritorio. El guardado
usa descarga en navegador y selección de destino en aplicaciones nativas.

## Organización

```text
lib/
├── main.dart
├── app/                         # Aplicación, tema y navegación
│   └── navigation/              # Catálogo único de módulos
├── features/
│   ├── dashboard/presentation/  # Inicio y contenido educativo
│   ├── catalog/presentation/    # Menú, búsqueda e ilustraciones
│   ├── graph/presentation/      # Editor y dibujo de grafos
│   ├── assignment/              # Dominio y presentación
│   ├── johnson/                 # Dominio y presentación
│   ├── esquina_nor_oeste/       # Dominio y presentación
│   ├── sorting/                 # Dominio, estado y presentación
│   └── binary_tree/             # Dominio y presentación
└── shared/
    ├── graph_editor/            # Modelos visuales y geometría
    ├── persistence/             # Documentos y archivos JSON
    └── widgets/                 # Encabezados, tarjetas, paneles y diálogos
```

Las pantallas están en `features/<módulo>/presentation/screens/` y sus
componentes en `presentation/widgets/`. Las pruebas de cada módulo se agrupan
en `test/features/`; las verificaciones de navegación e integración general
permanecen en `test/`.

Consulta [la arquitectura](docs/ARQUITECTURA.md) para las dependencias y pautas
para ampliar la aplicación.

## Desarrollo

```sh
flutter pub get
flutter run -d chrome
```

## Verificación

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
```

Para comprobar la descarga real de archivos en navegador:

```sh
flutter test --platform chrome test/shared/persistence/graph_file_web_test.dart
```

La pantalla denominada Johnson implementa una red de actividades CPM/PERT.
La regla clásica de Johnson para secuenciar trabajos en dos máquinas es otro
algoritmo y requiere un módulo propio.

## Compartir con el docente

La publicación automática está preparada para GitHub Pages. Sigue
[los pasos para activarla y obtener el enlace](docs/PUBLICAR_EN_GITHUB.md).
