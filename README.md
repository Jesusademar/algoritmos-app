# LogiVerse Core

Laboratorio interactivo de algoritmos e investigación de operaciones,
desarrollado con Flutter por Jesus Canqui, Miguel Sanchez y Jenny Quispe.

## Módulos

- **Grafos:** edición de nodos y conexiones, matriz de adyacencia y grados.
- **Asignación:** minimización y maximización, con filas o columnas ficticias
  para matrices rectangulares.
- **Johnson / red de actividades:** tiempos tempranos y tardíos, holguras y
  ruta crítica; inicio fijo en cero y validación de ciclos y conexiones.
- **Esquina Noroeste / transporte:** distribución de oferta y demanda,
  optimización de costos, matriz compacta y fila o columna ficticia visible al balancear.
- **Kruskal:** árbol de expansión mínima o máxima en redes sin dirección; bosque mínimo
  si la red está desconectada, conexiones resaltadas y procedimiento por pasos.
- **Dijkstra:** rutas mínimas dirigidas con pesos no negativos, selección de inicio
  y destino, distancias a todos los nodos y procedimiento de relajación. El modo
  Maximizar obtiene rutas más largas mediante orden topológico y requiere una red
  sin ciclos; no utiliza Dijkstra para maximizar.
- **Ordenamiento:** Selection, Insertion, Merge y Shell; sentido ascendente o
  descendente, reproducción por pasos y reporte Big O al finalizar. Cantidad y
  rango aleatorio definidos por el usuario, repetición opcional y enteros de
  precisión arbitraria, incluidos negativos y cero, sin topes fijos del módulo.
  Limpiar vacía los datos y resultados; Reiniciar conserva la entrada original.
- **Árboles binarios:** inserción manual o aleatoria por rango, nodos móviles,
  recorridos Pre-order, In-order y Post-order, y reconstrucción con dos recorridos.

El dashboard ofrece ejemplos preparados para los ocho módulos. La carrera de
ordenamiento compara los cuatro métodos con una entrada común, controles de
reproducción, línea de tiempo y métricas al terminar. Sus turnos visuales no
representan mediciones de velocidad real.

Los módulos incluyen ayuda y archivos JSON para guardar y cargar los datos.
Los manuales comparten una vista adaptable con instrucciones, ejemplos,
interpretación de resultados y solución de errores. Incluyen también la carrera
de ordenamiento y el acceso al procedimiento matemático donde está disponible.
En Asignación y Esquina Noroeste, calcula una solución y pulsa **Ver procedimiento
matemático** para consultar matrices, restricciones, operaciones y el costo final.
El procedimiento registra la búsqueda de asignaciones y, en transporte, la
distribución inicial noroeste y sus ajustes de optimización.
En las pizarras, arrastrar el fondo desplaza la vista y arrastrar un nodo lo
acomoda. Los controles de zoom y encuadre recuperan nodos fuera de pantalla;
se admiten rueda y zoom con dos dedos. La navegación no modifica las coordenadas
guardadas ni los resultados del algoritmo. En árboles también se conserva el
encuadre automático.
La interfaz se adapta a pantallas móviles, tabletas y escritorio. El guardado
usa descarga en navegador y selección de destino en aplicaciones nativas.
Los documentos nuevos de ordenamiento usan la versión 2 y guardan los números
como cadenas decimales para conservar todas sus cifras en navegador. Se siguen
aceptando documentos de la versión 1. Las listas grandes se dibujan por demanda
y los pasos comparten instantáneas del arreglo para reducir el uso de memoria;
la capacidad práctica sigue dependiendo de los recursos del dispositivo.

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
│   ├── network_algorithms/      # Kruskal y Dijkstra: dominio y presentación
│   ├── sorting/                 # Dominio, estado y presentación
│   └── binary_tree/             # Dominio y presentación
└── shared/
    ├── domain/                  # Procedimientos matemáticos de los módulos
    ├── graph_editor/            # Modelos, geometría y navegación de pizarras
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
